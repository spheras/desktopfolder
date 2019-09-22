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
 * Folder Window that is shown above the desktop to manage files and folders
 */
public class DesktopFolder.NoteWindow : Gtk.ApplicationWindow {
    private NoteManager manager                     = null;
    private Gtk.Menu menu                           = null; // Context menu
    private Gtk.TextView text                       = null;
    private Cairo.Pattern texture_pattern           = null;
    private Cairo.Surface clip_surface              = null; // The clip image
    private Gtk.Button trash_button                 = null;
    private DesktopFolder.EditableLabel label       = null;

    private const string HEAD_TAGS_COLORS[3]        = { null, "#ffffff", "#000000" };
    private const string HEAD_TAGS_COLORS_CLASS[3]  = { "df_headless", "df_light", "df_dark" };
    private const string BODY_TAGS_COLORS[10]       = { null, "#ffe16b", "#ffa154", "#795548", "#9bdb4d", "#64baff", "#ad65d6", "#ed5353", "#d4d4d4", "#000000" };
    private const string BODY_TAGS_COLORS_CLASS[10] = { "df_transparent", "df_yellow", "df_orange", "df_brown", "df_green", "df_blue", "df_purple", "df_red", "df_gray", "df_black" };
    private string last_custom_color                = "#FF0000";
    private Gtk.CssProvider custom_color_provider   = new Gtk.CssProvider ();

    /** flag to know if the window was painted /packed already */
    private bool flag_realized = false;

    construct {
        this.hide_titlebar_when_maximized = false;

        stick ();
    }

    /**
     * @constructor
     * @param NoteManager manager The manager of this window
     */
    public NoteWindow (NoteManager manager) {
        Object (
            application:        manager.get_application (),
            icon_name:          "com.github.spheras.desktopfolder",
            resizable:          true,
            accept_focus:       true,
            decorated:          true,
            title:              (manager.get_note_name ()),
            type_hint:          Gdk.WindowTypeHint.NORMAL,
            deletable:          false,
            height_request:     140,
            width_request:      160
        );

        this.check_window_type ();
        this.manager = manager;
        this.name    = manager.get_application ().get_next_id ();
        DesktopManager desktop_manager = manager.get_application ().get_fake_desktop ();
        if (desktop_manager != null) {
            this.set_transient_for (desktop_manager.get_view ());
        }

        this.trash_button         = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        trash_button.has_tooltip  = true;
        trash_button.tooltip_text = DesktopFolder.Lang.DESKTOPFOLDER_DELETE_TOOLTIP;
        trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button");
        trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        this.trash_button.enter_notify_event.connect (() => {
            this.trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hover");
            return true;
        });
        this.trash_button.leave_notify_event.connect (() => {
            this.trash_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hover");
            return true;
        });

        this.create_headerbar ();

        Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        box.get_style_context ().add_class ("df_note_container");
        box.set_border_width (20);
        this.add (box);

        Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.get_style_context ().add_class ("df_note_scroll");
        box.pack_start (scrolled, true, true, 0);

        this.text = new Gtk.SourceView (); // Gtk.TextView ();
        this.text.set_wrap_mode (Gtk.WrapMode.WORD);
        this.text.get_style_context ().add_class ("df_note_text");
        this.text.buffer.text = this.manager.get_settings ().text;
        scrolled.add (this.text);

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

        this.check_on_top ();

        // this.configure_event.connect (this.on_configure);
        this.button_press_event.connect (this.on_press);
        this.button_release_event.connect (this.on_release);
        this.draw.connect (this.draw_background);

        this.enter_notify_event.connect (this.on_enter_notify);
        this.leave_notify_event.connect (this.on_leave_notify);
        this.text.add_events (Gdk.EventMask.ENTER_NOTIFY_MASK);
        this.text.add_events (Gdk.EventMask.LEAVE_NOTIFY_MASK);
        this.text.enter_notify_event.connect (this.on_enter_notify);
        this.text.leave_notify_event.connect (this.on_leave_notify);

        trash_button.clicked.connect (this.manager.trash);

        this.text.focus_out_event.connect (this.on_focus_out);
        // this.key_release_event.connect(this.on_key);

        // TODO: Does the GTK window have any active signal or css :active state?
        Wnck.Screen screen = Wnck.Screen.get_default ();
        screen.active_window_changed.connect (on_active_change);

        NoteSettings settings = this.manager.get_settings ();

        if (settings.edit_label_on_creation) {
            GLib.Timeout.add (50, () => {
                this.label.start_editing ();
                settings.edit_label_on_creation = false;
                return false;
            });
        }
    }


    /**
     * @name create_headerbar
     * @description create the header bar
     */
    protected virtual void create_headerbar () {
        // debug("Create headerbar for %s",this.manager.get_folder_name ());

        var header = new Gtk.HeaderBar ();
        header.height_request = DesktopFolder.HEADERBAR_HEIGHT;
        header.has_subtitle   = false;
        this.label            = new DesktopFolder.EditableLabel (manager.get_note_name ());
        this.label.set_margin_top (10);
        this.label.set_margin_end (40);
        this.label.show_popup.connect ((event) => { this.show_popup (event); return true; });
        this.label.get_style_context ().add_class ("title");
        header.set_custom_title (this.label);
        header.pack_start (trash_button);
        header.set_decoration_layout ("");
        this.set_titlebar (header);

        this.label.changed.connect ((new_name) => {
            if (this.manager.rename (new_name)) {
                this.label.text = new_name;
            }
        });

        header.button_press_event.connect ((event) => {
            this.type_hint = Gdk.WindowTypeHint.NORMAL;
            this.begin_move_drag ((int) event.button, (int) event.x_root, (int) event.y_root, event.time);
            return false;
        });
    }

    /**
     * @name fade_in
     * @description fade the view in. does not call show
     */
    public void fade_in () {
        this.get_style_context ().remove_class ("df_fadeout");
        this.get_style_context ().add_class ("df_fadein");
    }

    /**
     * @name fade_out
     * @description fade the view out. does not call hide
     */
    public void fade_out () {
        this.get_style_context ().remove_class ("df_fadein");
        this.get_style_context ().add_class ("df_fadeout");
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
    protected virtual void resize_to (int width, int height) {
        // debug ("RESIZE_TO: %d,%d", width, height);
        this.set_default_size (width, height);
        this.resize (width, height);
    }

    /**
     * @name reload_settings
     * @description reload the window style in general
     */
    public void reload_settings () {
        NoteSettings settings = this.manager.get_settings ();
        if (settings.w > 0) {
            this.resize_to (settings.w, settings.h);
        }
        if (settings.x > 0 || settings.y > 0) {
            this.move_to (settings.x, settings.y);
        }

        List <unowned string> classes = this.get_style_context ().list_classes ();
        foreach (string class in classes) {
            if (class.has_prefix ("df_")) {
                this.get_style_context ().remove_class (class);
            }
        }

        this.get_style_context ().add_class ("df_folder");
        this.get_style_context ().add_class ("df_note");
        this.get_style_context ().add_class ("df_shadow");

        this.get_style_context ().add_class ("df_fadingwindow");
        if (this.manager.get_application ().get_desktop_visibility ()) {
            this.get_style_context ().add_class ("df_fadein");
            // setting opacity to stop the folder window flashing at startup
            this.opacity = 1;
        } else {
            this.get_style_context ().add_class ("df_fadeout");
            // ditto
            this.opacity = 0;
        }

        // applying existing colors configuration
        if (settings.bgcolor.has_prefix ("rgb")) {
            string custom = settings.bgcolor;
            this.set_custom_color (custom);
        } else {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (this.get_color_for_class (settings.bgcolor));
            rgba.alpha             = 0.6;
            this.last_custom_color = rgba.to_string ();
            this.get_style_context ().add_class (settings.bgcolor);
        }
        this.get_style_context ().add_class (settings.fgcolor);

        this.check_on_top ();
    }

    /**
     * @name get_color_for_class
     * @description return the correct color for a certain class
     * @param {string} class the class to obtain (@see BODY_TAGS_COLORS_CLASS)
     * @return {string} the color for the class passed
     */
    private string get_color_for_class (string class) {
        if (class == "df_transparent") {
            return "rgba(0,0,0,0)";
        } else {
            for (int i = 0; i < BODY_TAGS_COLORS_CLASS.length; i++) {
                if (BODY_TAGS_COLORS_CLASS[i] == class) {
                    return BODY_TAGS_COLORS[i];
                }
            }
        }
        return "rgba(0,0,0)";
    }

    /**
     * @name set_custom_color
     * @description utility function to set a custom color for the window
     * @param {string} custom the custom color to set (rgba(....))
     * @return {string} the real custom color applied
     */
    private string set_custom_color (string custom) {
        for (int i = 0; i < BODY_TAGS_COLORS_CLASS.length; i++) {
            string scolor = BODY_TAGS_COLORS_CLASS[i];
            this.get_style_context ().remove_class (scolor);
        }

        Gdk.RGBA rgba   = Gdk.RGBA ();
        rgba.parse (custom);
        string mycustom = custom;
        if (rgba.alpha == 1) {
            // this solves a bug wen setting an opaque color to gtk and vice
            rgba.alpha = 0.999;
            mycustom   = rgba.to_string ();
        }

        Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), this.custom_color_provider);
        try {
            string css =
                "#" + this.name + """.df_folder.window-frame, #""" + this.name + """.df_folder.window-frame:backdrop {
                border-color: """ + mycustom + """;
            }
            #""" + this.name + """.df_folder.background, #""" + this.name + """.df_folder.background:backdrop {
                background-color: """ + mycustom + """;
            }
            #""" + this.name + """.df_folder .titlebar, #""" + this.name + """.df_folder .titlebar:backdrop{
                background-color: """ + mycustom + """;
                border-color: """ + mycustom + """;
            }""";
            // debug("applying css:\n %s",css);
            this.custom_color_provider.load_from_data (css);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            DesktopFolder.Util.show_error_dialog ("Error", e.message);
        }
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), this.custom_color_provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        this.last_custom_color = mycustom;
        return mycustom;
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
                // debug("active");
                style.add_class ("df_active");
                this.check_window_type ();
                // we need to force a queue_draw
                this.queue_draw ();
                this.text.queue_draw ();
            }
        } else {
            if (style.has_class (sclass)) {
                // debug("inactive");
                style.remove_class ("df_active");
                // we need to force a queue_draw
                this.queue_draw ();
                this.text.queue_draw ();
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
        int w = 0;
        int h = 0;
        this.get_size (out w, out h);

        int x = 0;
        int y = 0;
        this.get_position (out x, out y);

        // debug ("set_new_shape:%i,%i,%i,%i", x, y, w, h);
        this.manager.set_new_shape (x, y, w, h);
    }

    /**
     * @name on_focus_out
     * @description focus out event
     * @param {Gdk.EventFocus} event the event launched
     * @return bool @see focus_out_event signal
     */
    private bool on_focus_out (Gdk.EventFocus event) {
        // This is to avoid minimization when Show Desktop shortcut is used
        // TODO: Is there a way to make a desktop window resizable and movable?
        this.check_window_type ();

        var buffer     = this.text.get_buffer ();
        var text       = buffer.text;
        var saved_text = this.manager.get_settings ().text;
        if (text != saved_text) {
            this.manager.on_text_change (text);
        }
        return false;
    }

    /**
     * @name on_enter_notify
     * @description On mouse entering the window
     */
    private bool on_enter_notify (Gdk.EventCrossing event) {
        // debug("NOTEWINDOW ENTER notify");
        trash_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hidden");
        return true;
    }

    /**
     * @name on_enter_leave
     * @description On mouse leaving the window
     */
    private bool on_leave_notify (Gdk.EventCrossing event) {
        // debug("NOTEWINDOW LEAVE notify");
        if (event.detail == Gdk.NotifyType.ANCESTOR || event.detail == Gdk.NotifyType.VIRTUAL || event.detail == Gdk.NotifyType.INFERIOR) {
            return false;
        }
        trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        return true;
    }

    /**
     * @name on_release
     * @description release event captured.
     * @return bool @see widget on_release signal
     */
    private bool on_release (Gdk.EventButton event) {
        // debug ("window release");
        // This is to avoid minimization when Show Desktop shortcut is used
        // TODO: Is there a way to make a desktop window resizable and movable?
        this.check_window_type ();
        return false;
    }

    /**
     * @name on_press
     * @description press event captured. The Window should show the popup on right button
     * @return bool @see widget on_press signal
     */
    private bool on_press (Gdk.EventButton event) {
        // debug("window press");

        // This is to allow moving and resizing the panel
        // TODO: Is there a way to make a desktop window resizable and movable?
        this.type_hint = Gdk.WindowTypeHint.NORMAL;

        // debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button == Gdk.BUTTON_SECONDARY)) {
            this.show_popup (event);
        } else if (event.type == Gdk.EventType.BUTTON_PRESS && (event.button == Gdk.BUTTON_PRIMARY)) {
            // int width  = this.get_allocated_width ();
            // int height = this.get_allocated_height ();
            // debug("x:%d,y:%d,width:%d,height:%d",(int)event.x,(int) event.y,width,height);

            /*
               if (event.x > 11 && event.y > 11) {
               // the corner need some extra space
               if (!(event.x < 31 && event.y < 31)) {
                   this.flag_dragging=true;
                   this.begin_move_drag ((int) event.button, (int) event.x_root, (int) event.y_root, event.time);
               }
               }
             */
        }
        return false;
    }

    /**
     * @name show_popup
     * @description build and show the popup menu
     * @param event EventButton the origin event, needed to position the menu
     */
    private void show_popup (Gdk.EventButton event) {
        this.check_window_type ();

        this.menu = new Gtk.Menu ();

        if (!this.manager.get_application ().get_desktoppanel_enabled ()) {
            Gtk.MenuItem item_new = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_SUBMENU);
            menu.append (item_new);

            Gtk.Menu newmenu = new Gtk.Menu ();
            item_new.set_submenu (newmenu);

            Gtk.MenuItem item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
            item.activate.connect ((item) => {
                this.new_desktop_folder ((int) event.x, (int) event.y);
            });
            newmenu.append (item);

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LINK_PANEL);
            item.activate.connect ((item) => {
                this.new_link_panel ((int) event.x, (int) event.y);
            });
            newmenu.append (item);

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
            item.activate.connect ((item) => {
                this.new_note ((int) event.x, (int) event.y);
            });
            newmenu.append (item);

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);
            item.activate.connect ((item) => {
                this.new_photo ((int) event.x, (int) event.y);
            });
            newmenu.append (item);

            menu.append (new MenuItemSeparator ());
        }

        Gtk.MenuItem item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_PAPER_NOTE);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().texture == "square_paper");
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
            this.on_texture ("square_paper");
        });
        menu.append (item);

        menu.append (new MenuItemSeparator ());

        item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_ON_TOP);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().on_top);
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
            this.on_toggle_on_top ();
        });
        menu.append (item);

        item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_ON_BACK);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().on_back);
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
            this.on_toggle_on_back ();
        });
        menu.append (item);

        menu.append (new MenuItemSeparator ());

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_DELETE_NOTE);
        item.activate.connect ((item) => { this.manager.trash (); });
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_RENAME_NOTE);
        item.activate.connect (this.label.start_editing);
        menu.append (item);

        item = new MenuItemColor (HEAD_TAGS_COLORS, null);
        ((MenuItemColor) item).color_changed.connect (change_head_color);
        menu.append (item);

        item = new MenuItemColor (BODY_TAGS_COLORS, this.last_custom_color);
        ((MenuItemColor) item).color_changed.connect (change_body_color);
        ((MenuItemColor) item).custom_changed.connect (change_body_color_custom);
        menu.append (item);

        menu.show_all ();
        menu.popup_at_pointer (null);
    }

    /**
     * @name on_texture
     * @description set the texture for the note window
     * @param {string} texture the texture to apply
     */
    private void on_texture (string texture) {
        string current_texture = this.manager.get_settings ().texture;
        if (current_texture == texture) {
            this.manager.get_settings ().texture = "";
        } else {
            this.manager.get_settings ().texture = texture;
        }
        this.manager.get_settings ().save ();
        this.queue_draw ();
    }

    /**
     * @name new_desktop_folder
     * @description create a new desktop folder
     */
    private void new_desktop_folder (int x, int y) {
        DesktopFolder.Util.create_new_desktop_folder (this, x, y);
    }

    /**
     * @name new_link_panel
     * @description create a new link panel
     */
    private void new_link_panel (int x, int y) {
        DesktopFolder.Util.create_new_link_panel (this, x, y);
    }

    /*
     * @name new_note
     * @description create a new note
     */
    private void new_note (int x, int y) {
        DesktopFolder.Util.create_new_note (this, x, y);
    }

    /**
     * @name new_photo
     * @description create a new photo
     */
    private void new_photo (int x, int y) {
        DesktopFolder.Util.create_new_photo (this, x, y);
    }

    /**
     * @name change_head_color
     * @description change event captured from the popup for a new color to the head window
     * @param ncolor int the new color for the head window
     */
    private void change_head_color (int ncolor) {
        string color = HEAD_TAGS_COLORS_CLASS[ncolor];
        for (int i = 0; i < HEAD_TAGS_COLORS_CLASS.length; i++) {
            string scolor = HEAD_TAGS_COLORS_CLASS[i];
            this.get_style_context ().remove_class (scolor);
        }
        this.get_style_context ().add_class (color);
        this.manager.save_head_color (color);
    }

    /**
     * @name change_body_color
     * @description change event captured from the popup for a new color to the body window
     * @param ncolor int the new color for the body window
     */
    private void change_body_color (int ncolor) {
        string color = BODY_TAGS_COLORS_CLASS[ncolor];
        for (int i = 0; i < BODY_TAGS_COLORS_CLASS.length; i++) {
            string scolor = BODY_TAGS_COLORS_CLASS[i];
            this.get_style_context ().remove_class (scolor);
        }
        if (this.custom_color_provider != null) {
            Gtk.StyleContext.remove_provider_for_screen (Gdk.Screen.get_default (), this.custom_color_provider);
        }

        if (ncolor > 0) {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (BODY_TAGS_COLORS[ncolor]);
            this.last_custom_color = rgba.to_string ();
        } else {
            this.last_custom_color = "rgba(0,0,0,0)";
        }

        this.get_style_context ().add_class (color);
        this.manager.save_body_color (color);
        // debug("color:%d,%s",ncolor,color);
    }

    /**
     * @name change_body_color_custom
     * @description change event captured from the popup for a new color to the body window
     * @param custom string the new custom color
     */
    public void change_body_color_custom (string custom) {
        string mycustom = this.set_custom_color (custom);
        this.manager.save_body_color (mycustom);
    }

    /**
     * @name draw_backgorund
     * @description draw the note window background intercepting the draw signal
     * @param {Cairo.Context} cr the cairo context
     * @bool @see draw signal
     */
    private bool draw_background (Cairo.Context cr) {
        // util code to draw the whole window background (which contains also the decoration and you can size it)
        // cr.rectangle(0,0,10000,10000);
        // cr.set_source_rgba (1, 1, 1, 0.2);
        // cr.fill();

        int width  = this.get_allocated_width ();
        int height = this.get_allocated_height ();

        cr.set_operator (Cairo.Operator.CLEAR);
        cr.paint ();
        cr.set_operator (Cairo.Operator.OVER);

        /*
           var background_style = this.get_style_context ();
           background_style.render_background (cr, 0, 0, width, height);
           background_style.render_frame (cr, 0, 0, width, height);
         */

        // shaping
        shape (cr, width, height);
        cr.clip ();

        if (this.manager.get_settings ().texture == "square_paper") {
            try {
                if (this.texture_pattern == null) {
                    var pixbuf  = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/hip-square.png");
                    var surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
                    this.texture_pattern = new Cairo.Pattern.for_surface (surface);
                    this.texture_pattern.set_extend (Cairo.Extend.REPEAT);
                }

                cr.set_source (this.texture_pattern);
                cr.paint_with_alpha (0.9);
            } catch (Error e) {
                // error! ??
                stderr.printf ("Error: %s\n", e.message);
            }
        }

        // drawing border
        shape (cr, width, height);
        cr.set_line_width (3.0);
        cr.set_source_rgba (0, 0, 0, 0.2);
        cr.stroke ();

        // drawing corner
        draw_corner (cr, width, height);
        cr.set_source_rgba (0, 0, 0, 0.4);
        cr.stroke ();

        base.draw (cr);

        cr.reset_clip ();

        // drawing clip
        try {
            if (this.clip_surface == null) {
                int clipcolor = this.manager.get_settings ().clipcolor;
                var color     = "";
                switch (clipcolor) {
                case 1:
                    color = "blue";
                    break;
                case 2:
                    color = "green";
                    break;
                case 3:
                    color = "orange";
                    break;
                case 4:
                    color = "pink";
                    break;
                case 5:
                    color = "red";
                    break;
                default:
                case 6:
                    color = "yellow";
                    break;
                }
                var pixbuf = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/clip-" + color + ".png");
                this.clip_surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
            }
            cr.set_source_surface (this.clip_surface, 5, 5);
            cr.paint ();
        } catch (Error e) {
            // error! ??
            stderr.printf ("Error: %s\n", e.message);
        }

        return true;
    }

    private void draw_corner (Cairo.Context cr, double width, double height) {
        int margin      = 15;
        int rightRadius = 25;
        cr.move_to (width - margin - rightRadius, margin);
        cr.line_to (width - margin - rightRadius, margin + rightRadius);
        cr.line_to (width - margin, margin + rightRadius);
    }

    /**
     * @name shape
     * @description shape the window with the shape of a note
     * @param {Cairo.Context} cr the context to draw
     * @param double width the width of the window
     * @param double height the height of the window
     */
    private void shape (Cairo.Context cr, double width, double height) {
        int margin      = 15;
        int radius      = 2;
        int rightRadius = 25;

        cr.move_to (margin, margin + radius);

        ///
        cr.line_to (margin + radius, margin);
        // -
        cr.line_to (width - margin - rightRadius, margin);
        // \ (top right corner)
        cr.line_to (width - margin, margin + rightRadius);
        // |
        cr.line_to (width - margin, height - margin - radius);
        ///
        cr.line_to (width - margin - radius, height - margin);
        // -
        cr.line_to (margin + radius, height - margin);
        // \ (top right corner)
        cr.line_to (margin, height - margin - radius);
        // |
        cr.line_to (margin, margin + radius);
        cr.close_path ();
    }

    /**
     * @name on_toggle_on_top
     * @description toggle the on top setting
     */
    protected void on_toggle_on_top () {
        this.manager.get_settings ().on_top = !this.manager.get_settings ().on_top;
        if (this.manager.get_settings ().on_top) {
            this.manager.get_settings ().on_back = false;
        }
        this.manager.get_settings ().save ();
        this.check_on_top ();
        this.manager.reopen ();
    }

    /**
     * @name on_toggle_on_back
     * @description toggle the on back setting
     */
    protected void on_toggle_on_back () {
        this.manager.get_settings ().on_back = !this.manager.get_settings ().on_back;
        if (this.manager.get_settings ().on_back) {
            this.manager.get_settings ().on_top = false;
        }
        this.manager.get_settings ().save ();
        this.check_on_top ();
        this.manager.reopen ();
    }

    /**
     * @name check_on_top
     * @description check the current settings to put the window above or not
     */
    private void check_on_top () {
        this.check_window_type ();
        if (this.manager.get_settings ().on_top) {
            this.set_keep_above (true);
        } else {
            this.set_keep_above (false);
        }
    }

    /**
     * @name check_window_type
     * @description check whether the window should have a normal or desktop type
     */
    private void check_window_type () {
        if (this.manager != null) {
            var settings = this.manager.get_settings ();
            if (settings == null || settings.on_back) {
                this.type_hint = Gdk.WindowTypeHint.DESKTOP;
            } else {
                this.type_hint = Gdk.WindowTypeHint.NORMAL;
            }
        }
    }

}
