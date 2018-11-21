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

public errordomain FolderManagerIOError {
    FILE_EXISTS,
    MOVE_ERROR
}

/**
 * @class
 * Desktop Folder Manager
 */
public class DesktopFolder.FolderManager : Object, DragnDrop.DndView {
    /** parent application */
    private DesktopFolderApp application;
    /** to know if the panel is moveable or not */
    protected bool is_moveable                   = true;
    /** the view of this logic */
    protected FolderWindow view                  = null;
    /** Folder Settings of this folder */
    private FolderSettings settings              = null;
    /** File Monitor of this folder */
    private FileMonitor monitor                  = null;
    /** List of items of this folder */
    protected List <ItemManager> items           = null;
    /** name of the folder */
    private string folder_name                   = null;
    /** drag and drop behaviour for this folder */
    private DragnDrop.DndBehaviour dnd_behaviour = null;
    /** the arrangement for this folder manager */
    private FolderArrangement arrangement        = null;
    // the last selected item
    private ItemView selected_item               = null;


    /**
     * @constructor
     * @param DesktopFolderApp application the application owner of this window
     * @param string folder_name the name of the folder
     */
    public FolderManager (DesktopFolderApp application, string folder_name) {
        this.folder_name = folder_name;

        // Let's load the settings of the folder (if exist or a new one)
        this.load_folder_settings ();

        // First we create a Folder Window above the desktop
        this.application = application;
        this.create_view ();
        this.application.add_window (this.view);
        this.view.show ();

        // trying to put it in front of the rest
        this.view.set_keep_below (false);
        this.view.set_keep_above (true);
        this.view.present ();
        this.view.set_keep_above (false);
        this.view.set_keep_below (true);
        // ---------------------------------------

        // let's sync the files found at this folder
        GLib.Idle.add_full (GLib.Priority.LOW, () => {
            this.sync_files (0, 0);
            return false;
        });


        // finally, we start monitoring the folder
        this.monitor_folder ();

        this.dnd_behaviour = new DragnDrop.DndBehaviour (this, false, true);
    }

    /**
     * @name create_view
     * @description create the view associated with this manager
     */
    protected virtual void create_view () {
        this.view = new DesktopFolder.FolderWindow (this);
    }

    /**
     * @name on_screen_size_changed
     * @description detecting screen size changes
     */
    public virtual void on_screen_size_changed (Gdk.Screen screen) {
        debug ("size changed for %s", this.folder_name);
        this.settings.calculate_current_position ();
        debug ("reloading settings");
        this.view.reload_settings ();
    }

    /**
     * @name on_arrange_change
     * @description arrange type changed for the panel
     */
    public void on_arrange_change (int type) {
        if (this.settings.arrangement_type != type) {
            this.settings.arrangement_type = type;
            this.settings.save ();
            this.arrangement               = FolderArrangement.factory (this.settings.arrangement_type);

            if (this.arrangement.forze_organization ()) {
                this.organize_panel_items ();
            }
        }
    }

    /**
     * @name set_selected_item
     * @description set the selected item
     * @param ItemView selected the new selected item
     */
    public void set_selected_item (ItemView ? selected) {
        this.selected_item = selected;
    }

    /**
     * @name get_selected_item
     * @description return the current selected item, or null if none
     * @return ItemView the current selected item, null if none
     */
    public ItemView ? get_selected_item () {
        return this.selected_item;
    }


    /**
     * @name are_items_locked
     * @description return whether the items are locked or not
     * @return {bool} true->yes, the items are locked, false otherwise
     */
    public bool are_items_locked () {
        return this.get_settings ().lockitems;
    }

    /**
     * @name load_folder_settings
     * @description load the settings file inside the folder (if exist), if not, it will create a new one.
     * The settings file contains the basic info saved to create window and items componentes.. position, size, etc..
     */
    private void load_folder_settings () {
        // let's search the folder settings file
        var abs_path      = this.get_absolute_path ();
        // debug ("loading folder settings...%s", abs_path);
        var settings_file = abs_path + "/.desktopfolder";
        var file          = File.new_for_path (settings_file);
        if (!file.query_exists ()) {
            // we don't have yet a folder settings file, let's create one
            FolderSettings newone = new FolderSettings (this.folder_name);
            newone.save_to_file (file);
            this.settings = newone;
        } else {
            FolderSettings existent = FolderSettings.read_settings (file, this.get_folder_name ());
            this.settings = existent;
        }

        this.settings.calculate_current_position ();

        // creating the Manager
        this.arrangement = FolderArrangement.factory (this.settings.arrangement_type);
    }

    /**
     * @name can_move
     * @description say if the panel can move or not
     * @return {bool} true->yes, the panel can be moved
     */
    public bool can_move () {
        return this.is_moveable && !this.settings.lockpanel;
    }

    /**
     * @name monitor_folder
     * @description monitor the folder owned by this manager looking for changes inside
     */
    private void monitor_folder () {
        try {
            if (this.monitor != null) {
                // if we have an existing monitor, we cancel it before to monitor again
                this.monitor.cancel ();
            }
            File directory = this.get_file ();
            this.monitor            = directory.monitor_directory (FileMonitorFlags.SEND_MOVED, null);
            this.monitor.rate_limit = 100;
            debug ("Monitoring: %s", directory.get_path ());
            this.monitor.changed.connect (this.directory_changed);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name directory_changed
     * @description we received an event of the monitor that indicates a change
     * @see changed signal of FileMonitor (https://valadoc.org/gio-2.0/GLib.FileMonitor.changed.html)
     */
    private void directory_changed (GLib.File src, GLib.File ? dest, FileMonitorEvent event) {
        File file_myself = this.get_file ();
        if (file_myself.get_path () == src.get_path ()) {
            // its me! maybe I was removed :(
            return;
        }
        string old_filename = src.get_basename ();
        if (old_filename == DesktopFolder.FOLDER_SETTINGS_FILE) {
            // we ignore the settings file changes
        } else {
            // debug ("%s - Change Detected", this.get_folder_name ());
            if (dest != null && src.query_exists () && dest.query_exists ()) {
                // something has been renamed
                string new_filename = dest.get_basename ();
                this.settings.rename (old_filename, new_filename);
                this.settings.save ();

                // we need to rename the affected file/folder
                for (int i = 0; i < this.items.length (); i++) {
                    ItemManager element = (ItemManager) this.items.nth_data (i);
                    if (element.get_file_name () == old_filename) {
                        element.rename (new_filename);
                    }
                }

                // finally we refresh the view
                this.view.refresh ();
            } else {
                // somehthing changed.. created or removed
                this.sync_files (0, 0);
            }

        }
    }

    /**
     * @name get_folder_name
     * @description return the folder name
     * @return string the folder name
     */
    public string get_folder_name () {
        return this.folder_name;
    }

    /**
     * @name get_application
     * @description return the desktop folder application
     * @return DesktopFolderApp
     */
    public DesktopFolderApp get_application () {
        return this.application;
    }

    /**
     * @name get_arrangement
     * @description return the current arrangement for the panel's items
     * @return FolderArrangement the current arrangement class
     */
    public FolderArrangement get_arrangement () {
        return this.arrangement;
    }

    /**
     * @name skip_file
     * @description to check if the folder manager should skip the file and not take into account
     */
    protected virtual bool skip_file (File file) {
        string basename = file.get_basename ();
        if (basename.has_prefix (".")) {
            return true;
        }
        if (basename.has_suffix ("~")) {
            return true;
        }
        return false;
    }

    /**
     * @name sync_files
     * @description sync all the files contained at the folder this manager refers to
     * @param x int the x position where any new item found should be positioned, <=0 if this algorithm must decide
     * @param y int the y position where any new item found should be positioned, <=0 if this algorithm must decide
     */
    public void sync_files (int x, int y) {
        // debug ("syncingfiles for folder %s, %d, %d", this.get_folder_name (), x, y);
        try {
            this.load_folder_settings ();

            // the current list must be refreshed, copying in an old list
            List <ItemManager> oldItems = new List <ItemManager>();
            this.items.foreach ((entry) => { oldItems.append (entry); }) ;
            this.items = new List <ItemManager>();

            // list of new file names recently created that need to find a valid position
            List <string> newItemsToPosition = new List <string>();

            string base_path                 = this.get_absolute_path ();
            File   directory                 = this.get_file ();

            // listing all the files inside this folder
            var      enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo file_info;

            // list of gaps to put new items without a custom position
            FolderGrid <ItemSettings> grid = null;

            while ((file_info = enumerator.next_file ()) != null) {
                string file_name = file_info.get_name ();
                // debug("found:%s", file_name);
                File file        = File.new_for_commandline_arg (base_path + "/" + file_name);

                if (file_name == ".nopanel") {
                    // This folder doesn't want to be a panel anymore, destroy the panel
                    debug (".nopanel found, destroying panel");
                    this.close ();
                    return;
                }

                // checking if we must skip the file
                if (this.skip_file (file)) {
                    continue;
                }


                // debug("creating an item...");
                // we try to get the settings for this item
                ItemSettings is = this.settings.get_item (file_name);
                if (is == null) {
                    newItemsToPosition.append (file_name);
                } else {
                    // lets check if the item already exists
                    ItemManager oldItemManager = popItemFromList (file_name, ref oldItems);
                    if (oldItemManager != null) {
                        this.items.append (oldItemManager);
                    } else {
                        ItemManager item = new ItemManager (file_name, file, this);
                        this.items.append (item);
                        this.view.add_item (item.get_view (), is.x, is.y);
                    }

                }

            }

            // removing old entries, now no exist
            oldItems.foreach ((entry) => {
                this.view.remove_item (entry.get_view ());
            }) ;

            // last, there are new items that need to be positioned in a valid place
            newItemsToPosition.foreach ((file_name) => {
                File file = File.new_for_commandline_arg (base_path + "/" + file_name);
                // we need to create one empty
                ItemSettings is = new ItemSettings ();
                if (x == 0 && y == 0) {
                    // no desired position for the item, lets calculate a good position
                    if (grid == null) {
                        // building the structure to see current gaps
                        grid = FolderGrid.build_grid_structure (this.view);
                        // grid.print();
                    }
                    Gdk.Point pos = grid.get_next_gap (this.view, is);
                    is.x = pos.x;
                    is.y = pos.y;
                } else {
                    is.x = x;
                    is.y = y;
                }
                is.name = file_name;
                this.settings.add_item (is);
                ItemManager item = new ItemManager (file_name, file, this);
                this.items.append (item);
                this.view.add_item (item.get_view (), is.x, is.y);
            }) ;

            this.settings.save ();
            this.view.refresh ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name organize_panel_items
     * @description the panel try to organize all the items over the panel. This is asked manually by the user.
     */
    public void organize_panel_items () {
        bool asc = !this.settings.sort_reverse;
        FolderArrangement.organize_items (this.view, ref this.items, this.settings.sort_by_type, asc);
    }

    /**
     * @name popItemFromList
     * @description try to ind an item in a item list by the file get_name
     * @param string file_name the file name of the item
     * @param List<ItemManager> the list to search inside (reference)
     * @return ItemManager the itemmanager found, or null if none match
     */
    private ItemManager ? popItemFromList (string file_name, ref List <ItemManager> items) {
        foreach (ItemManager item in items) {
            if (item.get_file_name () == file_name) {
                items.remove (item);
                return item;
            }
        }
        return null;
    }

    /**
     * @name clear_all
     * @description clear all the items associated with this folder
     */
    public virtual void hide_items () {
    }

    /**
     * @name clear_all
     * @description clear all the items associated with this folder
     */
    public void clear_all () {
        this.items = new List <ItemManager> ();
        this.view.clear_all ();
    }

    /**
     * @name open_terminal_here
     * @description open terminal here, works in folder & on Desktop
     */
    public void open_terminal_here (string path) {
        try {
            Environment.set_current_dir (path);
            Process.spawn_command_line_async ("x-terminal-emulator --working-directory \"" + path + "\"");
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name create_new_folder_inside
     * @description function to create inside the recent created folder whatever is needed
     * @param {string} folder_path the folder which is being created
     */
    protected virtual void create_new_folder_inside (string folder_path) {
    }

    /**
     * @name create_new_folder
     * @description create a new folder inside this folder
     * @param string name the name of the new folder
     * @param int x the x position of the new folder
     * @param int y the y position of the new folder
     */
    public void create_new_folder (string name, int x, int y) {
        // cancelling the current monitor
        this.monitor.cancel ();
        string folder_path = this.get_absolute_path () + "/" + name;
        DirUtils.create (folder_path, 0755);

        this.create_new_folder_inside (folder_path);
        // forcing the sync of the files as a new folder has been created
        this.sync_files (x, y);
        // monitoring again
        this.monitor_folder ();
    }

    /**
     * @name create_new_text_file
     * @description create a new text file inside this folder
     * @param string name the name of the new text file
     * @param int x the x position of the new file
     * @param int y the y position of the new file
     */
    public void create_new_text_file (string name, int x, int y) {
        // cancelling the current monitor
        this.monitor.cancel ();

        // we create the text file with a touch command
        try {
            var command = "touch \"" + this.get_absolute_path () + "/" + name + "\"";
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);

            // forcing the sync of the files as a new folder has been created
            this.sync_files (x, y);
            // monitoring again
            this.monitor_folder ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name create_new_link
     * @description create a new link inside this folder
     * @param string target the target of the new link file
     * @param int x the x position of the new file
     * @param int y the y position of the new file
     */
    public void create_new_link (string target, int x, int y) {
        // cancelling the current monitor
        this.monitor.cancel ();

        // we create the text file with a touch command
        try {
            var file    = File.new_for_path (target);
            var name    = file.get_basename ();
            var command = "ln -s \"" + target + "\" \"" + this.get_absolute_path () + "/" + name + "\"";
            // debug("command: %s"+command);
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);

            // forcing the sync of the files as a new lynk has been created
            this.sync_files (x, y);
            // monitoring again
            this.monitor_folder ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name trash
     * @description deleting myself!!
     */
    public void trash () {
        try {
            File file = File.new_for_path (this.get_absolute_path ());
            file.trash ();
            this.close ();
        } catch (Error error) {
            stderr.printf ("Error: %s\n", error.message);
            Util.show_error_dialog ("Error", error.message);
        }
    }

    /**
     * @name close
     * @description close the folder manager and its view
     */
    public void close () {
        this.monitor.cancel ();
        this.view.close ();
    }

    /**
     * @name rename
     * @description Renaming the folder
     * @param string name the new name
     * @return bool true->everything is ok, false->something failed, rollback
     */
    public bool rename (string new_name) {
        string sanitized_name = DesktopFolder.Util.sanitize_name (new_name);
        if (!DesktopFolder.Util.check_name (sanitized_name)) {
            DesktopFolder.Util.show_invalid_name_error_dialog (this.view, new_name);
            return false;
        }
        var old_name  = this.folder_name;
        var old_path  = this.get_absolute_path ();
        this.folder_name = sanitized_name;
        var new_path  = this.get_absolute_path ();
        var directory = File.new_for_path (new_path);
        try {
            if (directory.query_exists ()) {
                DesktopFolder.Util.show_file_exists_error_dialog (this.view, sanitized_name, _("Panel"), null);
                throw new FolderManagerIOError.FILE_EXISTS ("Folder already exists");
            }
            this.settings.name = this.folder_name;
            this.settings.save ();
            FileUtils.rename (old_path, new_path);
            var new_directory = File.new_for_path (new_path);
            if (new_directory.query_exists ()) {
                // forcing to reload settings
                this.load_folder_settings ();
                this.sync_files (0, 0);
                this.monitor_folder ();
                return true;
            } else {
                throw new FolderManagerIOError.MOVE_ERROR ("Failed to rename folder");
            }
        } catch (Error error) {
            warning (error.message);
            // Revert changes
            this.folder_name   = old_name;
            this.settings.name = this.folder_name;
            this.settings.save ();
            return false;
        }
    }

    /**
     * @name paste
     * @description paste what ever is in the clipboard (file or folder) to this desktop folder
     */
    public void paste () {
        Clipboard.ClipboardManager cm = Clipboard.ClipboardManager.get_for_display ();
        if (cm.can_paste) {
            File folder = this.get_file ();
            cm.paste_files (folder, null, null);
        }
    }

    /**
     * @name set_new_shape
     * @description set a new shape (position and size) of the view
     */
    public void set_new_shape (int x, int y, int width, int height) {
        this.settings.x = x;
        this.settings.y = y;
        this.settings.w = width;
        this.settings.h = height;
        this.settings.save ();
    }

    /**
     * @name save_head_color
     * @description save a head color to the settings file
     * @param color string the color for the head to be saved
     */
    public void save_head_color (string color) {
        this.settings.fgcolor = color;
        this.settings.save ();
    }

    /**
     * @name save_body_color
     * @description save a body color to the settings file
     * @param color string the color for the body to be saved
     */
    public void save_body_color (string color) {
        this.settings.bgcolor = color;
        this.settings.save ();
    }

    /**
     * @name get_absolute_path
     * @description return the absolute path for this folder
     * @return the absolute path
     */
    public string get_absolute_path () {
        return DesktopFolderApp.get_app_folder () + "/" + this.folder_name;
    }

    /**
     * @name get_file
     * @description return the Glib.File associated with this folder
     * @return File the File object
     */
    private File get_file () {
        var  basePath  = this.get_absolute_path ();
        File directory = File.new_for_path (basePath);
        return directory;
    }

    /**
     * @name get_settings
     * @description return the settings of this folder
     * @return FolderSettings the settings of this folder
     */
    public FolderSettings get_settings () {
        return this.settings;
    }

    /**
     * @name reopen
     * @description close the current view and reopen it again
     */
    public void reopen () {
        this.get_settings ().save ();

        // closing
        this.application.remove_window (this.view);
        this.view.close ();
        // reopening
        this.view = new FolderWindow (this);
        this.application.add_window (this.view);
        this.view.show ();

        // trying to put it in front of the rest
        this.view.set_keep_below (false);
        this.view.set_keep_above (true);
        this.view.present ();
        this.view.set_keep_above (false);
        this.view.set_keep_below (true);
        // ---------------------------------------

        // let's sync the files found at this folder
        this.sync_files (0, 0);

        this.view.show_all ();
    }

    /**
     * @name get_view
     * @description return the FolderWindow view of this manager
     * @return FolderWindow
     */
    public FolderWindow get_view () {
        return this.view;
    }

    /**
     * @name on_active
     * @description the folder is window is being active.
     */
    public void on_active () {
        // lets recheck the file existence
        this.on_mount_changed ();
    }

    /**
     * @name on_mount_changed
     * @description the mount filesystem has been changed
     */
    public void on_mount_changed () {
        // lets recheck the file existence
        for (int i = 0; i < this.items.length (); i++) {
            ItemManager element = (ItemManager) this.items.nth_data (i);
            element.recheck_existence ();
        }
    }

    // ---------------------------------------------------------------------------------------
    // ---------------------------DndView Implementation--------------------------------------
    // ---------------------------------------------------------------------------------------

    /**
     * @name get_widget
     * @description return the widget associated with this view
     * @return Widget the widget
     */
    public Gtk.Widget get_widget () {
        return this.view;
    }

    /**
     * @name get_application_window
     * @description return the application window of this view, needed for drag operations
     * @return ApplicationWindow
     */
    public Gtk.ApplicationWindow get_application_window () {
        return this.view;
    }

    /**
     * @name get_file_at
     * @name get the file at the position x, y
     * @return File
     */
    public GLib.File get_file_at (int x, int y) {
        return this.get_file ();
    }

    /**
     * @name is_link
     * @description check whether the item is a link to other folder or not
     * @return {bool} true-> yes it is a link
     */
    public bool is_link () {
        var file = this.get_file ();
        var path = file.get_path ();
        return FileUtils.test (path, FileTest.IS_SYMLINK);
    }

    /**
     * @name is_writable
     * @description indicates if the file linked by this view is writable or not
     * @return bool
     */
    public bool is_writable () {
        // TODO
        return true;
    }

    /**
     * @name is_folder
     * @description check whether the view represents a folder or a file
     * @return bool true->this view represents a folder
     */
    public bool is_folder () {
        return true;
    }

    /**
     * @name get_target_location
     * @description return the target File that represents this view
     * @return File the file target of this view
     */
    public GLib.File get_target_location () {
        return this.get_file ();
    }

    /**
     * @name is_recent_uri_scheme
     * @description check whether the File is a recent uri scheme?
     * @return bool
     */
    public bool is_recent_uri_scheme () {
        return true;
    }

    /**
     * @name get_display_target_uri
     * @description return the target uri of this view
     * @return string the target uri
     */
    public string get_display_target_uri () {
        return DragnDrop.Util.get_display_target_uri (this.get_file ());
    }

    /**
     * @overrided
     */
    public Gtk.Image get_image () {
        return null as Gtk.Image;
    }

    public void on_drag_end () {
        // nothing
    }

    // ---------------------------------------------------------------------------------------
    // ---------------------------**********************--------------------------------------
    // ---------------------------------------------------------------------------------------
}
