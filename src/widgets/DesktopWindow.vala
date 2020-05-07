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
public class DesktopFolder.DesktopWindow : DesktopFolder.FolderWindow {

    /**
     * @constructor
     * @param FolderManager manager the manager of this window
     */
    public DesktopWindow (FolderManager manager) {
        base (manager);
        this.scroll.get_vscrollbar ().visible = false;
        this.scroll.get_hscrollbar ().visible = false;
    }

    /**
     * @name on_enter_notify
     * @description On mouse entering the window
     */
    protected override bool on_enter_notify (Gdk.EventCrossing event) {
        // debug("DESKTOP enter notify");
        return true;
    }

    protected override bool on_press (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
            debug ("toggling desktop visiblity");
            base.get_manager ().get_application ().toggle_desktop_visibility ();
        }
        base.on_press (event);
        return true;
    }

    /**
     * @name move_to
     * @description move the window to other position
     */
    protected override void move_to (int x, int y) {
        // we cannot move move the desktop window
    }

    /**
     * @name resize_to
     * @description resize the window to other position
     */
    protected override void resize_to (int width, int height) {
        // we cannot resize the desktop window
    }

    /**
     * @name on_enter_leave
     * @description On mouse leaving the window
     */
    protected override bool on_leave_notify (Gdk.EventCrossing event) {
        // debug("DESKTOP leave notify");
        return true;
    }

    /**
     * @overrided
     */
    public override void reload_settings () {
        base.reload_settings ();
        this.get_style_context ().remove_class ("df_fadeout");
        this.get_style_context ().add_class ("df_fadein");
        this.opacity = 1;
    }

    /**
     * @overrided
     */
    public override void refresh () {
        var app = this.manager.get_application ();
        if (app.get_desktop_visibility () && app.get_desktopicons_enabled ()) {
            debug ("refresh, icons enabled and desktop visibility = true");
            this.show_all ();
        } else {
            debug ("trying to hide");
            this.manager.hide_items ();
        }
    }

    /**
     * @overrided
     */
    protected override void create_headerbar () {
        this.set_titlebar (new Gtk.HeaderBar ());
    }

    /**
     * @overrided
     */
    protected override void show_popup (Gdk.EventButton event) {
        // debug("evento:%f,%f",event.x,event.y);
        // if(this.menu==null) { // we need the event coordinates for the menu, we need to recreate?!

        // Forcing desktop mode to avoid minimization in certain extreme cases without on_press signal!
        // TODO: Is there a way to make a desktop window resizable and movable?

        bool show_icon_options = this.manager.get_application ().get_desktoppanel_enabled () && this.manager.get_application ().get_desktopicons_enabled () && this.manager.get_application ().get_desktop_visibility ();

        this.type_hint    = Gdk.WindowTypeHint.DESKTOP;
        this.context_menu = new Gtk.Menu ();
        Clipboard.ClipboardManager cm = Clipboard.ClipboardManager.get_for_display ();

        // Creating items (please try and keep these in the same order as appended to the menu)
        var new_item                   = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_SUBMENU);

        var          new_submenu       = new Gtk.Menu ();
        var          newfolder_item    = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER);
        var          emptyfile_item    = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_EMPTY_FILE);
        var          newlink_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FILE_LINK);
        var          newlinkdir_item   = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER_LINK);
        var          newpanel_item     = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
        var          newlinkpanel_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LINK_PANEL);
        var          newnote_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
        var          newphoto_item     = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);
        var          properties_item   = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_PROPERTIES_TOOLTIP);
        var          desktop_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_CHANGEDESKTOP);
        Gtk.MenuItem show_desktop_item;
        if (this.manager.get_application ().get_desktop_visibility ()) {
            show_desktop_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_HIDE_DESKTOP);
        } else {
            show_desktop_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SHOW_DESKTOP);
        }
        var openterminal_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_OPENTERMINAL);

        // sortby submenu -----------
        var sortby_item          = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_BY);
        var sortby_submenu       = new Gtk.Menu ();
        var sortby_name_item     = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_BY_NAME);
        var sortby_size_item     = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_BY_SIZE);
        var sortby_type_item     = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_BY_TYPE);
        var sortby_reverse_item  = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_REVERSE);
        var sortby_vertical_item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_VERTICAL);
        var organize_item        = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_SORT_ORGANIZE);
        // ----------------------------

        var textcolor_item = new MenuItemColor (HEAD_TAGS_COLORS, null);

        // Events (please try and keep these in the same order as appended to the menu)
        if (show_icon_options) {
            newfolder_item.activate.connect (() => { this.new_folder ((int) event.x, (int) event.y); });
            emptyfile_item.activate.connect (() => { this.new_text_file ((int) event.x, (int) event.y); });
            newlink_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, false); });
            newlinkdir_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, true); });
        }
        newpanel_item.activate.connect (() => { this.new_desktop_folder ((int) event.x, (int) event.y); });
        newlinkpanel_item.activate.connect (() => { this.new_link_panel ((int) event.x, (int) event.y); });
        newnote_item.activate.connect (() => { this.new_note ((int) event.x, (int) event.y); });
        newphoto_item.activate.connect (() => { this.new_photo ((int) event.x, (int) event.y); });
        if (show_icon_options) {
            // sortby submenu ---------
            sortby_name_item.set_active (this.manager.get_settings ().sort_by_type == FolderSort.SORT_BY_NAME);
            sortby_size_item.set_active (this.manager.get_settings ().sort_by_type == FolderSort.SORT_BY_SIZE);
            sortby_type_item.set_active (this.manager.get_settings ().sort_by_type == FolderSort.SORT_BY_TYPE);
            sortby_reverse_item.set_active (this.manager.get_settings ().sort_reverse == true);
            sortby_vertical_item.set_active (this.manager.is_vertical_arragement ());
            sortby_name_item.toggled.connect ((item) => {
                this.on_sort_by (FolderSort.SORT_BY_NAME);
            });
            sortby_size_item.toggled.connect ((item) => {
                this.on_sort_by (FolderSort.SORT_BY_SIZE);
            });
            sortby_type_item.toggled.connect ((item) => {
                this.on_sort_by (FolderSort.SORT_BY_TYPE);
            });
            sortby_reverse_item.toggled.connect ((item) => {
                this.manager.get_settings ().sort_reverse = !this.manager.get_settings ().sort_reverse;
                this.manager.get_settings ().save ();
                this.manager.organize_panel_items ();
            });
            sortby_vertical_item.toggled.connect ((item) => {
                if (this.manager.is_vertical_arragement ()) {
                    this.manager.get_settings ().arrangement_orientation = FolderSettings.ARRANGEMENT_ORIENTATION_HORIZONTAL;
                } else {
                    this.manager.get_settings ().arrangement_orientation = FolderSettings.ARRANGEMENT_ORIENTATION_VERTICAL;
                }
                this.manager.get_settings ().save ();
                this.manager.organize_panel_items ();
            });
            organize_item.activate.connect (this.manager.organize_panel_items);

            // ------------------------

            ((MenuItemColor) textcolor_item).color_changed.connect (change_head_color);
        }

        ((Gtk.MenuItem)properties_item).activate.connect (this.show_properties_dialog);
        ((Gtk.MenuItem)desktop_item).activate.connect (this.show_desktop_dialog);

        ((Gtk.MenuItem)show_desktop_item).activate.connect (this.manager.get_application ().toggle_desktop_visibility);

        if (show_icon_options) {
            openterminal_item.activate.connect (this.open_terminal);

            // Appending (in order)
            if (cm.can_paste) {
                var paste_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_PASTE);
                paste_item.activate.connect (this.manager.paste);
                context_menu.append (paste_item);
                context_menu.append (new MenuItemSeparator ());
            }
        }
        context_menu.append (new_item);
        new_item.set_submenu (new_submenu);
        if (show_icon_options) {
            new_submenu.append (newfolder_item);
            new_submenu.append (emptyfile_item);
            new_submenu.append (new MenuItemSeparator ());
            new_submenu.append (newlink_item);
            new_submenu.append (newlinkdir_item);
            new_submenu.append (new MenuItemSeparator ());
        }
        new_submenu.append (newpanel_item);
        new_submenu.append (newlinkpanel_item);
        new_submenu.append (newnote_item);
        new_submenu.append (newphoto_item);
        context_menu.append (new MenuItemSeparator ());

        if (show_icon_options) {
            // sortby submenu ---------
            context_menu.append (sortby_item);
            sortby_item.set_submenu (sortby_submenu);
            sortby_submenu.append (sortby_name_item);
            sortby_submenu.append (sortby_size_item);
            sortby_submenu.append (sortby_type_item);
            sortby_submenu.append (new MenuItemSeparator ());
            sortby_submenu.append (sortby_reverse_item);
            sortby_submenu.append (sortby_vertical_item);
            if (this.manager.get_arrangement ().can_organize ()) {
                context_menu.append (organize_item);
            }
            context_menu.append (new MenuItemSeparator ());
        }
        context_menu.append (desktop_item);
        context_menu.append (show_desktop_item);
        context_menu.append (openterminal_item);

        if (show_icon_options) {
            context_menu.append (new MenuItemSeparator ());
            context_menu.append (properties_item);
            context_menu.append (textcolor_item);
        }

        context_menu.show_all ();
        context_menu.popup_at_pointer (null);
    }

    /**
     * @name show_desktop_dialog
     * @description show the desktop dialog
     */
    protected void show_desktop_dialog () {
        try {
            var current_desktop = GLib.Environment.get_variable ("XDG_CURRENT_DESKTOP");
            var command         = "";

            if (current_desktop == "Pantheon") {
                debug ("We are in pantheon...");
                command = "xdg-open settings://desktop";
            } else {
                command = "gnome-control-center background";
            }

            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);
        } catch (Error err) {
            // TODO
        }
    }

}
