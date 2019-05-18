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

protected errordomain FolderManagerIOError {
    FILE_EXISTS,
    MOVE_ERROR
}

/**
 * @class
 * Desktop Folder Manager
 */
public class DesktopFolder.FolderManager : Object, DragnDrop.DndView, FolderSettingsInfoProvider {
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
    public List <ItemManager> items              = null;
    /** name of the folder */
    private string folder_name                   = null;
    /** drag and drop behaviour for this folder */
    private DragnDrop.DndBehaviour dnd_behaviour = null;
    /** the arrangement for this folder manager */
    private FolderArrangement arrangement        = null;
    // the list of selected items
    private Gee.List <ItemView> selected_items   = new Gee.ArrayList <ItemView>();
    /** Folder Sync Thread */
    private FolderSync.Thread sync_thread        = null;
    /** the id for the organize event timer */
    private uint organize_event_timeout;


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

        this.try_to_order_at_top ();

        // let's sync the files found at this folder
        this.sync_files (0, 0);

        // finally, we start monitoring the folder
        this.monitor_folder ();

        this.view.refresh ();

        this.dnd_behaviour = new DragnDrop.DndBehaviour (this, false, true);
    }

    /**
     * @overrided
     */
    public virtual int get_parent_default_arrangement_orientation_setting () {
        return FolderSettings.ARRANGEMENT_ORIENTATION_HORIZONTAL;
    }

    /**
     * @name create_view
     * @description create the view associated with this manager
     */
    protected virtual void create_view () {
        this.view = new DesktopFolder.FolderWindow (this);
        this.application.add_window (this.view);
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

            if (this.arrangement.force_organization ()) {
                this.organize_panel_items ();
            }
        }
    }

    /**
     * @name get_item_by_filename
     * @description get item by filename, or null if none
     * @param string filename to get item for, null if none
     */
    public ItemManager ? get_item_by_filename (string name) {
        foreach (ItemManager item in this.items) {
            if (item.get_file_name () == name) {
                return item;
            }
        }
        return null;
    }

    public void select_items (Gdk.Rectangle sel_rectangle) {
        this.view.unselect_all ();
        this.selected_items.clear ();
        // debug("sel_rectangle(%d,%d,%d,%d)",sel_rectangle.x,sel_rectangle.y,sel_rectangle.width,sel_rectangle.height);
        foreach (ItemManager item in this.items) {
            Gdk.Rectangle item_rect = item.get_view ().get_bounding_box ();
            // debug("item_rect(%d,%d,%d,%d)",item_rect.x,item_rect.y,item_rect.width,item_rect.height);
            bool intersect          = item_rect.intersect (sel_rectangle, null);
            if (intersect) {
                // debug("sel_rectangle(%d,%d,%d,%d)",sel_rectangle.x,sel_rectangle.y,sel_rectangle.width,sel_rectangle.height);
                // debug("item_rect(%d,%d,%d,%d)",item_rect.x,item_rect.y,item_rect.width,item_rect.height);
                item.get_view ().select_add ();
            }
        }
    }

    /**
     * @name set_selected_item
     * @description set the selected item
     * @param ItemView selected the new selected item
     */
    public void set_selected_item (ItemView ? selected) {
        this.selected_items.clear ();
        this.selected_items.add (selected);
    }

    /**
     * @name add_selected_item
     * @description add the item to the selected list of items
     * @param {ItemView} the new selected item to add
     */
    public void add_selected_item (ItemView ? selected) {
        this.selected_items.add (selected);
    }

    /**
     * @name remove_selected_item
     * @description remove a selected item from the list of selected items
     * @param {ItemView} selected the item view which will be removed
     */
    public void remove_selected_item (ItemView selected) {
        this.selected_items.remove (selected);
    }

    /**
     * @name get_selected_item
     * @description return the current selected item, or null if none
     * @return ItemView the current selected item, null if none
     */
    public Gee.List <ItemView> get_selected_items () {
        return this.selected_items;
    }

    /**
     * @name are_items_selected
     * @description check whether there are 1 or more items selected
     * @return {bool} true->yes, there are
     */
    public bool are_items_selected () {
        return this.selected_items.size > 0;
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
            FolderSettings existent = FolderSettings.read_settings (file, this.get_folder_name (), this);
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
            this.monitor            = directory.monitor_directory (FileMonitorFlags.WATCH_MOVES, null);
            this.monitor.rate_limit = 100;
            debug ("Monitoring: %s", directory.get_path ());
            this.monitor.changed.connect (this.directory_changed);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name on_sync_finished
     * @description sync thread has been finished
     */
    public void on_sync_finished () {
        this.view.refresh ();
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
            debug ("%s - Change Detected - %d", this.get_folder_name (), event);
            if (event == FileMonitorEvent.RENAMED) {
                // something has been renamed
                string new_filename = dest.get_basename ();
                this.settings.rename (old_filename, new_filename);
                this.settings.save ();

                // we need to rename the affected file/folder
                for (int i = 0; i < this.items.length (); i++) {
                    ItemManager element = (ItemManager) this.items.nth_data (i);
                    if (element.get_file_name () == old_filename) {
                        element.rename (new_filename);
                        element.get_view ().rename (new_filename);
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
    public virtual bool skip_file (File file) {
        string basename = file.get_basename ();
        if (basename.has_prefix (".")) {
            return true;
        }
        if (basename.has_suffix ("~")) {
            return true;
        }
        return false;
    }

    protected void try_to_order_at_top () {
        this.view.set_keep_below (false);
        this.view.set_keep_above (true);
        this.view.present ();
        this.view.set_keep_above (false);
        this.view.set_keep_below (true);
    }

    /**
     * @name stop_sync
     * @description stop the syncing thread (if any)
     */
    public bool is_sync_running () {
        if (this.sync_thread != null) {
            return this.sync_thread.is_running ();
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
        if (this.sync_thread == null) {
            this.sync_thread = new FolderSync.Thread (this);
        }
        this.load_folder_settings ();
        this.sync_thread.sync_files (x, y);
    }

    /**
     * @name organize_panel_items
     * @description the panel try to organize all the items over the panel. This is asked manually by the user.
     */
    public void organize_panel_items () {
        if (this.organize_event_timeout > 0) {
            Source.remove (this.organize_event_timeout);
            this.organize_event_timeout = 0;
        }
        this.organize_event_timeout = Timeout.add (500, () => {
            this.organize_event_timeout = 0;

            bool asc = !this.settings.sort_reverse;
            FolderArrangement.organize_items (this.view, ref this.items, this.settings.sort_by_type, asc, this.is_vertical_arragement ());

            return false;
        });
    }

    /**
     * @name get_item_at
     * @description return the item at a certain area of the folder window
     * @param {Gdk.Rectangle} rectangle the rectangle area to search
     * @return {ItemManager} return the item at that area found, or null if none
     */
    public Gee.List <ItemManager> ? get_items_at (Gdk.Rectangle rectangle) {
        Gee.List <ItemManager> result = new Gee.ArrayList <ItemManager>();
        for (int i = 0; i < this.items.length (); i++) {
            ItemManager    im = this.items.nth_data (i);
            ItemView       iv = im.get_view ();
            Gtk.Allocation allocation;
            iv.get_allocation (out allocation);

            int           qwidth         = DesktopFolder.ICON_DEFAULT_WIDTH / 2;
            Gdk.Rectangle icon_rectangle = Gdk.Rectangle ();
            icon_rectangle.x      = allocation.x + qwidth;
            icon_rectangle.y      = allocation.y + qwidth;
            icon_rectangle.width  = DesktopFolder.ICON_DEFAULT_WIDTH - qwidth;
            icon_rectangle.height = DesktopFolder.ICON_DEFAULT_WIDTH - qwidth;

            if (rectangle.intersect (icon_rectangle, null)) {
                result.add (im);
            }
        }

        return result;
    }

    /**
     * @name is_vertical_arragement
     * @description check whether the arrangement is vertically
     * @return {bool} true->vertical, false->horizontal
     */
    public bool is_vertical_arragement () {
        return this.settings.arrangement_orientation == FolderSettings.ARRANGEMENT_ORIENTATION_VERTICAL;
    }

    /**
     * @name quick_show_items
     * @description shows the items
     */
    public void quick_show_items () {
        // TODO Make this less messy
        foreach (var item in items) {
            item.get_view ().show_all ();
            item.get_view ().get_style_context ().remove_class ("df_fadingwindow");
            item.get_view ().get_style_context ().remove_class ("df_fadeout");
            item.get_view ().get_style_context ().add_class ("df_fadein");
            Timeout.add (20, () => {
                item.get_view ().get_style_context ().add_class ("df_fadingwindow");
                return false;
            });
        }
    }

    /**
     * @name show_items
     * @description shows the items
     */
    public virtual void show_items () {
        foreach (var item in items) {
            item.show_view ();
        }
    }

    /**
     * @name hide_items
     * @description hides the items
     */
    public virtual void hide_items () {
        foreach (var item in items) {
            item.hide_view ();
        }
    }

    /**
     * @name show_view
     * @description show the folder
     */
    public virtual void show_view () {
        // setting opacity to stop the folder window flashing at startup
        this.view.opacity = 1;
        this.view.show_all ();
        this.view.fade_in ();
        this.show_items ();
    }

    /**
     * @name hide_view
     * @description hide the folder
     */
    public virtual void hide_view () {
        this.view.fade_out ();
        Timeout.add (160, () => {
            // ditto
            this.view.opacity = 0;
            this.view.hide ();
            return false;
        });
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
    public string create_new_folder (int x, int y, string name = DesktopFolder.Lang.DESKTOPFOLDER_NEW_FOLDER_NAME) {
        string path     = this.get_absolute_path () + "/" + name;
        string new_name = "";
        File   folder   = File.new_for_path (path);

        if (folder.query_exists ()) {
            new_name = DesktopFolder.Util.make_next_duplicate_name (name, this.get_absolute_path ());
        } else {
            new_name = name;
        }
        // cancelling the current monitor
        this.monitor.cancel ();

        try {
            string folder_path = this.get_absolute_path () + "/" + new_name;
            DirUtils.create (folder_path, 0755);

            this.create_new_folder_inside (folder_path);
            // forcing the sync of the files as a new folder has been created
            this.sync_files (x, y);
            // monitoring again
            this.monitor_folder ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }

        return new_name;
    }

    /**
     * @name create_new_text_file
     * @description create a new text file inside this folder
     * @param string name the name of the new text file
     * @param int x the x position of the new file
     * @param int y the y position of the new file
     */
    public string create_new_text_file (int x, int y, string name = DesktopFolder.Lang.DESKTOPFOLDER_NEW_TEXT_FILE_NAME) {
        string path     = this.get_absolute_path () + "/" + name;
        string new_name = "";

        File file       = File.new_for_path (path);
        if (file.query_exists ()) {
            new_name = DesktopFolder.Util.make_next_duplicate_name (name, this.get_absolute_path ());
        } else {
            new_name = name;
        }

        // cancelling the current monitor
        this.monitor.cancel ();

        // we create the text file with a touch command
        try {
            file = File.new_for_path (this.get_absolute_path () + "/" + new_name);
            file.create (FileCreateFlags.NONE);

            // forcing the sync of the files as a new folder has been created
            this.sync_files (x, y);
            // monitoring again
            this.monitor_folder ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
        return new_name;
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
        this.view.hide ();
        this.application.remove_window (this.view);
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
        bool flag_size_change = (this.settings.w != width || this.settings.h != height);
        this.settings.w = width;
        this.settings.h = height;
        this.settings.save ();

        if (flag_size_change && this.get_arrangement ().force_organization ()) {
            this.organize_panel_items ();
        }

        if (flag_size_change && this.sync_thread != null) {
            this.sync_thread.on_resize ();
        }
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
        this.close ();

        // reopening
        this.create_view ();

        this.try_to_order_at_top ();


        // let's sync the files found at this folder
        this.sync_files (0, 0);

        this.monitor_folder ();

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

    public void on_drag_motion () {
    }

    public void on_drag_leave () {
    }

    /**
     * @overrided
     */
    public DragnDrop.DndView[] get_all_selected_views () {
        Gee.List <ItemView> selected_views = this.get_selected_items ();
        DragnDrop.DndView[] result         = new DragnDrop.DndView[selected_views.size];
        for (int i = 0; i < selected_views.size; i++) {
            result[i] = (DragnDrop.DndView)selected_views.@get (i);
        }
        return result;
    }

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

public class DesktopFolder.FolderSync.Param {
    public int x { get; set; }
    public int y { get; set; }

    public Param (int x, int y) {
        this.x = x;
        this.y = y;
    }
}

public class DesktopFolder.FolderSync.PendingItem {
    public string file_name { get; set; }
    public File file { get; set; }
    public bool calculate_position { get; set; default = false; }
    public ItemSettings settings { get; set; }

    public PendingItem (File file, string file_name, bool calculate_position, ItemSettings ? settings) {
        this.file               = file;
        this.file_name          = file_name;
        this.calculate_position = calculate_position;
        this.settings           = settings;
    }
}

public class DesktopFolder.FolderSync.Thread {
    /** the manager owner */
    private FolderManager manager;
    /** flag to know if the algorithm should stop and restart */
    private bool flag_restart = false;
    /** flag to know whether the sync algorithm is running or not */
    private bool flag_running = false;

    /** list of pending items to add to the folder window  */
    private Gee.List <PendingItem> pending_items_to_process = null;
    /** list of pending command params to process */
    private Gee.List <Param> pending_params_to_process      = null;
    /** semaphore */
    private Mutex mutex            = Mutex ();
    // the current grid of items, util to find gaps and position automatically new items
    FolderGrid <ItemSettings> grid = null;

    /**
     * Constructor
     * @param {FolderManager} manager the manager owned of this thread
     */
    public Thread (FolderManager manager) {
        this.manager = manager;
        this.pending_params_to_process = new Gee.ArrayList <Param>();
    }

    public bool is_running () {
        return this.flag_running;
    }

    /**
     * @name add_pending
     * @descripition add a param to pending params to process
     */
    private void add_pending_param (Param param) {
        mutex.lock () ;
        this.pending_params_to_process.add (param);
        mutex.unlock ();
    }

    /**
     * @name on_resize
     * @description the folder window was resize, this function notify of that event
     */
    public void on_resize () {
        mutex.lock () ;
        this.grid = null;
        mutex.unlock ();
    }

    /**
     * @name sync_files
     * @param {int} x the x point where the next not managed item found should be positioned
     * @param {int} y the y point where the next not managed item found should be positioned
     */
    public void sync_files (int x, int y) {
        // we add the pending param to be processed, when a new item is found
        this.add_pending_param (new Param (x, y));

        mutex.lock () ;
        if (this.flag_running) {
            // it is running, so, lets start
            this.flag_restart = true;
        } else {
            // the algorithm is not running, lets execute it in a new thread
            this.flag_running = true;
            try {
                this.manager.get_view ().show_loading ();
                new GLib.Thread <bool> .try ("sync_thread", this._sync_files);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
                Util.show_error_dialog ("Error", e.message);
            }
        }
        mutex.unlock ();
    }

    /**
     * @name set_restart
     * @description set the flag restart to a value (concurrent safe)
     * @param {bool} value the value to set
     */
    private void set_restart (bool value) {
        mutex.lock () ;
        this.flag_restart = value;
        mutex.unlock ();
    }

    /**
     * @name set_running
     * @description set the flag running to a value (concurrent safe)
     * @param {bool} value the value to set
     */
    private void set_running (bool value) {
        mutex.lock () ;
        this.flag_running = value;
        mutex.unlock ();
    }

    /**
     * @name _sync_files
     * @description this is the sync algorithm processed in a different thread
     */
    private bool _sync_files () {
        this.grid = null;
        debug (">>>>>>>>>>> INIT _sync_files for Panel: %s", this.manager.get_folder_name ());
        this.set_running (true);
        this.set_restart (true);
        int restart_count = 0;

        // main loop, in case we need to restart the algorithm (new sync commands)
        while (this.flag_restart) {
            restart_count++;
            debug (">>>>>>>>>>>>>>>>>>>>>>>RESTARTING _sync_files %d times for Panel %s", restart_count - 1, this.manager.get_folder_name ());
            this.set_restart (false);

            // 1. setting some initial variables
            // --------------------------------------------------------------------------
            // list of current items that are showed in the window
            List <ItemManager> old_showed_items = new List <ItemManager>();
            this.manager.items.foreach ((entry) => {
                // debug("actualmente el manager tiene este entry: %s",entry.get_file_name());
                old_showed_items.append (entry);
            }) ;
            // list of new items to be viewed in the window
            List <ItemManager> new_viewed_items = new List <ItemManager>();
            // list of current items managed by the settings
            Gee.HashMap <string, ItemSettings> old_managed_items = this.manager.get_settings ().get_items_parsed ();
            // list of pending items to be processed (to create setting, manager and view)
            this.pending_items_to_process = new Gee.ArrayList <PendingItem>();
            string   base_path       = this.manager.get_absolute_path ();
            File     directory       = this.manager.get_file ();
            var      file_enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);
            FileInfo file_info;

            // 2. looping through all the files in the folder
            // --------------------------------------------------------------------------
            while ((file_info = file_enumerator.next_file ()) != null) {
                ////////////////////////////////////
                // >>>>>>>>> check control <<<<<<<<<
                if (this.flag_restart) /////////////
                    break; /////////////////////////
                // >>>>>>>>> check control <<<<<<<<<
                ////////////////////////////////////

                // lets get the file to process
                string file_name = file_info.get_name ();
                File   file      = File.new_for_commandline_arg (base_path + "/" + file_name);
                debug ("syncing file found:%s", base_path + "/" + file_name);

                // checking the .nopanel flag
                if (file_name == ".nopanel") {
                    // This folder doesn't want to be a panel anymore, destroy the panel
                    debug (".nopanel found, destroying panel");
                    this.manager.close ();
                    this.set_running (false);
                    this.set_restart (false);
                    return false;
                }

                // checking if we must skip the file
                if (this.manager.skip_file (file)) {
                    // debug("skiping file %s", file_name);
                    continue;
                }

                // we try to get the settings for this item
                ItemSettings is = old_managed_items[file_name];
                if (is == null) {
                    // debug("1---we don't have this file managed yet: %s",file_name);
                    // we don't have this file managed yet
                    this.pending_items_to_process.add (new PendingItem (file, file_name, true, null));
                } else {
                    // lets check if the item already exists
                    ItemManager old_item_manager = this.pop_item_from_list (file_name, ref old_showed_items);
                    if (old_item_manager != null) {
                        // debug("2---yes, this is an existing already managed file: %s",file_name);
                        // yes, this is an existing already managed file, lets update
                        old_item_manager.set_file (file);
                        new_viewed_items.append (old_item_manager);
                    } else {
                        // debug("3---no, we need to add this file: %s",file_name);
                        this.pending_items_to_process.add (new PendingItem (file, file_name, false, is));
                    }
                }
            }

            ////////////////////////////////////
            // >>>>>>>>> check control <<<<<<<<<
            if (this.flag_restart) /////////////
                continue; //////////////////////
            // >>>>>>>>> check control <<<<<<<<<
            ////////////////////////////////////


            // 2. Last part, there are new items that need to be positioned in a valid place
            // --------------------------------------------------------------------------
            // removing old entries, now no exist
            old_showed_items.foreach ((entry) => {
                GLib.Idle.add_full (GLib.Priority.LOW, () => {
                    this.manager.get_view ().remove_item (entry.get_view ());
                    return false;
                });
            }) ;
            this.manager.items = new List <ItemManager>();
            new_viewed_items.foreach ((entry) => {
                // GLib.Idle.add_full (GLib.Priority.LOW, () => {
                this.manager.items.append (entry);
                // return false;
                // });
            }) ;

            if (this.pending_items_to_process.size > 0) {
                // there are pending items to be processed, it means, create the widget and so
                // Therefore, the pending actions need to be executed in the main gtk Thread
                GLib.Idle.add_full (GLib.Priority.LOW, () => {
                    // max items to process in the gtk draw thread
                    const int MAX = 10;
                    int index = 0;
                    while (index < MAX && this.pending_items_to_process.size > 0) {
                        PendingItem pending = this.pending_items_to_process.remove_at (0);
                        // debug ("drawing widget for file: %s", pending.file_name);

                        if (!pending.calculate_position) {
                            // managing previously saved items in settings
                            ItemManager item = new ItemManager (pending.file_name, pending.file, this.manager);
                            this.manager.items.append (item);
                            this.manager.get_view ().add_item (item.get_view (), pending.settings.x, pending.settings.y);
                        } else {
                            // new item to position
                            // we need to create one empty setting
                            ItemSettings is = new ItemSettings ();
                            int x = 0;
                            int y = 0;

                            // trying to get a position for the new items
                            this.mutex.lock () ;
                            if (this.pending_params_to_process.size > 0) {
                                Param fsp = this.pending_params_to_process.remove_at (0);
                                x = fsp.x;
                                y = fsp.y;
                            }
                            if (x == 0 && y == 0) {
                                // no desired position for the item, lets calculate a good position
                                if (this.grid == null) {
                                    // building the structure to see current gaps
                                    this.grid = FolderGrid.build_grid_structure (this.manager.get_view (), this.manager.get_settings ().arrangement_padding);
                                    // grid.print ();
                                }
                                Gdk.Point pos = grid.get_next_gap (this.manager.get_view (), is, this.manager.get_settings ().arrangement_padding, this.manager.is_vertical_arragement ());
                                is.x = pos.x;
                                is.y = pos.y;
                            } else {
                                is.x = x;
                                is.y = y;
                            }
                            this.mutex.unlock ();

                            is.name = pending.file_name;
                            this.manager.get_settings ().add_item (is);
                            ItemManager item = new ItemManager (pending.file_name, pending.file, this.manager);
                            this.manager.items.append (item);
                            this.manager.get_view ().add_item (item.get_view (), is.x, is.y);
                        }

                        index++;
                    }

                    // checking if we need to continue processing items in the idle thread
                    if (this.flag_restart || this.pending_items_to_process.size == 0) {
                        this.manager.get_settings ().save ();
                        this.manager.get_view ().refresh ();
                        if (this.manager.get_arrangement ().force_organization ()) {
                            this.manager.organize_panel_items ();
                        }
                        this.manager.get_view ().hide_loading ();
                        this.flag_running = false;
                        this.manager.on_sync_finished ();

                        // debug ("finished drawing");
                        debug (">>>>>>>>>>> END _sync_files for Panel: %s", this.manager.get_folder_name ());
                        return false;
                    } else {
                        // this.manager.get_view ().refresh ();
                        // debug ("lets continue drawing in the future");
                        return true;
                    }
                });
            } else {
                // nothing to process, the sync algorithm is finished
                this.manager.get_view ().hide_loading ();
                this.flag_running = false;
                this.manager.on_sync_finished ();
                debug (">>>>>>>>>>> END _sync_files for Panel: %s", this.manager.get_folder_name ());
            }
        }

        return true;
    }

    /**
     * @name pop_item_from_list
     * @description try to ind an item in a item list by the file get_name
     * @param string file_name the file name of the item
     * @param List<ItemManager> the list to search inside (reference)
     * @return ItemManager the itemmanager found, or null if none match
     */
    private ItemManager ? pop_item_from_list (string file_name, ref List <ItemManager> items) {
        foreach (var item in items) {
            if (item.get_file_name () == file_name) {
                items.remove (item);
                return item;
            }
        }
        return null;
    }

}
