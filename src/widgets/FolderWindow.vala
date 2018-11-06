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
public class DesktopFolder.FolderWindow : Gtk.ApplicationWindow {
    protected FolderManager manager           = null;
    protected Gtk.Fixed container             = null;
    protected Gtk.Menu context_menu           = null;
    protected bool flag_moving                = false;
    private Gtk.Button trash_button           = null;
    private DesktopFolder.EditableLabel label = null;
    protected Gtk.Button properties_button    = null;

    /** item alignment*/
    protected const int SENSITIVITY_WITH_GRID    = 100;
    protected const int SENSITIVITY_WITHOUT_GRID = 4;
    // TODO: private int _sensitivity {public get;public set; default=SENSITIVITY_WITHOUT_GRID;}
    protected int sensitivity                      = SENSITIVITY_WITHOUT_GRID;

    public const string HEAD_TAGS_COLORS[3]        = { null, "#ffffff", "#000000" };
    public const string HEAD_TAGS_COLORS_CLASS[3]  = { "df_headless", "df_light", "df_dark" };

    public const string BODY_TAGS_COLORS[10]       = { null, "#ffe16b", "#ffa154", "#795548", "#9bdb4d", "#64baff", "#ad65d6", "#ed5353", "#d4d4d4", "#000000" };
    public const string BODY_TAGS_COLORS_CLASS[10] = { "df_transparent", "df_yellow", "df_orange", "df_brown", "df_green", "df_blue", "df_purple", "df_red", "df_gray", "df_black" };
    protected string last_custom_color             = "#FF0000";
    private Gtk.CssProvider custom_color_provider  = new Gtk.CssProvider ();

    /** flag to know if the window was painted /packed already */
    private bool flag_realized = false;


    // this is the link image loaded
    static Gdk.Pixbuf LINK_PIXBUF = null;
    static construct {
        try {
            int scale = DesktopFolder.ICON_SIZE / 3;
            FolderWindow.LINK_PIXBUF = new Gdk.Pixbuf.from_resource ("/com/github/spheras/desktopfolder/link.svg");
            FolderWindow.LINK_PIXBUF = FolderWindow.LINK_PIXBUF.scale_simple (scale, scale, Gdk.InterpType.BILINEAR);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    construct {
        set_keep_below (true);
        this.hide_titlebar_when_maximized = false;
        set_type_hint (Gdk.WindowTypeHint.DESKTOP);

        set_skip_taskbar_hint (true);
        this.set_property ("skip-taskbar-hint", true);
        this.set_property ("skip-pager-hint", true);
        this.set_property ("skip_taskbar_hint", true);
        this.set_property ("skip_pager_hint", true);
        this.skip_pager_hint   = true;
        this.skip_taskbar_hint = true;

        stick ();
    }

    /**
     * @constructor
     * @param FolderManager manager the manager of this window
     */
    public FolderWindow (FolderManager manager) {
        Object (
            application:        manager.get_application (),
            icon_name:          "com.github.spheras.desktopfolder",
            resizable:          true,
            accept_focus:       true,
            skip_taskbar_hint:  true,
            skip_pager_hint:    true,
            decorated:          true,
            title:              (manager.get_folder_name ()),
            type_hint:          Gdk.WindowTypeHint.DESKTOP,
            deletable:          false,
            default_width:      300,
            default_height:     300,
            height_request:     50,
            width_request:      50
        );
        this.manager = manager;

        DesktopManager desktop_manager = manager.get_application ().get_fake_desktop ();
        if (desktop_manager != null) {
            this.set_transient_for (desktop_manager.get_view ());
        }

        this.name                      = manager.get_application ().get_next_id ();
        this.trash_button              = new Gtk.Button.from_icon_name ("edit-delete-symbolic");
        this.trash_button.has_tooltip  = true;
        this.trash_button.tooltip_text = DesktopFolder.Lang.DESKTOPFOLDER_DELETE_TOOLTIP;
        this.trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button");
        this.trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        this.trash_button.enter_notify_event.connect (() => {
            this.trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hover");
            return true;
        });
        this.trash_button.leave_notify_event.connect (() => {
            this.trash_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hover");
            return true;
        });

        this.properties_button              = new Gtk.Button.from_icon_name ("open-menu-symbolic");
        this.properties_button.has_tooltip  = true;
        this.properties_button.tooltip_text = DesktopFolder.Lang.DESKTOPFOLDER_PROPERTIES_TOOLTIP;
        this.properties_button.get_image ().get_style_context ().add_class ("df_titlebar_button");
        this.properties_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        this.properties_button.enter_notify_event.connect (() => {
            this.properties_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hover");
            return true;
        });
        this.properties_button.leave_notify_event.connect (() => {
            this.properties_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hover");
            return true;
        });

        create_headerbar ();

        // To avoid showing in the taskbar
        this.set_skip_taskbar_hint (true);
        skip_pager_hint   = true;
        skip_taskbar_hint = true;
        this.set_property ("skip-taskbar-hint", true);

        this.container = new Gtk.Fixed ();
        add (this.container);

        // important to load settings 2 times, now and after realized event
        this.reload_settings ();
        this.realize.connect (() => {
            if (!this.flag_realized) {
                this.flag_realized = true;
                // we need to reload settings to ensure that it get the real sizes and positiions
                this.reload_settings ();
            }
        });

        this.configure_event.connect (this.on_configure);
        this.button_press_event.connect (this.on_press);
        this.button_release_event.connect (this.on_release);
        this.key_release_event.connect (this.on_key);
        this.key_press_event.connect (this.on_key);
        this.draw.connect (this.draw_background);
        this.enter_notify_event.connect (this.on_enter_notify);
        this.leave_notify_event.connect (this.on_leave_notify);

        // Warning! we need to connect with the press_event, instead of release or clicked to avoid problems
        trash_button.button_press_event.connect ((event) => {
            this.manager.trash ();
            return true;
        });
        properties_button.button_press_event.connect ((event) => {
            this.show_properties_dialog ();
            return true;
        });

        // TODO: Does the GTK window have any active signal or css :active state?
        Wnck.Screen screen = Wnck.Screen.get_default ();
        screen.active_window_changed.connect (on_active_change);


        // TODO this.dnd_behaviour=new DragnDrop.DndBehaviour(this,false, true);
    }

    /**
     * @name show_properties_dialog
     * @description show the properties dialog
     */
    protected void show_properties_dialog () {
        var dialog = new DesktopFolder.Dialogs.PanelProperties (this);
        dialog.set_transient_for (this);
        dialog.show_all ();
    }

    /**
     * @name create_headerbar
     * @description create the header bar
     */
    protected virtual void create_headerbar () {
        // debug("Create headerbar for %s",this.manager.get_folder_name ());

        var header = new Gtk.HeaderBar ();
        header.button_press_event.connect (() => {
            // to avoid moving the window if it is forbidden
            return !this.manager.can_move ();
        });
        header.height_request = DesktopFolder.HEADERBAR_HEIGHT;
        header.set_decoration_layout ("");
        this.label            = new DesktopFolder.EditableLabel (manager.get_folder_name ());
        this.label.set_margin (10);
        this.label.show_popup.connect (this.on_press);
        this.label.get_style_context ().add_class ("title");
        // header.set_custom_title (label);
        header.pack_start (trash_button);
        header.set_custom_title (label);
        header.pack_end (properties_button);

        this.set_titlebar (header);

        label.changed.connect ((new_name) => {
            if (this.manager.rename (new_name)) {
                label.text = new_name;
            }
        });
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
        FolderSettings settings = this.manager.get_settings ();
        if (settings.w > 0) {
            // applying existing position and size configuration
            this.resize_to (settings.w, settings.h);
            this.move_to (settings.x, settings.y);
            // debug ("Moving '%s' to (%d,%d), Resizing to (%d,%d)", this.manager.get_folder_name (), settings.x, settings.y, settings.w, settings.h);
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

        // applying existing colors configuration
        if (settings.bgcolor.has_prefix ("rgb")) {
            string custom = settings.bgcolor;
            this.set_custom_color (custom);
        } else {
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (this.get_color_for_class (settings.bgcolor));
            rgba.alpha             = 0.35;
            this.last_custom_color = rgba.to_string ();
            this.get_style_context ().add_class (settings.bgcolor);
        }
        this.get_style_context ().add_class (settings.fgcolor);

        if (this.manager.get_settings ().textshadow) {
            this.get_style_context ().add_class ("df_shadow");
        }
        if (this.manager.get_settings ().textbold) {
            this.get_style_context ().add_class ("df_bold");
        }

        this.set_title (manager.get_folder_name ());

        if (this.manager.get_settings ().align_to_grid) {
            this.sensitivity = SENSITIVITY_WITH_GRID;
        } else {
            this.sensitivity = SENSITIVITY_WITHOUT_GRID;
        }
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
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), this.custom_color_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        this.last_custom_color = mycustom;

        return mycustom;
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
     * @name on_active_change
     * @description the screen actived window has change signal
     * @param {Wnck.Window} the previous actived window
     */
    private void on_active_change (Wnck.Window ? previous) {
        string           sclass = "df_active";
        Gtk.StyleContext style  = this.get_style_context ();
        // debug("%s is active? %s",this.manager.get_folder_name(), this.is_active ? "true" : "false");
        if (this.is_active) {
            this.manager.on_active ();
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
    }

    /**
     * @name refresh
     * @description refresh the window
     */
    public void refresh () {
        this.show_all ();
    }

    /**
     * @name on_configure
     * @description the configure event is produced when the window change its dimensions or location settings
     */
    private bool on_configure (Gdk.EventConfigure event) {
        // it seems:
        // - the window.height is this.allocation.height + decoration.margin.height * 2 + header.height
        // - the window.width is the allocation.width + decoration.margin.width * 2
        if (!this.flag_realized) {
            // we discard all the pre realized configure events
            return false;
        }

        debug ("---------------------------------------------------------");
        debug ("event configure: type:%d,se:%d,w:%d,h:%d,x:%d,y:%d", event.type, event.send_event, event.width, event.height, event.x, event.y);
        if (event.type == Gdk.EventType.CONFIGURE) {
            // This is to avoid minimization when Show Desktop shortcut is used
            // TODO: Is there a way to make a desktop window resizable and movable?
            this.type_hint = Gdk.WindowTypeHint.DESKTOP; // Going to try DIALOG at some point

            int x = event.x + DesktopFolder.WINDOW_DECORATION_MARGIN;
            int y = event.y + DesktopFolder.WINDOW_DECORATION_MARGIN;
            int w = event.width - (DesktopFolder.WINDOW_DECORATION_MARGIN * 2);
            int h = event.height - (DesktopFolder.WINDOW_DECORATION_MARGIN * 2);
            debug ("set_new_shape: %i,%i,%i,%i", x, y, w, h);
            this.manager.set_new_shape (x, y, w, h);
        }
        return false;
    }

    /**
     * @name on_enter_notify
     * @description On mouse entering the window
     */
    protected virtual bool on_enter_notify (Gdk.EventCrossing event) {
        // debug("FOLDERWINDOW '%s' ENTER notify",this.manager.get_folder_name());
        trash_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hidden");
        properties_button.get_image ().get_style_context ().remove_class ("df_titlebar_button_hidden");
        return false;
    }

    /**
     * @name on_enter_leave
     * @description On mouse leaving the window
     */
    protected virtual bool on_leave_notify (Gdk.EventCrossing event) {
        if (event.detail == Gdk.NotifyType.ANCESTOR || event.detail == Gdk.NotifyType.VIRTUAL || event.detail == Gdk.NotifyType.INFERIOR) {
            return false;
        }
        // debug("FOLDERWINDOW '%s' LEAVE notify",this.manager.get_folder_name());
        trash_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        properties_button.get_image ().get_style_context ().add_class ("df_titlebar_button_hidden");
        return false;
    }

    /**
     * @name on_release
     * @description release event captured.
     * @return bool @see widget on_release signal
     */
    private bool on_release (Gdk.EventButton event) {
        // This is to avoid minimization when Show Desktop shortcut is used
        // TODO: Is there a way to make a desktop window resizable and movable?
        this.type_hint = Gdk.WindowTypeHint.DESKTOP;
        return false;
    }

    /**
     * @name on_press
     * @description press event captured. The Window should show the popup on right button
     * @return bool @see widget on_press signal
     */
    private bool on_press (Gdk.EventButton event) {
        // debug("on_press folderwindow");
        // Needed to exit focus from title when editting
        this.activate_focus ();

        // this code is to allow the drag'ndrop of files inside the folder window
        var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button == Gdk.BUTTON_PRIMARY && control_pressed) {
            return false;
        }


        // This is to allow moving and resizing the panel
        // TODO: Is there a way to make a desktop window resizable and movable?
        this.type_hint = Gdk.WindowTypeHint.NORMAL; // Going to try DIALOG at some point to make below obsolete

        // debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button == Gdk.BUTTON_SECONDARY)) {
            this.show_popup (event);
            return true;
            // Remove below later if hiding behind Wingpanel is properly fixed (required for drag boxes)
        } else if (event.type == Gdk.EventType.BUTTON_PRESS && (event.button == Gdk.BUTTON_PRIMARY)) {
            this.unselect_all ();

            if (this.manager.can_move ()) {
                // int width  = this.get_allocated_width ();
                // int height = this.get_allocated_height ();
                // debug("x:%d,y:%d,width:%d,height:%d",(int)event.x,(int) event.y,width,height);
                // some tricks to allow resizing from border
                if (event.x > 11 && event.y > 11) {
                    // the corner need some extra space
                    if (!(event.x < 31 && event.y < 31)) {
                        this.begin_move_drag ((int) event.button, (int) event.x_root, (int) event.y_root, event.time);
                    }
                }
            }
        }
        return false;
    }

    /**
     * @name show_popup
     * @description build and show the popup menu
     * @param event EventButton the origin event, needed to position the menu
     */
    protected virtual void show_popup (Gdk.EventButton event) {
        // debug("evento:%f,%f",event.x,event.y);
        // if(this.menu==null) { // we need the event coordinates for the menu, we need to recreate?!

        // Forcing desktop mode to avoid minimization in certain extreme cases without on_press signal!
        // TODO: Is there a way to make a desktop window resizable and movable?

        this.type_hint    = Gdk.WindowTypeHint.DESKTOP;
        this.context_menu = new Gtk.Menu ();
        Clipboard.ClipboardManager cm = Clipboard.ClipboardManager.get_for_display ();

        // Creating items (please try and keep these in the same order as appended to the menu)
        var new_item          = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_SUBMENU);

        var new_submenu       = new Gtk.Menu ();
        var newfolder_item    = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER);
        var emptyfile_item    = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_EMPTY_FILE);
        var newlink_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FILE_LINK);
        var newlinkdir_item   = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER_LINK);
        var newpanel_item     = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
        var newlinkpanel_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LINK_PANEL);
        var newnote_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
        var newphoto_item     = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);

        // var aligntogrid_item     = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ALIGN_TO_GRID);
        var trash_item  = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_REMOVE_DESKTOP_FOLDER);
        var rename_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_RENAME_DESKTOP_FOLDER);
        // var lockitems_item       = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_ITEMS);
        // var textshadow_item      = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_SHADOW);
        // var textbold_item        = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_BOLD);
        var textcolor_item       = new MenuItemColor (HEAD_TAGS_COLORS, this, null);
        var backgroundcolor_item = new MenuItemColor (BODY_TAGS_COLORS, this, this.last_custom_color);

        // Events (please try and keep these in the same order as appended to the menu)
        newfolder_item.activate.connect (() => { this.new_folder ((int) event.x, (int) event.y); });
        emptyfile_item.activate.connect (() => { this.new_text_file ((int) event.x, (int) event.y); });
        newlink_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, false); });
        newlinkdir_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, true); });
        newpanel_item.activate.connect (this.new_desktop_folder);
        newlinkpanel_item.activate.connect (this.new_link_panel);
        newnote_item.activate.connect (this.new_note);
        newphoto_item.activate.connect (this.new_photo);

        // ((Gtk.CheckMenuItem)aligntogrid_item).set_active (this.manager.get_settings ().align_to_grid);
        // ((Gtk.CheckMenuItem)aligntogrid_item).toggled.connect (this.on_toggle_align_to_grid);
        trash_item.activate.connect (this.manager.trash);
        rename_item.activate.connect (this.label.start_editing);
        ///((Gtk.CheckMenuItem)lockitems_item).set_active (this.manager.get_settings ().lockitems);
        // ((Gtk.CheckMenuItem)lockitems_item).toggled.connect (this.on_toggle_lockitems);
        // ((Gtk.CheckMenuItem)textshadow_item).set_active (this.manager.get_settings ().textshadow);
        // ((Gtk.CheckMenuItem)textshadow_item).toggled.connect (this.on_toggle_shadow);
        // ((Gtk.CheckMenuItem)textbold_item).set_active (this.manager.get_settings ().textbold);
        // ((Gtk.CheckMenuItem)textbold_item).toggled.connect (this.on_toggle_bold);
        ((MenuItemColor) textcolor_item).color_changed.connect (change_head_color);
        ((MenuItemColor) backgroundcolor_item).color_changed.connect (change_body_color);
        ((MenuItemColor) backgroundcolor_item).custom_changed.connect (change_body_color_custom);

        // Appending (in order)
        if (cm.can_paste) {
            var paste_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_PASTE);
            paste_item.activate.connect (this.manager.paste);
            context_menu.append (paste_item);
            context_menu.append (new MenuItemSeparator ());
        }
        context_menu.append (new_item);
        new_item.set_submenu (new_submenu);

        new_submenu.append (newfolder_item);
        new_submenu.append (emptyfile_item);
        new_submenu.append (new MenuItemSeparator ());
        new_submenu.append (newlink_item);
        new_submenu.append (newlinkdir_item);
        new_submenu.append (new MenuItemSeparator ());
        new_submenu.append (newpanel_item);
        new_submenu.append (newlinkpanel_item);
        new_submenu.append (newnote_item);
        new_submenu.append (newphoto_item);

        // context_menu.append (new MenuItemSeparator ());
        // context_menu.append (aligntogrid_item);
        context_menu.append (new MenuItemSeparator ());
        context_menu.append (trash_item);
        // context_menu.append (new MenuItemSeparator ());
        context_menu.append (rename_item);
        // context_menu.append (new MenuItemSeparator ());
        // context_menu.append (lockitems_item);
        // context_menu.append (textshadow_item);
        // context_menu.append (textbold_item);
        context_menu.append (new MenuItemSeparator ());
        context_menu.append (textcolor_item);
        context_menu.append (backgroundcolor_item);

        context_menu.show_all ();

        context_menu.popup_at_pointer (null);
    }

    /**
     * @name on_toggle_bold
     * @description the bold toggle event. the text bold property must change
     */
    public void on_toggle_bold () {
        Gtk.StyleContext style      = this.get_style_context ();
        string           bold_class = "df_bold";
        if (this.manager.get_settings ().textbold) {
            style.remove_class (bold_class);
            this.manager.get_settings ().textbold = false;
        } else {
            style.add_class (bold_class);
            this.manager.get_settings ().textbold = true;
        }
        this.manager.get_settings ().save ();
        // List <weak Gtk.Widget> children = this.container.get_children ();
        // foreach (Gtk.Widget elem in children) {
        // (elem as ItemView).force_adjust_label ();
        // }
    }

    /**
     * @name on_toggle_align_to_grid
     * @description the toggle align to grid event. The align to grid property must change
     */
    public void on_toggle_align_to_grid () {
        if (this.get_sensitivity () == SENSITIVITY_WITH_GRID) {
            this.set_sensitivity (SENSITIVITY_WITHOUT_GRID);
            this.manager.get_settings ().align_to_grid = false;
        } else {
            this.set_sensitivity (SENSITIVITY_WITH_GRID);
            this.manager.get_settings ().align_to_grid = true;
        }
        this.manager.get_settings ().save ();
        this.clear_all ();
        this.manager.sync_files (0, 0);
    }

    /**
     * @name on_toggle_shadow
     * @description the toggle shadow event. The shadow property must change
     */
    public void on_toggle_shadow () {
        Gtk.StyleContext style        = this.get_style_context ();
        string           shadow_class = "df_shadow";
        if (this.manager.get_settings ().textshadow) {
            style.remove_class (shadow_class);
            this.manager.get_settings ().textshadow = false;
        } else {
            style.add_class (shadow_class);
            this.manager.get_settings ().textshadow = true;
        }
        this.manager.get_settings ().save ();
        // List <weak Gtk.Widget> children = this.container.get_children ();
        // foreach (Gtk.Widget elem in children) {
        // (elem as ItemView).force_adjust_label ();
        // }
    }

    /**
     * @name on_toggle_lockitems
     * @description the toggle lock items event. The lock items property must change
     */
    public void on_toggle_lockitems () {
        this.manager.get_settings ().lockitems = !this.manager.get_settings ().lockitems;
        this.manager.get_settings ().save ();
    }

    /**
     * @name on_toggle_lockpanel
     * @description the toggle lock panel event. The lock panel property must change
     */
    public void on_toggle_lockpanel () {
        this.manager.get_settings ().lockpanel = !this.manager.get_settings ().lockpanel;
        this.manager.get_settings ().save ();
    }

    /**
     * @name change_head_color
     * @description change event captured from the popup for a new color to the head window
     * @param {int} ncolor the new color for the head window
     */
    protected void change_head_color (int ncolor) {
        string color = HEAD_TAGS_COLORS_CLASS[ncolor];
        for (int i = 0; i < HEAD_TAGS_COLORS_CLASS.length; i++) {
            string scolor = HEAD_TAGS_COLORS_CLASS[i];
            this.get_style_context ().remove_class (scolor);
        }
        this.get_style_context ().add_class (color);
        this.manager.save_head_color (color);
        // debug("color:%d,%s",ncolor,color);
    }

    /**
     * @name move_item
     * @description move an item inside this window to a certain position
     * @param {ItemView} item the item to be moved
     * @param {int} x the x position
     * @param {int} y the y position
     */
    public void move_item (ItemView item, int x, int y) {
        // debug("moved to:%d,%d",x,y);
        this.container.move (item, x, y);
    }

    /**
     * @name change_body_color
     * @description change event captured from the popup for a new color to the body window
     * @param {int} ncolor the new color for the body window
     */
    public void change_body_color (int ncolor) {
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
            rgba.alpha             = 0.35;
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
     * @name clear_all
     * @description clear all the items inside this folder window
     */
    public void clear_all () {
        // debug("clearing all items");
        var children = this.container.get_children ();
        foreach (Gtk.Widget element in children)
            this.container.remove (element);
    }

    /**
     * @name add_item
     * @description add an item icon to the container
     * @param ItemView item the item to be added
     * @param int x the x position where it should be placed
     * @param int y the y position where it should be placed
     */
    public void add_item (ItemView item, int x, int y) {
        // debug("initial position:%d,%d",x,y);
        x = ItemView.RoundToNearestMultiple (x, this.get_sensitivity ());
        y = ItemView.RoundToNearestMultiple (y, this.get_sensitivity ());
        int margin = ItemView.PADDING_X;
        this.container.put (item, x + margin, y);
    }

    /**
     * @name raise
     * @description bring to front the item
     * @param {ItemView}
     */
    public void raise (ItemView item, int x, int y) {
        this.container.remove (item);
        add_item (item, x, y);
    }

    /**
     * @name on_key
     * @description the key event captured for the window
     * @param EventKey event the event produced
     * @return bool @see the on_key signal
     */
    private bool on_key (Gdk.EventKey event) {
        // debug("FolderWindow on_key, event: %s",event.type == Gdk.EventType.KEY_RELEASE?"KEY_RELEASE":event.type == Gdk.EventType.KEY_PRESS?"KEY_PRESS":"OTRO");
        // If the uses is editing something on an entr
        if (this.get_focus () is Gtk.Entry) {
            // debug ("User is editing!");
            return false;
        }

        int key                   = (int) event.keyval;
        // debug("event key %d",key);
        const int DELETE_KEY      = 65535;
        const int F2_KEY          = 65471;
        const int ENTER_KEY       = 65293;
        const int ARROW_LEFT_KEY  = 65361;
        const int ARROW_UP_KEY    = 65362;
        const int ARROW_RIGHT_KEY = 65363;
        const int ARROW_DOWN_KEY  = 65364;

        var  mods                 = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed      = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);
        bool shift_pressed        = ((mods & Gdk.ModifierType.SHIFT_MASK) != 0);

        ItemView selected         = this.get_selected_item ();

        if (event.type == Gdk.EventType.KEY_RELEASE) {
            if (control_pressed) {
                if (key == 'c' || key == 'C') {
                    if (selected != null) {
                        selected.copy ();
                        return true;
                    }
                } else if (key == 'x' || key == 'X') {
                    if (selected != null) {
                        selected.cut ();
                        return true;
                    }
                } else if (key == 'v' || key == 'V') {
                    this.manager.paste ();
                }
            } else {
                if (key == DELETE_KEY) {
                    if (selected != null) {
                        if (shift_pressed) {
                            selected.delete_dialog ();
                        } else {
                            selected.trash ();
                        }
                        return true;
                    } else {
                        this.manager.trash ();
                    }
                } else if (key == F2_KEY) {
                    if (selected != null) {
                        selected.start_editing ();
                        return true;
                    } else {
                        this.label.start_editing ();
                    }
                } else if (key == ENTER_KEY) {
                    if (selected != null) {
                        selected.execute ();
                        return true;
                    }
                }
            }
        } else if (event.type == Gdk.EventType.KEY_PRESS) {
            if (key == ARROW_LEFT_KEY) {
                // left arrow pressed
                move_selected_to ((a, b) => {
                    return (b.y >= a.y && b.y <= (a.y + a.height)) || (a.y >= b.y && a.y <= (b.y + b.height));
                }, (a, b) => {
                    return a.x < b.x;
                });
            } else if (key == ARROW_UP_KEY) {
                // up arrow pressed
                move_selected_to ((a, b) => {
                    return (b.x >= a.x && b.x <= (a.x + a.width)) || (a.x >= b.x && a.x <= (b.x + b.width));
                }, (a, b) => {
                    return a.y < b.y;
                });
            } else if (key == ARROW_RIGHT_KEY) {
                // right arrow pressed
                move_selected_to ((a, b) => {
                    return (b.y >= a.y && b.y <= (a.y + a.height)) || (a.y >= b.y && a.y <= (b.y + b.height));
                }, (a, b) => {
                    return a.x > b.x;
                });
            } else if (key == ARROW_DOWN_KEY) {
                // down arrow pressed
                move_selected_to ((a, b) => {
                    return (b.x >= a.x && b.x <= (a.x + a.width)) || (a.x >= b.x && a.x <= (b.x + b.width));
                }, (a, b) => {
                    return a.y > b.y;
                });
            }
        }

        return false;
    }

    /**
     * @name CompareAllocations
     * @description Comparator of GtkAllocation objects to order the selection with the keyboard
     * @return {bool} if the a element is greater than the b element
     */
    private delegate bool CompareAllocations (Gtk.Allocation a, Gtk.Allocation b);

    /**
     * @name move_selected_to
     * @description select the next item following a direction
     * @param {CompareAllocations} same_axis a function to check that the next item is on the same axis than the previous one
     * @param {CompareAllocations} is_selectable a function to check that the next item is in the correct direction
     */
    private void move_selected_to (CompareAllocations same_axis, CompareAllocations is_selectable) {
        ItemView actual_item = this.get_selected_item ();
        if (actual_item == null) {
            actual_item = (ItemView) this.container.get_children ().nth_data (0);
            if (actual_item == null) {
                debug ("There is not widgets on the folder.");
                return;
            }
        }
        Gtk.Allocation actual_allocation;
        actual_item.get_allocation (out actual_allocation);
        ItemView       next_item        = null;
        Gtk.Allocation next_allocation  = actual_allocation;

        List <weak Gtk.Widget> children = this.container.get_children ();
        foreach (Gtk.Widget elem in children) {
            Gtk.Allocation elem_allocation;
            elem.get_allocation (out elem_allocation);
            if (same_axis (elem_allocation, actual_allocation) && is_selectable (elem_allocation, actual_allocation)) {
                if (next_item == null) {
                    // If this is the first element is selectable found
                    next_allocation = elem_allocation;
                    next_item       = (ItemView) elem;
                } else if (!is_selectable (elem_allocation, next_allocation)) {
                    // If it is nearer from the last found
                    next_allocation = elem_allocation;
                    next_item       = (ItemView) elem;
                }
            }
        }
        if (next_item != null) {
            next_item.select ();
        } else {
            debug ("There are no elements on this direction");
        }
    }

    /**
     * @name get_selected_item
     * @description return the selected item
     * @return ItemView return the selected item at the desktop folder, or null if none selected
     */
    private ItemView get_selected_item () {
        var children = this.container.get_children ();
        for (int i = 0; i < children.length (); i++) {
            ItemView element = (ItemView) children.nth_data (i);
            if (element.is_selected ()) {
                return element;
            }
        }
        return null as ItemView;
    }

    /**
     * @name new_desktop_folder
     * @description show a dialog to create a new desktop folder
     */
    protected void new_desktop_folder () {
        DesktopFolder.Util.create_new_desktop_folder (this);
    }

    /**
     * @name new_link_panel
     * @description show a dialog to create a new link panel
     */
    protected void new_link_panel () {
        DesktopFolder.Util.create_new_link_panel (this);
    }

    /*
     * @name new_note
     * @description show a dialog to create a new note
     */
    protected void new_note () {
        DesktopFolder.Util.create_new_note (this);
    }

    /**
     * @name new_photo
     * @description show a dialog to create a new photo
     */
    protected void new_photo () {
        DesktopFolder.Util.create_new_photo (this);
    }

    /**
     * @name new_folder
     * @description show a dialog to create a new folder
     * @param int x the x position where the new folder icon should be generated
     * @param int y the y position where the new folder icon should be generated
     */
    protected void new_folder (int x, int y) {
        RenameDialog dialog = new RenameDialog (this,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_TITLE,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_MESSAGE,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_NAME);
        dialog.on_rename.connect ((new_name) => {
            // creating the folder
            if (new_name != "") {
                this.manager.create_new_folder (new_name, x, y);
            }
        });
        dialog.show_all ();
    }

    /**
     * @name new_text_file
     * @description create a new text file item inside this folder
     * @param int x the x position where the new item should be placed
     * @param int y the y position where the new item should be placed
     */
    protected void new_text_file (int x, int y) {
        RenameDialog dialog = new RenameDialog (this,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_TITLE,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_MESSAGE,
                DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_NAME);
        dialog.on_rename.connect ((new_name) => {
            if (new_name != "") {
                this.manager.create_new_text_file (new_name, x, y);
            }
        });
        dialog.show_all ();
    }

    /**
     * @name new_link
     * @description create a new linnk item inside this folder
     * @param int x the x position where the new item should be placed
     * @param int y the y position where the new item should be placed
     * @param bool folder to indicate if we want to select a folder or a file
     */
    protected void new_link (int x, int y, bool folder) {
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            DesktopFolder.Lang.DESKTOPFOLDER_LINK_MESSAGE, this, Gtk.FileChooserAction.OPEN,
            DesktopFolder.Lang.DIALOG_CANCEL,
            Gtk.ResponseType.CANCEL,
            DesktopFolder.Lang.DIALOG_SELECT,
            Gtk.ResponseType.ACCEPT);

        if (folder) {
            chooser.set_action (Gtk.FileChooserAction.SELECT_FOLDER);
        }
        // Process response:
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var filename = chooser.get_filename ();
            debug ("file:%s", filename);
            this.manager.create_new_link (filename, x, y);
        }
        chooser.close ();
    }

    /**
     * @name unselect_all
     * @description unselect all the items inside this folder
     */
    public void unselect_all () {
        var children = this.container.get_children ();
        foreach (Gtk.Widget element in children) {
            ((ItemView) element).unselect ();
        }
    }

    /**
     * @name get_sensitivity
     * @description Get the value of sensitivity, used to calculate the alignment of the items
     */
    public int get_sensitivity () {
        return this.sensitivity;
    }

    /**
     * @name set_sensitivity
     * @description Set value to sensitivity, used to calculate the alignment of the items
     */
    public void set_sensitivity (int s) {
        this.sensitivity = s;
    }

    /**
     * @name on_item_moving
     * @description event capture of an item moving or stop moving
     * @param {bool} moving if the item started moving or stopped moving
     */
    public void on_item_moving (bool moving) {
        this.flag_moving = moving;
        this.queue_draw ();
    }

    /**
     * @name get_manager
     * @description return the FolderManager
     * @return {FolderManager}
     */
    public FolderManager get_manager () {
        return this.manager;
    }

    /**
     * @name draw_backgorund
     * @description draw the folder window background intercepting the draw signal
     * @param {Cairo.Context} cr the cairo context
     * @bool @see draw signal
     */
    private bool draw_background (Cairo.Context cr) {
// util code to draw the whole window background (which contains also the decoration and you can size it)
        // cr.rectangle(0,0,10000,10000);
        // cr.set_source_rgba (1, 1, 1, 0.2);
        // cr.fill();

        // we must show the grid if it is enabled and an item being moved
        if (flag_moving == true && this.manager.get_settings ().align_to_grid) {
            int width  = this.get_allocated_width ();
            int height = this.get_allocated_height ();

            cr.set_operator (Cairo.Operator.CLEAR);
            cr.paint ();
            cr.set_operator (Cairo.Operator.OVER);

            cr.rectangle (0, 40, width - 14, height - 54);
            cr.clip ();

            Gtk.Allocation title_allocation;
            this.get_titlebar ().get_allocation (out title_allocation);
            // debug("panel: width:%d height:%d",width,height);
            // debug("header: x:%d y:%d width:%d height:%d",title_allocation.x,title_allocation.y,title_allocation.width,title_allocation.height);

            int left_padding = title_allocation.x;
            int top_padding  = title_allocation.y;
            int header       = title_allocation.height + top_padding;
            int margin       = 10;
            int sensitivity  = SENSITIVITY_WITH_GRID - 10;
            cr.set_source_rgba (1, 1, 1, 0.2);

            for (int i = left_padding + DesktopFolder.ItemView.PADDING_X; i <= width - left_padding - sensitivity; i += sensitivity + margin) {
                // debug("-i: %d",i);
                for (int j = header; j <= height - sensitivity - top_padding; j += sensitivity + margin) {
                    // debug("|j: %d",j);
                    cr.rectangle (i, j, sensitivity, sensitivity);
                    cr.fill ();
                }
            }

            cr.reset_clip ();
        }

        base.draw (cr);

        // we must show the link icon for link panels
        if (this.manager.is_link ()) {
            try {
                int width  = this.get_allocated_width ();
                int height = this.get_allocated_height ();

                int scale  = DesktopFolder.ICON_SIZE / 3;
                var links  = Gdk.cairo_surface_create_from_pixbuf (FolderWindow.LINK_PIXBUF, 1, null);
                cr.set_source_surface (links, width - scale - 20, height - scale - 20);
                cr.paint_with_alpha (0.8);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
                Util.show_error_dialog ("Error", e.message);
            }
        }

        return true;
    }

}
