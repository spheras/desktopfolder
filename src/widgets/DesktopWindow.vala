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
    }

    /**
     * @name on_enter_notify
     * @description On mouse entering the window
     */
    protected override bool on_enter_notify (Gdk.EventCrossing event) {
        // debug("DESKTOP enter notify");
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
    protected override void create_headerbar () {
        this.set_titlebar (new Gtk.HeaderBar ());
    }

    protected override void show_popup (Gdk.EventButton event) {
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
        var properties_item   = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_PROPERTIES_TOOLTIP);
        var desktop_item      = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_CHANGEDESKTOP);
        var openterminal_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_OPENTERMINAL);

        // var aligntogrid_item  = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ALIGN_TO_GRID);
        // var lockitems_item    = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_ITEMS);
        // var textshadow_item   = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_SHADOW);
        // var textbold_item     = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_BOLD);
        var textcolor_item = new MenuItemColor (HEAD_TAGS_COLORS, this, null);

        // Events (please try and keep these in the same order as appended to the menu)
        newfolder_item.activate.connect (() => { this.new_folder ((int) event.x, (int) event.y); });
        emptyfile_item.activate.connect (() => { this.new_text_file ((int) event.x, (int) event.y); });
        newlink_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, false); });
        newlinkdir_item.activate.connect (() => { this.new_link ((int) event.x, (int) event.y, true); });
        newpanel_item.activate.connect (this.new_desktop_folder);
        newlinkpanel_item.activate.connect (this.new_link_panel);
        newnote_item.activate.connect (this.new_note);
        newphoto_item.activate.connect (this.new_photo);
        openterminal_item.activate.connect (this.open_terminal);

        // ((Gtk.CheckMenuItem)aligntogrid_item).set_active (this.manager.get_settings ().align_to_grid);
        // ((Gtk.CheckMenuItem)aligntogrid_item).toggled.connect (this.on_toggle_align_to_grid);
        // ((Gtk.CheckMenuItem)lockitems_item).set_active (this.manager.get_settings ().lockitems);
        // ((Gtk.CheckMenuItem)lockitems_item).toggled.connect (this.on_toggle_lockitems);
        // ((Gtk.CheckMenuItem)textshadow_item).set_active (this.manager.get_settings ().textshadow);
        // ((Gtk.CheckMenuItem)textshadow_item).toggled.connect (this.on_toggle_shadow);
        // ((Gtk.CheckMenuItem)textbold_item).set_active (this.manager.get_settings ().textbold);
        // ((Gtk.CheckMenuItem)textbold_item).toggled.connect (this.on_toggle_bold);
        ((MenuItemColor) textcolor_item).color_changed.connect (change_head_color);
        ((Gtk.MenuItem)properties_item).activate.connect (this.show_properties_dialog);
        ((Gtk.MenuItem)desktop_item).activate.connect (this.show_desktop_dialog);
        

        // Appending (in order)
        if (cm.can_paste) {
            var paste_item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_PASTE);
            paste_item.activate.connect (this.manager.paste);
            context_menu.append (new MenuItemSeparator ());
            context_menu.append (paste_item);
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
        // context_menu.append (new MenuItemSeparator ());
        // context_menu.append (lockitems_item);
        // context_menu.append (textshadow_item);
        // context_menu.append (textbold_item);
        // context_menu.append (new MenuItemSeparator ());
        context_menu.append (textcolor_item);
        context_menu.append (new MenuItemSeparator ());
        context_menu.append (properties_item);
        context_menu.append (desktop_item);
        context_menu.append (new MenuItemSeparator ());
        context_menu.append (openterminal_item);
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
