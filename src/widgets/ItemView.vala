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

public class DesktopFolder.ItemView : Gtk.EventBox {

    // NOT SURE ABOUT THESE CONSTANTS!!! TODO!!!!!
    public const int PADDING_X       = 10;
    public const int PADDING_Y       = 44;
    // DEFAULT SIZES
    private const int ICON_WIDTH     = 48;
    private const int DEFAULT_WIDTH  = 90;
    private const int DEFAULT_HEIGHT = 90;
    private const int MAX_CHARACTERS = 13;
    /** flag to know that the item has been moved */
    private bool flagModified        = false;
    private bool flagMoved           = false;
    /** the manager of this item icon */
    private ItemManager manager;
    /** the context menu for this item */
    private Gtk.Menu menu = null;

    /** flag to know if we should hide the extension of the file */
    private bool hide_extension     = false;
    /** the hidden extension of the file, it it was hidden, @see hide_extension*/
    private string hidden_extension = "";

    /** the container of this item view */
    private Gtk.Box container;
    /** the label of the icon */
    private DesktopFolder.EditableLabel label;
    /** the image shown */
    private Gtk.Image icon             = null;
    /** flag to know whether the drag drop event was started */
    private bool flag_dragdrop_started = false;
    /** the last drag_context used to allow canceling it */
    private Gdk.DragContext drag_context;


    /** set of variables to allow move the widget */
    private int offsetx;
    private int offsety;
    private int px;
    private int py;
    private int maxx;
    private int maxy;
    /** ----------------------------------------- */

    // this is the link image loaded
    static Gdk.Pixbuf LINK_PIXBUF = null;
    static construct {
        try {
            int scale = DesktopFolder.ICON_SIZE / 3;
            ItemView.LINK_PIXBUF = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/link.svg");
            ItemView.LINK_PIXBUF = LINK_PIXBUF.scale_simple (scale, scale, Gdk.InterpType.BILINEAR);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @constructor
     * @param ItemManager manager the manager of this item view
     */
    public ItemView (ItemManager manager) {
        this.manager = manager;

        // we set the default size
        this.set_size_request (DEFAULT_WIDTH, DEFAULT_HEIGHT);
        // class for this widget
        this.get_style_context ().add_class ("df_item");

        this.get_style_context ().add_class ("df_fadingwindow");
        this.get_style_context ().add_class ("df_fadeout");

        // we connect the enter and leave events
        this.enter_notify_event.connect (this.on_enter);
        this.leave_notify_event.connect (this.on_leave);
        this.button_press_event.connect (this.on_press);
        this.button_release_event.connect (this.on_release);
        this.motion_notify_event.connect (this.on_motion);

        // we create the components to put inside the item (icon and label)
        this.container        = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        this.container.margin = 0;
        this.container.set_size_request (DEFAULT_WIDTH, DEFAULT_HEIGHT);

        this.refresh_icon ();
        string slabel = this.get_correct_label (this.manager.get_file_name ());
        this.create_label (slabel);

        this.add (this.container);

    }

    /**
     * @name create_headerbar
     * @description create the header bar
     */
    protected virtual void create_label (string slabel) {
        try {
            // debug ("Create label for %s", this.manager.get_file_name ());

            this.label = new DesktopFolder.EditableLabel (slabel);
            this.container.pack_end (label, true, true, 0);
            this.check_ellipse ();

            label.changed.connect ((new_name) => {
                if (this.manager.rename (new_name + this.hidden_extension)) {
                    label.text = new_name;
                    this.check_ellipse ();
                }
            });

            label.on_start_editing.connect (() => {
                this.manager.get_folder ().get_view ().on_start_editing ();
            });
            label.on_stop_editing.connect (() => {
                this.manager.get_folder ().get_view ().on_end_editing ();
            });
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name rename
     * @description change the label of the item to the new label
     */
    public void rename (string new_name) {
        this.label.text = new_name;
        this.refresh_icon ();
    }

    /**
     * @name refresh
     * @description refresh the window
     */
    public void refresh () {
        if (this.manager.get_folder ().get_application ().get_desktop_visibility ()) {
            this.fade_in ();
            this.show_all ();
        }
    }

    /**
     * @name refresh_icon
     * @description force to refresh the icon imagen shown
     */
    public void refresh_icon (string ? forced = null) {
        try {
            Gtk.Image newImage;

            if (forced == null) {
                newImage = this.calculate_icon ();
            } else {
                GLib.Icon gicon = GLib.Icon.new_for_string ("folder-open");
                if (this.manager.is_link ()) {
                    newImage = this.draw_link_mark_gicon (gicon);
                } else {
                    newImage = new Gtk.Image.from_gicon (gicon, Gtk.IconSize.DIALOG);
                }
            }

            if (this.icon != null) {
                this.container.remove (this.icon);
            }

            this.icon = newImage;
            this.icon.set_size_request (ICON_WIDTH, ICON_WIDTH);
            this.icon.get_style_context ().add_class ("df_icon");
            this.container.pack_start (this.icon, true, true);
            this.refresh ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name force_opened_folder_icon
     * @description put the folder-open icon over the item
     */
    public void force_opened_folder_icon () {
        this.refresh_icon ("folder-open");
    }

    /**
     * @return the image icon
     */
    public Gtk.Image get_image () {
        return this.icon;
    }

    /**
     * @name calculate_icon
     * @description calculate the icon image to show
     * @return Gtk.Image the image to be shown
     */
    private Gtk.Image calculate_icon () {
        try {
            Gtk.Image icon;
            var       fileInfo = this.manager.get_file ().query_info ("standard::icon", FileQueryInfoFlags.NONE);
            if (manager.get_settings ().icon != null && manager.get_settings ().icon.length > 0) {
                // We have a custom icon
                int        scale  = DesktopFolder.ICON_SIZE;
                Gdk.Pixbuf custom = new Gdk.Pixbuf.from_file_at_scale (manager.get_settings ().icon, scale, scale, true);
                // custom = custom.scale_simple (scale, scale, Gdk.InterpType.BILINEAR);
                if (this.manager.is_link ()) {
                    icon = this.draw_link_mark_pixbuf (custom);
                } else {
                    icon = new Gtk.Image.from_pixbuf (custom);
                }
            } else {
                // checking if the file still exists... we need to check following symlinks!
                if (!this.manager.check_exist_cached ()) {
                    // the file doesn't exist
                    GLib.ThemedIcon themed = new ThemedIcon.with_default_fallbacks ("text-x-generic");
                    var info               = Gtk.IconTheme.get_default ().lookup_by_gicon (themed, ICON_WIDTH, 0);
                    var pixbuf             = info.load_icon ();
                    if (pixbuf.height != ICON_WIDTH) {
                        // Some icons don't return the requested size, so we need to scale them
                        pixbuf = pixbuf.scale_simple (ICON_WIDTH, ICON_WIDTH, Gdk.InterpType.BILINEAR);
                    }
                    // drawing a cross over the icon
                    icon = draw_not_exist_mark_pixbuf (pixbuf);

                } else if (this.manager.is_desktop_file ()) {
                    GLib.DesktopAppInfo desktopApp = new GLib.DesktopAppInfo.from_filename (this.manager.get_absolute_path ());
                    GLib.Icon           gicon      = desktopApp.get_icon ();
                    if (this.manager.is_link ()) {
                        icon = this.draw_link_mark_gicon (gicon);
                    } else {
                        GLib.ThemedIcon themed = new GLib.ThemedIcon.with_default_fallbacks (gicon.to_string ());
                        var        info        = Gtk.IconTheme.get_default ().lookup_by_gicon (themed, ICON_WIDTH, 0);
                        Gdk.Pixbuf pixbuf      = null;
                        if (info == null) {
                            // force a large icon load to ensure icons like svg's are scaled correctly later
                            pixbuf = new Gdk.Pixbuf.from_file_at_scale (gicon.to_string (), ICON_WIDTH, ICON_WIDTH, true);
                        } else {
                            pixbuf = info.load_icon ();
                        }

                        if (pixbuf.height != ICON_WIDTH) {
                            // Some icons don't return the requested size, so we need to scale them
                            pixbuf = pixbuf.scale_simple (ICON_WIDTH, ICON_WIDTH, Gdk.InterpType.BILINEAR);
                            icon   = new Gtk.Image.from_pixbuf (pixbuf);
                        } else {
                            icon = new Gtk.Image.from_gicon (gicon, Gtk.IconSize.DIALOG);
                        }
                    }
                } else {
                    var    ctypeInfo   = this.manager.get_file ().query_info ("standard::content-type", FileQueryInfoFlags.NONE);
                    string contentType = ctypeInfo.get_content_type ();
                    string mimeType    = GLib.ContentType.get_mime_type (contentType);
                    var    isImage     = GLib.ContentType.is_a (mimeType, "image/*");
                    if (mimeType != null && isImage) {
                        // reading the image to show it
                        int        scale  = DesktopFolder.ICON_SIZE;
                        Gdk.Pixbuf custom = new Gdk.Pixbuf.from_file (this.manager.get_file ().get_path ());
                        custom = custom.scale_simple (scale, scale, Gdk.InterpType.BILINEAR);
                        if (this.manager.is_link ()) {
                            icon = this.draw_link_mark_pixbuf (custom);
                        } else {
                            icon = new Gtk.Image.from_pixbuf (custom);
                        }
                    } else {
                        // we get the default icon from the system
                        GLib.Icon gicon = fileInfo.get_icon ();
                        if (this.manager.is_link ()) {
                            icon = this.draw_link_mark_gicon (gicon);
                        } else {
                            icon = new Gtk.Image.from_gicon (gicon, Gtk.IconSize.DIALOG);
                        }
                    }
                }
            }
            return icon;
        } catch (Error e) {
            try {
                stderr.printf ("Error: %s\n", e.message);
                Gtk.Image icon;
                icon = new Gtk.Image.from_icon_name ("image-x-generic", Gtk.IconSize.DIALOG);
                return icon;
            } catch (Error ee) {
                stderr.printf ("Error: %s\n", ee.message);
                Util.show_error_dialog ("Error", ee.message);
            }
        }
    }

    /**
     * @name draw_not_exist_mark_pixbuf
     * @description draw a CROSS mark to indicate that the file doesn't exist
     * @param pixbuf {Gdk.Pixbuf} the pixbuf to modify
     * @result {Gtk.Image} the image produced
     */
    private Gtk.Image draw_not_exist_mark_pixbuf (Gdk.Pixbuf pixbuf) {
        try {
            var surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
            var context = new Cairo.Context (surface);

            context.set_source_rgba (1, 0, 0, 1);
            context.move_to (0, 0);
            context.line_to (ICON_SIZE, ICON_SIZE);
            context.move_to (ICON_SIZE, 0);
            context.line_to (0, ICON_SIZE);
            context.stroke ();

            var       pixbuf2 = Gdk.pixbuf_get_from_surface (surface, 0, 0, ICON_SIZE, ICON_SIZE);
            Gtk.Image icon    = new Gtk.Image.from_pixbuf (pixbuf2);
            return icon;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name draw_link_mark_gicon
     * @description draw a link mark over the image of an icon
     * @param gicon {GLib.Icon} the icon we want to modify and add the mark
     * @result {Gtk.Image} the image produced
     */
    private Gtk.Image draw_link_mark_gicon (GLib.Icon gicon) {
        try {
            Gtk.IconTheme theme    = Gtk.IconTheme.get_default ();
            Gtk.IconInfo  iconInfo = theme.lookup_by_gicon (gicon, ICON_SIZE, 0);
            Gdk.Pixbuf    pixbuf   = iconInfo.load_icon ();

            if (pixbuf.height != ICON_WIDTH) {
                // some icons doesn't return the asked size, so we need to scale them
                pixbuf = pixbuf.scale_simple (ICON_WIDTH, ICON_WIDTH, Gdk.InterpType.BILINEAR);
            }

            return this.draw_link_mark_pixbuf (pixbuf);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
        return null as Gtk.Image;
    }

    /**
     * @name draw_link_mark_pixbuf
     * @description draw a link mark over a pixbuf
     * @param pixbuf {Gdk.Pixbuf} the pixbuf to modify
     * @result {Gtk.Image} the image produced
     */
    private Gtk.Image draw_link_mark_pixbuf (Gdk.Pixbuf pixbuf) {
        try {
            var surface = Gdk.cairo_surface_create_from_pixbuf (pixbuf, 1, null);
            var context = new Cairo.Context (surface);

            int scale   = DesktopFolder.ICON_SIZE / 3;
            var links   = Gdk.cairo_surface_create_from_pixbuf (ItemView.LINK_PIXBUF, 1, null);
            context.set_source_surface (links, ICON_SIZE - scale, ICON_SIZE - scale);
            context.paint ();

            var       pixbuf2 = Gdk.pixbuf_get_from_surface (surface, 0, 0, ICON_SIZE, ICON_SIZE);
            Gtk.Image icon    = new Gtk.Image.from_pixbuf (pixbuf2);
            return icon;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name get_correct_label
     * @description return the correct label to be shown
     */
    private string get_correct_label (string file_name) {
        if (this.hide_extension) {
            int index = file_name.index_of (".", 0);
            if (index > 0) {
                hidden_extension = file_name.substring (index);
                return file_name.substring (0, index);
            }
            hidden_extension = "";
            return file_name;
        } else {
            int index = file_name.index_of (".desktop", 0);
            if (index > 0) {
                // is a desktop file!
                this.hide_extension = true;
                hidden_extension    = file_name.substring (index);
                return file_name.substring (0, index);
            }
            hidden_extension = "";
            return file_name;
        }
    }

    /**
     * @name check_ellipse
     * @description check if the ellipse should be shown
     * @param string name the name to be shown in order to calculate if the ellipse will be shown
     */
    private void check_ellipse () {
        // debug ("check ellipse!");
        if (this.label.text.length > MAX_CHARACTERS) {
            this.label.set_lines (2);
            this.label.set_ellipsize (Pango.EllipsizeMode.END);
        } else {
            this.label.set_lines (1);
            this.label.set_ellipsize (Pango.EllipsizeMode.NONE);
        }
    }

    /**
     * @name on_enter
     * @description on_enter signal to highlight the icon
     * @param eventCrossing EventCrossing @see on_enter signal
     * @return bool @see the on_enter signal
     */
    private bool on_enter (Gdk.EventCrossing eventCrossing) {
        this.get_style_context ().add_class ("df_item_over");
        // debug("enter item");
        bool single_click = this.manager.get_folder ().get_application ().get_single_click ();

        if (single_click && !this.flagModified) {
            get_window ().set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default (), "pointer"));
        }

        return true;
    }

    /**
     * @name cancel_movement_and_start_drag_action
     * @description cancel the current icon movement and start a drag action instead
     */
    private void cancel_movement_and_start_drag_action (Gdk.Event event) {
        this.flagModified = false;

        this.drag_context = Gtk.drag_begin_with_coordinates (this,
                new Gtk.TargetList (DesktopFolder.DragnDrop.drag_targets),
                DesktopFolder.DragnDrop.file_drag_actions,
                Gdk.BUTTON_PRIMARY,
                event, -1, -1);
        this.flag_dragdrop_started = true;

        // restoring the icon position
        // debug("restoring to: %d,%d",manager.get_settings ().x,manager.get_settings ().y);
        // now, moving the rest of selected items to replicate the main movement
        Gee.List <ItemView> selecteds = this.manager.get_folder ().get_selected_items ();
        for (int i = 0; i < selecteds.size; i++) {
            ItemView selected = selecteds.@get (i);
            UtilGtkAnimation.animate_move (selected, selected.start_drag_point, 500, UtilFx.AnimationMode.EASE_OUT_BACK);
            var settings      = selected.manager.get_settings ();
            settings.x = selected.start_drag_point.x;
            settings.y = selected.start_drag_point.y;
            selected.manager.save_settings (settings);
            selected.manager.get_folder ().get_view ().on_item_moving (false);

        }
    }

    /**
     * @name on_leave
     * @description on_leave signal to remove highlight of the icon
     * @param eventCrossing EventCrossing @see on_enter signal
     * @return bool @see the on_leave signal
     */
    public bool on_leave (Gdk.EventCrossing ? eventCrossing) {
        // debug ("detail: %d", eventCrossing.detail);
        // we remove the highlight class
        this.get_style_context ().remove_class ("df_item_over");


        if (this.flagMoved) {
            if (this.manager.get_folder ().get_view () is DesktopWindow && eventCrossing.y < 0) {
                return true;
            }
            // if the item is outside the current windows, we cancel the movement, and start dragging
            Gtk.Allocation allocation;
            this.get_allocation (out allocation);
            FolderWindow window = this.manager.get_folder ().get_view ();
            int          window_width;
            int          window_height;
            window.get_size (out window_width, out window_height);
            if (eventCrossing.detail == Gdk.NotifyType.NONLINEAR ||
                eventCrossing.detail == Gdk.NotifyType.NONLINEAR_VIRTUAL ||
                (
                    !(this.manager.get_folder ().get_view () is DesktopWindow)
                    &&
                    (
                        allocation.x < 0 ||
                        allocation.y < 0 ||
                        allocation.x > window_width - DesktopFolder.ICON_DEFAULT_WIDTH ||
                        allocation.y > window_height - DesktopFolder.ICON_DEFAULT_WIDTH
                    )
                )
            ) {
                this.cancel_movement_and_start_drag_action (eventCrossing);

            }
        } else if (this.flagModified) {
            this.manager.save_current_position ();
            this.flagModified = false;
        }
        return true;
    }

    /**
     * @name start_editing
     * @description action of rename the item selected by the user
     * @param string new_name the new name for this item
     */
    public void start_editing () {
        // debug ("renaming ItemView");
        this.label.start_editing ();
    }

    ///**
    // * @name force_adjust_label
    // * @description util function to force the label to readjust
    // * sometimes, the label change its appareance, but it is not adjusted automatically
    // * this function force the adjust
    // */
    // public void force_adjust_label () {
    // this.label.title_label.set_label (this.label.title_label.get_text ());
    // }

    /**
     * @name select
     * @description the user select the icon
     */
    public void select_only () {
        Gtk.Window window = (Gtk.Window) this.get_toplevel ();
        ((FolderWindow) window).unselect_all ();
        this.manager.select_only ();
        this.get_style_context ().add_class ("df_selected");

    }

    public void select_add () {
        this.manager.select_add ();
        this.get_style_context ().add_class ("df_selected");
    }

    /**
     * @name unselect
     * @description unselect the icon
     */
    public void unselect () {
        this.manager.unselect ();
        this.get_style_context ().remove_class ("df_selected");
    }

    /**
     * @name is_selected
     * @description check whether the item is selected or not
     * @return bool true->is selected
     */
    public bool is_selected () {
        return this.manager.is_selected ();
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
     * @name on_release
     * @description the release button event
     * @param EventButton event the event produced
     * @return bool @see on_release signal
     */
    private bool on_release (Gdk.EventButton event) {
        /*
           //TODO IF WE DO THIS ON PRESS EVENT, THE MOTION IS ALTERED
           //I'VE NOT FOUND A WAY TO ALTER THE Z ORDER WITHOUT REMOVING AND ADDING AGAIN FROM CONTAINER :(
           //we will move to top this icon
           Gtk.Allocation allocation;
           this.get_allocation(out allocation);
           //HELP! don't know why these constants?? maybe padding??
           int x=allocation.x - PADDING_X;
           int y=allocation.y - PADDING_Y;
           ((FolderWindow)this.manager.get_application_window()).raise(this,x,y);

           return true;
         */
        // if the icon wasnt moved, maybe we must execute it
        // depending if the files preferences single-click was activated

        var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);

        this.flag_dragdrop_started = false;

        // Change cursor
        get_window ().set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default (), "default"));

        // we notify that we are stopping to move
        this.manager.get_folder ().get_view ().on_item_moving (false);

        if (!this.flagMoved) {
            bool single_click = this.manager.get_folder ().get_application ().get_single_click ();

            if (single_click && !control_pressed && event.type == Gdk.EventType.BUTTON_RELEASE && event.button == Gdk.BUTTON_PRIMARY) {
                on_double_click ();
            }
        } else {
            this.flagMoved = false;
            Gtk.Allocation allocation;
            this.get_allocation (out allocation);
            // debug("release(%d,%d)",allocation.x,allocation.y);
            // HELP! don't know why these constants?? maybe padding??
            int x = allocation.x; // - PADDING_X;
            int y = allocation.y; // - PADDING_Y;

            FolderArrangement arrangement = this.manager.get_folder ().get_arrangement ();
            int sensitivity               = arrangement.get_sensitivity ();
            int padding = this.manager.get_folder ().get_settings ().arrangement_padding;
            x = RoundToNearestMultiple (int.max (int.min (x, this.maxx), 0), sensitivity + padding);
            y = RoundToNearestMultiple (int.max (int.min (y, this.maxy), 0), sensitivity + padding);

            if (this.manager.get_folder ().get_arrangement ().have_margin ()) {
                x = x + FolderArrangement.DEFAULT_EXTERNAL_MARGIN;
            }

            Gtk.Window window = (Gtk.Window) this.get_toplevel ();
            ((FolderWindow) window).move_item (this, x, y);

            int diff_x = allocation.x - x;
            int diff_y = allocation.y - y;


            // notifying to the arrangement
            this.manager.get_folder ().get_arrangement ().end_drag ();
            ItemSettings my_settings = this.manager.get_settings ();
            my_settings.x = x;
            my_settings.y = y;
            this.manager.save_settings (my_settings);

            // now, moving the rest of selected items to replicate the main movement
            Gee.List <ItemView> selecteds = this.manager.get_folder ().get_selected_items ();
            for (int i = 0; i < selecteds.size; i++) {
                ItemView selected = selecteds.@get (i);
                if (selected != this) {
                    Gtk.Allocation allocation_selected;
                    selected.get_allocation (out allocation_selected);
                    int sel_x = allocation_selected.x - diff_x;
                    int sel_y = allocation_selected.y - diff_y;
                    ((FolderWindow) window).move_item (selected, sel_x, sel_y);

                    // we simulate a drag to move the conflict items in that position of the grid
                    this.manager.get_folder ().get_arrangement ().start_drag (selected);
                    this.manager.get_folder ().get_arrangement ().motion_drag (sel_x + PADDING_X, sel_y);
                    this.manager.get_folder ().get_arrangement ().end_drag ();

                    ItemSettings sel_settings = selected.manager.get_settings ();
                    sel_settings.x = sel_x;
                    sel_settings.y = sel_y;
                    selected.manager.save_settings (sel_settings);

                }
            }

        }

        return false;
    }

    /**
     * @name get_manager
     * @description return the manager of this view
     * @return {ItemManager} the manager
     */
    public ItemManager get_manager () {
        return this.manager;
    }

    /**
     * @name is_dragdrop_started
     * @description return whether the item has started a drag drop event
     * @return true -> yes, it was started, false otherwise
     */
    public bool is_dragdrop_started () {
        return this.flag_dragdrop_started;
    }

    /**
     * @name on_drag_end
     * @description drag end event
     */
    public void on_drag_end () {
        this.flag_dragdrop_started = false;
    }

    /** start drag point to restore if the drag was cancelled */
    private Gdk.Point start_drag_point = Gdk.Point ();

    /**
     * @name on_press
     * @description the mouse press event captured
     * @param EventButton event the event produced
     * @return bool @see on_press signal
     */
    private bool on_press (Gdk.EventButton event) {
        // debug("press:%i",(int)event.button);
        manager.get_folder ().get_view ().present ();
        // Change cursor to closed hand
        get_window ().set_cursor (new Gdk.Cursor.from_name (Gdk.Display.get_default (), "grabbing"));

        // this code is to allow the drag'ndrop of files inside the folder window
        var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
        bool shift_pressed   = ((mods & Gdk.ModifierType.SHIFT_MASK) != 0);
        bool can_drag        = this.manager.get_folder ().get_arrangement ().can_drag ();
        bool locked          = this.manager.get_folder ().are_items_locked ();

        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            event.button == Gdk.BUTTON_PRIMARY &&
            (control_pressed || !can_drag || locked) &&
            this.is_selected ()) {
            this.flag_dragdrop_started = true;
            return false;
        }

        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            event.button == Gdk.BUTTON_PRIMARY &&
            (control_pressed || shift_pressed)) {

            if (!this.is_selected ()) {
                this.select_add ();
            } else {
                this.unselect ();
            }
            return false;
        }



        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY) {
            // first we must select the item
            if (!this.is_selected ()) {
                this.select_only ();
            }
            this.flagMoved = false;

            if (!this.manager.get_folder ().are_items_locked () &&
                this.manager.get_folder ().get_arrangement ().can_drag ()) {
                Gee.List <ItemView> selecteds = this.manager.get_folder ().get_selected_items ();
                for (int i = 0; i < selecteds.size; i++) {
                    ItemView selected = selecteds.@get (i);
                    selected.start_drag_point.x = selected.manager.get_settings ().x;
                    selected.start_drag_point.y = selected.manager.get_settings ().y;

                }

                Gtk.Widget p = this.parent;
                // offset == distance of parent widget from edge of screen ...
                p.get_window ().get_position (out this.offsetx, out this.offsety);
                // debug ("offset_1: %i,%i", this.offsetx, this.offsety);
                // plus distance from pointer to edge of widget
                this.offsetx += (int) event.x + PADDING_X + PADDING_X;
                this.offsety += (int) event.y + PADDING_Y;
                // debug ("offset_2: %i,%i", this.offsetx, this.offsety);

                // if it was grabed the title_label, the event position (y) need to be recalculated
                if (event.window == this.label.title_label.get_window ()) {
                    int my_x = 0;
                    int my_y = 0;
                    this.translate_coordinates (this.label.title_label, (int) event.x, (int) event.y, out my_x, out my_y);
                    this.offsety -= my_y;
                    // debug ("offset_3 %i,%i", this.offsetx, this.offsety);
                }

                // creating a map of the current grid structure
                this.manager.get_folder ().get_arrangement ().start_drag (this);

                // maxx, maxy both relative to the parent
                // note that we're rounding down now so that these max values don't get
                // rounded upward later and push the widget off the edge of its parent.
                Gtk.Allocation pAllocation;
                p.get_allocation (out pAllocation);
                Gtk.Allocation thisAllocation;
                this.get_allocation (out thisAllocation);
                this.maxx = RoundDownToMultiple (pAllocation.width - thisAllocation.width, this.manager.get_folder ().get_arrangement ().get_sensitivity ());
                this.maxy = RoundDownToMultiple (pAllocation.height - thisAllocation.height, this.manager.get_folder ().get_arrangement ().get_sensitivity ());
            } else {
                // we must ensure the event is not processed by the folder window parent to avoid unselections
                return true;
            }
        } else if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
            if (!this.is_selected ()) {
                this.select_only ();
            }
            on_double_click ();
        } else if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_SECONDARY) {
            if (!this.is_selected ()) {
                this.select_only ();
            }
            this.show_popup (event);
        }

        return true;
    }

    /**
     * @name on_double_click
     * @description double click event captured
     */
    private void on_double_click () {
        // debug("doble click! %s",this.fileName);
        this.execute ();
    }

    /**
     * @name execute
     * @description execute the action associated with the item
     */
    public void execute () {
        this.manager.execute ();
    }

    /**
     * @name show_popup
     * @description show the context popup for this item
     * @param EventButton event the event button that originates this context menu
     */
    private void show_popup (Gdk.EventButton event) {

        // debug("evento:%f,%f",event.x,event.y);
        // if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!

        // building the menu
        this.menu = new Gtk.Menu ();

        var label = DesktopFolder.Lang.ITEM_MENU_OPEN;
        if (this.manager.is_executable ()) {
            label = DesktopFolder.Lang.ITEM_MENU_EXECUTE;
        }

        Gtk.MenuItem item = new Gtk.MenuItem.with_label (label);
        item.activate.connect ((item) => {
            this.manager.execute ();
        });

        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_OPEN_WITH);
        string path = this.manager.get_absolute_path ();
        item.activate.connect ((item) => { this.manager.openwith (path); });
        item.show ();
        menu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_CUT);
        item.activate.connect ((item) => { this.manager.cut (); });
        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_COPY);
        item.activate.connect ((item) => { this.manager.copy (); });
        item.show ();
        menu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_RENAME);
        item.activate.connect ((item) => { this.label.start_editing (); });
        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_TRASH);
        item.activate.connect ((item) => { this.manager.trash_selected (); });
        item.show ();
        menu.append (item);

        // if (this.manager.is_executable ()) { //only allowing this to executable files
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_MENU_CHANGEICON);
        item.activate.connect ((item) => { this.change_icon (); });
        item.show ();
        menu.append (item);
        // }

        item = new MenuItemSeparator ();
        item.show ();
        menu.append (item);

        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_FILEINFO);
        string info_path = this.manager.get_absolute_path ();
        item.activate.connect ((item) => { this.manager.show_info (info_path); });
        item.show ();
        menu.append (item);

        // only add open-folder-in-terminal to menu if the item is a folder
        if (this.manager.is_folder ()) {
            item = new MenuItemSeparator ();
            item.show ();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_OPEN_IN_TERMINAL);
            item.activate.connect ((item) => { this.manager.open_in_terminal (path); });
            item.show ();
            menu.append (item);
        }

        menu.show_all ();
        // }

        // showing the menu
        menu.popup_at_pointer (null);
    }

    /**
     * @name cut
     * @description cut the file to the clipboard
     */
    public void cut () {
        this.manager.cut ();
    }

    /**
     * @name copy
     * @description copy the file to the clipboard
     */
    public void copy () {
        this.manager.copy ();
    }

    /**
     * @name copy
     * @description copy the file to the clipboard
     */
    public void trash () {
        this.manager.trash ();
    }

    /**
     * @name delete_dialog
     * @description the user wants to delete the item. It should be confirmed before the deletion occurs
     */
    public void delete_dialog () {
        string     message = DesktopFolder.Lang.ITEM_DELETE_FOLDER_MESSAGE;
        Gtk.Window window  = (Gtk.Window) this.get_toplevel ();
        bool       isdir   = this.manager.is_folder ();
        if (!isdir) {
            message = DesktopFolder.Lang.ITEM_DELETE_FILE_MESSAGE;
        }
        if (this.manager.is_link ()) {
            message = DesktopFolder.Lang.ITEM_DELETE_LINK_MESSAGE;
        }

        Gtk.MessageDialog msg = new Gtk.MessageDialog (window, Gtk.DialogFlags.MODAL,
                Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, message);
        msg.use_markup = true;
        msg.response.connect ((response_id) => {
            switch (response_id) {
            case Gtk.ResponseType.OK:
                msg.destroy ();
                if (isdir) {
                    this.manager.trash ();
                    break;
                } else {
                    this.manager.trash ();
                }
                break;
            default:
                msg.destroy ();
                break;
                // uff
            }
        });
        msg.show ();
    }

    /**
     * @name change_icon
     * @description change the icon of an executable item
     */
    private void change_icon () {
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            DesktopFolder.Lang.ITEM_CHANGEICON_MESSAGE, this.manager.get_application_window (),
            Gtk.FileChooserAction.OPEN,
            DesktopFolder.Lang.DIALOG_CANCEL,
            Gtk.ResponseType.CANCEL,
            DesktopFolder.Lang.DIALOG_SELECT,
            Gtk.ResponseType.ACCEPT);

        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.set_name ("Images");
        filter.add_mime_type ("image");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/gif");
        filter.add_mime_type ("image/svg+xml");
        filter.add_pattern ("*.png");
        filter.add_pattern ("*.jpg");
        filter.add_pattern ("*.svg");
        filter.add_pattern ("*.gif");
        filter.add_pattern ("*.tif");
        filter.add_pattern ("*.xpm");
        chooser.add_filter (filter);

        // Process response:
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var filename = chooser.get_filename ();
            this.manager.change_icon (filename);
        }
        chooser.close ();
    }

    /**
     * @name modify
     * @description raise the flat modify
     */
    public void modify () {
        this.flagModified = true;
    }

    public Gdk.Rectangle get_bounding_box () {
        Gtk.Allocation allocation;
        this.get_allocation (out allocation);
        allocation.y = allocation.y + PADDING_Y; // damn magic numbers!
        allocation.x = allocation.x + PADDING_X; // damn magic numbers!
        return allocation;
    }

    /**
     * @name on_motion
     * @description the on_motion event captured to allow the movement of the icon
     * @param EventMotion event @see the on_motion signal
     * @return bool @see the on_motion signal
     */
    private bool on_motion (Gdk.EventMotion event) {
        if (!this.manager.get_folder ().are_items_locked () && this.manager.get_folder ().get_arrangement ().can_drag ()) {

            // To prevent moving the itemView when editing the label
            if (this.label.editing) {
                // debug("ItemView has the focus but is editing the label");
                return false;
            }
            var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
            bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
            if (control_pressed) {
                return false;
            }

            // debug("on_motion");
            this.flagModified = true;

            if (!this.flagMoved) {
                // we notify that we are starting to move
                this.manager.get_folder ().get_view ().on_item_moving (true);
                this.flagMoved = true;
            }

            // x_root,x_root relative to screen
            // x,y relative to parent (fixed widget)
            // px,py stores previous values of x,y

            // get starting values for x,y
            int x = (int) event.x_root - this.offsetx;
            int y = (int) event.y_root - this.offsety;


            // debug("motion: %d,%d",(int) event.x_root,(int) event.y_root);
            // debug("offset_motion: %d,%d",this.offsetx,this.offsety);


            // removing parent absolute position due to scroll
            // if (!(this.manager.get_folder ().get_view () is DesktopWindow)) {
            FolderSettings folder_settings = this.manager.get_folder ().get_settings ();
            x = x - folder_settings.x + DesktopFolder.WINDOW_DECORATION_MARGIN;
            y = y - folder_settings.y + DesktopFolder.WINDOW_DECORATION_MARGIN;
            // }


            Gdk.Rectangle icon_rectangle = Gdk.Rectangle ();
            int           qwidth         = DesktopFolder.ICON_DEFAULT_WIDTH / 2;
            icon_rectangle.x      = x + qwidth;
            icon_rectangle.y      = y + qwidth;
            icon_rectangle.width  = DesktopFolder.ICON_DEFAULT_WIDTH - qwidth;
            icon_rectangle.height = DesktopFolder.ICON_DEFAULT_WIDTH - qwidth;
            Gee.List <ItemManager> ims = this.manager.get_folder ().get_items_at (icon_rectangle);
            for (int i = 0; i < ims.size; i++) {
                ItemManager im = ims.@get (i);
                // if(im!=null){
                // debug("im is folder? %s",(im.is_folder()?"true":"false"));
                // }
                if (im != null && im != this.manager && im.is_folder () && !im.is_selected ()) {
                    this.cancel_movement_and_start_drag_action (event);
                    break;
                }
            }

            // debug("-------------");
            // debug ("offset(%d,%d)", this.offsetx, this.offsety);
            // debug ("event-xy(%f, %f)", event.x, event.y);
            // debug ("root(%f, %f)", event.x_root, event.y_root);
            // debug ("x,y=(%d,%d)", x, y);

            // make sure the potential coordinates x,y:
            // 1) will not push any part of the widget outside of its parent container
            // 2) is a multiple of Sensitivity
            // x           = RoundToNearestMultiple (int.max (int.min (x, this.maxx), 0), FreeArrangement.SENSITIVITY_WITHOUT_GRID);
            // y           = RoundToNearestMultiple (int.max (int.min (y, this.maxy), 0), FreeArrangement.SENSITIVITY_WITHOUT_GRID);
            if (x != this.px || y != this.py) {
                this.px = x;
                this.py = y;

                Gtk.Allocation allocation0;
                this.get_allocation (out allocation0);
                FolderWindow window = this.manager.get_folder ().get_view ();
                window.move_item (this, x + PADDING_X, y);
                int diff_x          = allocation0.x - (x + PADDING_X);
                int diff_y          = allocation0.y - y;

                // now, moving the rest of selected items to replicate the main movement
                Gee.List <ItemView> selecteds = this.manager.get_folder ().get_selected_items ();
                for (int i = 0; i < selecteds.size; i++) {
                    ItemView selected = selecteds.@get (i);
                    if (selected != this) {
                        Gtk.Allocation allocation;
                        selected.get_allocation (out allocation);
                        window.move_item (selected, allocation.x - diff_x, allocation.y - diff_y);
                    }
                }

                // debug("moving to: %d,%d",x+PADDING_X,y);

                // notifying to the arrangement
                this.manager.get_folder ().get_arrangement ().motion_drag (x + PADDING_X, y);
            }

            return true;
        } else {
            return false;
        }
    }

    /**
     * @name RoundDownToMultiple
     * @description util function for the movement of icons
     */
    inline static int RoundDownToMultiple (int i, int m) {
        return i / m * m;
    }

    /**
     * @name RoundToNearestMultiple
     * @description util function for the movement of icons
     */
    public static int RoundToNearestMultiple (int i, int m) {
        if (i % m > (double) m / 2.0d)
            return (i / m + 1) * m;
        return i / m * m;
    }

}
