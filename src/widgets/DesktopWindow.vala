/*
 * Copyright (c) 2017 José Amuedo (https://github.com/spheras)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
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
     * @name show_popup
     * @description build and show the popup menu
     * @param event EventButton the origin event, needed to position the menu
     */
    protected override void show_popup (Gdk.EventButton event) {
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
        Gtk.MenuItem item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER);
        item.activate.connect ((item) => {
                this.new_folder ((int) event.x, (int) event.y);
            });
        item.show ();
        newmenu.append (item);

        // menu to create a new empty file
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_EMPTY_FILE);
        item.activate.connect ((item) => {
                this.new_text_file ((int) event.x, (int) event.y);
            });
        item.show ();
        newmenu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        newmenu.append (item);

        // menu to create a new link file
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FILE_LINK);
        item.activate.connect ((item) => {
                this.new_link ((int) event.x, (int) event.y, false);
            });
        item.show ();
        newmenu.append (item);

        item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ALIGN_TO_GRID);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().align_to_grid);
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
                this.on_toggle_align_to_grid ();
            });
        item.show ();
        menu.append (item);

        item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_SHADOW);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().textshadow);
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
                this.on_toggle_shadow ();
            });
        item.show ();
        menu.append (item);

        item = new Gtk.CheckMenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_BOLD);
        (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings ().textbold);
        (item as Gtk.CheckMenuItem).toggled.connect ((item) => {
                this.on_toggle_bold ();
            });
        item.show ();
        menu.append (item);

        // menu to create a new link folder
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_FOLDER_LINK);
        item.activate.connect ((item) => {
                this.new_link ((int) event.x, (int) event.y, true);
            });
        item.show ();
        newmenu.append (item);

        item = new MenuItemSeparator ();
        item.show ();
        newmenu.append (item);

        // menu to create a new panel
        item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
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

        // If the paste is available, a paste option
        Clipboard.ClipboardManager cm = Clipboard.ClipboardManager.get_for_display ();
        if (cm.can_paste) {

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_PASTE);
            item.activate.connect ((item) => { this.manager.paste (); });
            item.show ();
            menu.append (item);

            item = new MenuItemSeparator ();
            item.show ();
            menu.append (item);
        }

        menu.show_all ();

        // }

        // finally we show the popup
        menu.popup (
            null // parent menu shell
            , null // parent menu item
            , null // func
            , event.button // button
            , event.get_time () // Gtk.get_current_event_time() //time
        );
    }

}
