/*
 * Copyright (c) 2017-2019 José Amuedo (https://github.com/spheras)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
 * @class
 * Photo Window to show a photo
 */
public class DesktopFolder.PhotoWindow : Gtk.ApplicationWindow {
    /** parent manager of this window */
    private PhotoManager manager = null;
    /** Context menu of the Folder Window */
    private Gtk.Menu menu        = null;

    // private const string FIXO_TAGS_COLORS[7] = { null, "#fce94f", "#8ae234", "#729fcf", "#fe44f8", "#FFFFFF", "#000000" };
    private const string FIXO_TAGS_COLORS[9] = { null, "#ffe16b", "#ffa154", "#9bdb4d", "#64baff", "#ad65d6", "#ed5353", "#ffffff", "#000000" };

    // cached shadow photo and fixos
    private Cairo.Surface shadowSurface = null;
    private Cairo.Surface photoSurface  = null;
    private Gdk.Pixbuf fixoPixbuf       = null;

    // flag to know if the window is being resized
    private bool flag_resizing = false;
    private uint timeout_id    = 0;
    /** flag to know if the window was painted /packed already */
    private bool flag_realized = false;

    construct {
        set_keep_below (true);
        stick ();
        this.hide_titlebar_when_maximized = false;
        set_type_hint (Gdk.WindowTypeHint.MENU);
        set_skip_taskbar_hint (true);
        this.set_property ("skip-taskbar-hint", true);
    }

    /**
     * @constructor
     * @param FolderManager manager the manager of this window
     */
    public PhotoWindow (PhotoManager manager) {
        Object (
            application:        manager.get_application (),
            icon_name:          "com.github.spheras.desktopfolder",
            resizable:          true,
            skip_taskbar_hint:  true,
            decorated:          true,
            type_hint:          Gdk.WindowTypeHint.DESKTOP,
            title:              "",
            deletable:          false,
            width_request:      0,
            height_request:     0
        );

        DesktopManager desktop_manager = manager.get_application ().get_fake_desktop ();
        if (desktop_manager != null) {
            this.set_transient_for (desktop_manager.get_view ());
        }
        this.set_titlebar (null);
        this.set_skip_taskbar_hint (true);
        this.set_property ("skip-taskbar-hint", true);
        // setting the folder name
        this.manager = manager;

        // important to load settings 2 times, now and after realized event
        this.reload_settings ();
        this.realize.connect (() => {
            if (!this.flag_realized) {
                this.flag_realized = true;
                // we need to reload settings to ensure that it get the real sizes and positiions
                this.reload_settings ();
            }
        });

        this.show_all ();

        // connecting to events
        this.configure_event.connect (this.on_configure);
        this.motion_notify_event.connect ((event) => {
            // forzing to draw the borders background
            this.flag_resizing = true;
            this.queue_draw ();
            return true;
        });
        this.button_press_event.connect (this.on_press);
        this.button_release_event.connect (this.on_release);
        this.draw.connect (this.draw_background);

        // help: doesn't have the gtk window any active signal? or css :active state?
        Wnck.Screen screen = Wnck.Screen.get_default ();
        screen.active_window_changed.connect (on_active_change);
    }

    /**
     * @name move_to
     * @description move the window to other position
     */
    protected virtual void move_to (int x, int y) {
        // debug ("MOVE_TO: %d,%d", x, y);
        this.move (x, y);
    }

    /**
     * @name resize_to
     * @description resize the window to other position
     */
    public virtual void resize_to (int width, int height) {
        // debug ("RESIZE_TO: %d,%d", width, height);
        this.set_default_size (width, height);
        this.resize (width, height);
    }

    /**
     * @name reload_settings
     * @description reload the window style in general
     */
    public void reload_settings () {
        // let's load the settings of the folder (if exist or a new one)
        PhotoSettings settings = this.manager.get_settings ();
        if (settings.w > 0) {
            // applying existing position and size configuration
            this.resize_to (settings.w, settings.h);
        }
        if (settings.x > 0 || settings.y > 0) {
            this.move_to (settings.x, settings.y);
        }

        List <unowned string> classes = this.get_style_context ().list_classes ();
        for (int i = 0; i < classes.length (); i++) {
            string class = classes.nth_data (i);
            if (class.has_prefix ("df_")) {
                this.get_style_context ().remove_class (class);
            }
        }


        // we set a class to this window to manage the css
        this.get_style_context ().add_class ("df_folder");
        this.get_style_context ().add_class ("df_photo");
        this.get_style_context ().add_class ("df_transparent");
        this.get_style_context ().add_class ("df_headless");
    }

    /**
     * @name on_active_change
     * @description the screen actived window has change signal
     * @param {Wnck.Window} the previous actived window
     */
    private void on_active_change (Wnck.Window ? previous) {
        string           sclass = "df_active";
        Gtk.StyleContext style  = this.get_style_context ();
        if (this.is_active) {
            if (!style.has_class (sclass)) {
                style.add_class ("df_active");
                // we need to force a queue_draw
                this.queue_draw ();
            }
        } else {
            if (style.has_class (sclass)) {
                style.remove_class ("df_active");
                this.type_hint = Gdk.WindowTypeHint.DESKTOP;
                // we need to force a queue_draw
                this.queue_draw ();
            }
        }

        this.save_current_position_and_size ();
    }

    /**
     * @name save_position_and_size
     * @description save the current position and size of the window
     */
    public void save_current_position_and_size () {
        // we are saving here the last position and size
        // we avoid doing it at on_configure because it launches a lot of events
        Gtk.Allocation all;
        int x = 0;
        int y = 0;
        int w = 0;
        int h = 0;
        this.get_position (out x, out y);
        this.get_allocation (out all);
        this.get_size (out w, out h);
        // debug ("set_new_shape:%i,%i,%i,%i", x, y, w, h);
        this.manager.set_new_shape (x, y, w, h);
    }

    /**
     * @name on_configure
     * @description the configure event is produced when the window change its dimensions or location settings
     * @return {bool} @see configure_event signal
     */
    private bool on_configure (Gdk.EventConfigure event) {
        if (event.type == Gdk.EventType.CONFIGURE) {
            // we are now a dock Window, to avoid minimization when show desktop
            // TODO exists a way to make resizable and moveable a dock window?
            this.type_hint = Gdk.WindowTypeHint.DESKTOP;

            // debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            /*this.manager.set_new_shape (event.x, event.y, event.width, event.height);*/

            // reseting cached images
            this.shadowSurface = null;
            this.photoSurface  = null;
            this.fixoPixbuf    = null;
        }
        return false;
    }

    /**
     * @name on_release
     * @description release event captured.
     * @return bool @see widget on_release signal
     */
    private bool on_release (Gdk.EventButton event) {
        // we are now a dock Window, to avoid minimization when show desktop
        // TODO exists a way to make resizable and moveable a dock window?
        this.type_hint = Gdk.WindowTypeHint.DESKTOP;
        return false;
    }

    /**
     * @name on_press
     * @description press event captured. The Window should show the popup on right button
     * @return bool @see widget on_press signal
     */
    private bool on_press (Gdk.EventButton event) {
        // we are now a normal Window, to allow resizing and movement
        // TODO exists a way to make resizable and moveable a dock window?
        this.type_hint = Gdk.WindowTypeHint.NORMAL;

        // debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button == Gdk.BUTTON_SECONDARY)) {
            this.show_popup (event);
            return true;
        } else if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button == Gdk.BUTTON_PRIMARY)) {
            this.flag_resizing = true;
            int width  = this.get_allocated_width ();
            int height = this.get_allocated_height ();
            int margin = 30;
            // debug("x:%d,y:%d,width:%d,height:%d",(int)event.x,(int) event.y,width,height);
            if (event.x > margin && event.y > margin && event.x < width - margin && event.y < height - margin) {
                this.begin_move_drag ((int) event.button, (int) event.x_root, (int) event.y_root, event.time);
            }
        }
        return false;
    }

    /**
     * @name show_popup
     * @description build and show the popup menu
     * @param event EventButton the origin event, needed to position the menu
     */
    private void show_popup (Gdk.EventButton event) {
        // debug("evento:%f,%f",event.x,event.y);
        // if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!

        // Forcing Dock mode to avoid minimization in certain extremely cases without on_press signal!
        // TODO exists a way to make resizable and moveable a dock window?
        this.type_hint = Gdk.WindowTypeHint.DESKTOP;

        this.menu      = new Gtk.Menu ();

        // new submenu
        Gtk.MenuItem item_new = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_SUBMENU);
        item_new.show ();
        menu.append (item_new);

        Gtk.Menu newmenu = new Gtk.Menu ();
        item_new.set_submenu (newmenu);

        // menu to create a new folder
        Gtk.MenuItem item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
        item.activate.connect ((item) => {
            this.new_desktop_folder ();
        });
        item.show ();
        newmenu.append (item);

        // menu to create a new link panel
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LINK_PANEL);
        item.activate.connect ((item) => {
            this.new_link_panel ();
        });
        item.show ();
        newmenu.append (item);

        // menu to create a new note
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
        item.activate.connect ((item) => {
            this.new_note ();
        });
        item.show ();
        newmenu.append (item);

        // menu to create a new photo
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);
        item.activate.connect ((item) => {
            this.new_photo ();
        });
        item.show ();
        newmenu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        menu.append (item);

        // option to delete the current folder
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.PHOTO_MENU_DELETE_PHOTO);
        item.activate.connect ((item) => { this.manager.delete (); });
        item.show ();
        menu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        menu.append (item);

        item = new MenuItemColor (FIXO_TAGS_COLORS, this, null);
        ((MenuItemColor) item).color_changed.connect (change_fixo_color);
        item.show ();
        menu.append (item);

        // }

        // finally we show the popup
        menu.popup_at_pointer (null);
    }

    /**
     * @name change_fixo_color
     * @description change event captured from the popup for a new color to the fixo color
     * @param ncolor int the new color for the fixo
     */
    private void change_fixo_color (int ncolor) {
        this.manager.get_settings ().fixocolor = ncolor;
        // reseting fixo images
        this.fixoPixbuf = null;
        this.queue_draw ();
    }

    /**
     * @name new_desktop_folder
     * @description show a dialog to create a new desktop folder
     */
    private void new_desktop_folder () {
        DesktopFolder.Util.create_new_desktop_folder (this);
    }

    /**
     * @name new_link_panel
     * @description show a dialog to create a new link panel
     */
    private void new_link_panel () {
        DesktopFolder.Util.create_new_link_panel (this);
    }

    /**
     * @name new_note
     * @description show a dialog to create a new note
     */
    private void new_note () {
        DesktopFolder.Util.create_new_note (this);
    }

    /**
     * @name new_photo
     * @description show a dialog to create a new photo
     */
    private void new_photo () {
        DesktopFolder.Util.create_new_photo (this);
    }

    /**
     * @name draw_backgorund
     * @description draw the note window background intercepting the draw signal
     * @param {Cairo.Context} cr the cairo context
     * @bool @see draw signal
     */
    private bool draw_background (Cairo.Context cr) {
        int width        = 0;
        int height       = 0;
        this.get_size (out width, out height);
        int MAGIC_NUMBER = 56;
        height = height + MAGIC_NUMBER;

        // debug ("-width:%d, -height:%d", width, height);

        cr.set_operator (Cairo.Operator.CLEAR);
        cr.paint ();
        cr.set_operator (Cairo.Operator.OVER);

        try {
            // the image dimensions
            int margin     = 50;
            int halfmargin = 25;
            int pixwidth   = width - margin;
            int pixheight  = height - margin;
            if (this.manager.get_settings ().original_width > 0) {
                pixheight = (pixwidth * this.manager.get_settings ().original_height) / this.manager.get_settings ().original_width;
                if (pixheight > (height - margin)) {
                    pixheight = height - margin;
                    pixwidth  = (pixheight * this.manager.get_settings ().original_width) / this.manager.get_settings ().original_height;
                }
            }

            // debug ("pixwidth:%d, pixheight:%d", pixwidth, pixheight);
            if (this.flag_resizing) {
                cr.set_source_rgba (0, 0, 0, 0.2);
                cr.rectangle (0, 0, width, height);
                cr.fill ();

                if (this.timeout_id > 0) {
                    GLib.Source.remove (this.timeout_id);
                    this.timeout_id = 0;
                }
                this.timeout_id = GLib.Timeout.add (2000, () => {
                    // we force to resize to adapt to the image size, (to maintain aspect ratio)
                    // this.resize (pixwidth + margin, pixheight + margin);
                    this.flag_resizing = false;
                    this.queue_draw ();
                    // debug ("!!resizing to %d,%d", pixwidth + margin, pixheight + margin);
                    this.resize_to (pixwidth + margin, pixheight + margin - MAGIC_NUMBER);
                    this.timeout_id = 0;

                    this.save_current_position_and_size ();
                    return false;
                });
            } else {
                cr.set_source_rgba (255, 0, 0, 0);
                cr.rectangle (0, 0, width, height);
                cr.fill ();
            }

            // drawing the shadow
            if (this.manager.get_settings ().fixocolor == 0) {
                if (this.shadowSurface == null) {
                    var shadowPixbuf = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/shadow.png");
                    shadowPixbuf       = shadowPixbuf.scale_simple (pixwidth, 40, Gdk.InterpType.BILINEAR);
                    this.shadowSurface = Gdk.cairo_surface_create_from_pixbuf (shadowPixbuf, 0, null);
                }
                cr.set_source_surface (this.shadowSurface, halfmargin, pixheight + 20);
                cr.paint ();
            }


            // the photo
            if (photoSurface == null) {
                var photopath   = this.manager.get_settings ().photo_path;
                var photoPixbuf = new Gdk.Pixbuf.from_file (photopath);
                photoPixbuf       = photoPixbuf.scale_simple (pixwidth, pixheight, Gdk.InterpType.BILINEAR);
                this.photoSurface = Gdk.cairo_surface_create_from_pixbuf (photoPixbuf, 0, null);
                // DesktopFolder.Util.blur_image_surface((Cairo.ImageSurface)this.photoSurface,4);
            }
            cr.set_source_surface (this.photoSurface, halfmargin, halfmargin);
            cr.paint ();

            // lets draw the fixo
            int fixoWidth  = 56;
            int fixoHeight = 56;
            int fixoMargin = 4;
            int fixocolor  = this.manager.get_settings ().fixocolor;
            var color      = "";
            switch (fixocolor) {
            case 0:
                color = null;
                break;
            case 1:
                color = "banana";
                break;
            case 2:
                color = "orange";
                break;
            case 3:
                color = "lime";
                break;
            case 4:
                color = "blueberry";
                break;
            case 5:
                color = "grape";
                break;
            case 6:
                color = "strawberry";
                break;
            case 7:
                color = "white";
                break;
            default:
            case 8:
                color = "black";
                break;
            }
            if (color != null) {
                if (this.fixoPixbuf == null) {
                    this.fixoPixbuf = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/fixo-" + color + ".svg");
                    // this.fixoPixbuf=fixoPixbuf.scale_simple(100,100,Gdk.InterpType.BILINEAR);
                }
                var fixoSurface = Gdk.cairo_surface_create_from_pixbuf (this.fixoPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, fixoMargin, fixoMargin);
                cr.paint ();

                var rotatedPixbuf = this.fixoPixbuf.rotate_simple (Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface = Gdk.cairo_surface_create_from_pixbuf (rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, pixwidth + margin - fixoWidth - fixoMargin, fixoMargin);
                cr.paint ();

                rotatedPixbuf = rotatedPixbuf.rotate_simple (Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface   = Gdk.cairo_surface_create_from_pixbuf (rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, pixwidth + margin - fixoWidth - fixoMargin, pixheight + margin - fixoHeight - fixoMargin);
                cr.paint ();

                rotatedPixbuf = rotatedPixbuf.rotate_simple (Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface   = Gdk.cairo_surface_create_from_pixbuf (rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, fixoMargin, pixheight + margin - fixoHeight - fixoMargin);
                cr.paint ();
            }

        } catch (Error e) {
            // error! ??
            stderr.printf ("Error: %s\n", e.message);
        }

        return true;
    }

}
