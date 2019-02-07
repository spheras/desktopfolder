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
 * Item Manager that represents an Icon of a File or Folder
 */
public class DesktopFolder.ItemManager : Object, DragnDrop.DndView, Clipboard.ClipboardFile {
    /** file name associated with this item */
    private string file_name;
    /** the File object associated with the item */
    private File file;
    /** the folder manager where this item is inserted */
    private FolderManager folder;
    /** whether the item is selected */
    private bool selected;
    /** the view associated with this manager */
    private ItemView view;
    /** drag and drop behaviour for this folder */
    private DragnDrop.DndBehaviour dnd_behaviour = null;
    /** flag to indicate that the file doesn't exist.. and need to be rechecked */
    private bool flag_dont_exist                 = false;

    /**
     * @constructor
     * @param string file_name the name of the file/folder that this item represents
     * @param File file the GLib File object for the file associated with this item
     * @param FolderManager folder the folder parent
     */
    public ItemManager (string file_name, File file, FolderManager folder) {
        this.file_name = file_name;
        this.file      = file;
        // checking if the file still exists... we need to check following symlinks!
        if (!GLib.FileUtils.test (file.get_path (), GLib.FileTest.EXISTS)) {
            this.flag_dont_exist = true;
        } else {
            this.flag_dont_exist = false;
        }
        this.folder        = folder;
        this.selected      = false;
        this.view          = new ItemView (this);
        this.dnd_behaviour = new DragnDrop.DndBehaviour (this, true, this.is_folder ());
    }

    /**
     * @name set_file
     * @description set the file of the item
     * @param Glib.File file the file associated with the item
     */
    public void set_file (File file) {
        this.file = file;
    }

    /**
     * @name is_selected
     * @description check if the item is selected or not
     * @return bool true->the item is selected
     */
    public bool is_selected () {
        return this.selected;
    }

    /**
     * @name check_exist_cached
     * @description check if the file exist, but doesn't check fiscally, to avoid checking a lot of times
     * @return {bool} true->, yes the file exist
     */
    public bool check_exist_cached () {
        return !this.flag_dont_exist;
    }

    /**
     * @name recheck_existence
     * @description recheck if the file exist
     */
    public void recheck_existence () {
        if (this.flag_dont_exist) {
            // we need to recheck if the file exist now
            // checking if the file still exists... we need to check following symlinks!
            if (GLib.FileUtils.test (this.get_file ().get_path (), GLib.FileTest.EXISTS)) {
                if (this.flag_dont_exist) {
                    this.flag_dont_exist = false;
                    this.view.refresh_icon ();
                }
            }
        }
    }

    /**
     * @name is_link
     * @description check whether the item is a link to other folder/file or not
     * @return {bool} true-> yes it is a link
     */
    public bool is_link () {
        var file = this.get_file ();
        var path = file.get_path ();
        return FileUtils.test (path, FileTest.IS_SYMLINK);
    }

    /**
     * @name is_executable
     * @description check whether the item is a executable
     * @return {bool} true-> yes it is a executable
     */
    public bool is_executable () {
        var file = this.get_file ();
        var path = file.get_path ();
        if (!this.is_folder ()) {
            return FileUtils.test (path, FileTest.IS_EXECUTABLE);
        } else {
            return false;
        }
    }

    /**
     * @name show_view
     * @description show the icon
     */
    public void show_view () {
        this.view.show_all ();
        this.view.fade_in ();
    }

    /**
     * @name hide_view
     * @description hide the icon
     */
    public void hide_view () {
        this.view.fade_out ();
        Timeout.add (160, () => {
            this.view.hide ();
            return false;
        });
    }

    /**
     * @name select
     * @description the item is selected
     */
    public void select_only () {
        this.selected = true;
        this.get_folder ().set_selected_item (this.view);
    }

    /**
     * @name select_add
     * @desription add this istem as selected
     */
    public void select_add () {
        this.selected = true;
        this.get_folder ().add_selected_item (this.view);
    }

    /**
     * @name unselect
     * @description unselect the item
     */
    public void unselect () {
        this.selected = false;
        this.get_folder ().remove_selected_item (this.view);
    }

    /**
     * @name change_icon
     * @description change the icon for the item
     */
    public void change_icon (string filename) {
        ItemSettings is = this.folder.get_settings ().get_item (this.get_file_name ());
        is.icon         = filename;
        this.folder.get_settings ().set_item (is);
        this.folder.get_settings ().save ();
        this.view.refresh_icon ();
    }

    /**
     * @name get_settings
     * @description return the settings of the item
     * @return ItemSettings the settings
     */
    public ItemSettings get_settings () {
        return this.folder.get_settings ().get_item (this.get_file_name ());
    }

    /**
     * @name save_settings
     * @description save the settings for the item
     * @param {ItemSettings} is the new settings
     */
    public void save_settings (ItemSettings is) {
        this.folder.get_settings ().set_item (is);
        this.folder.get_settings ().save ();
    }

    /**
     * @name rename
     * @description rename the current item (file or folder)
     * @param new_name string the new name for this item
     * @return bool true->the operation was succesfull
     */
    public bool rename (string new_name) {
        if (new_name.length <= 0) {
            return false;
        }
        string old_name = this.file_name;
        string old_path = this.get_absolute_path ();
        this.file_name = new_name;
        string new_path = this.folder.get_absolute_path () + "/" + new_name;

        try {
            this.folder.get_settings ().rename (old_name, new_name);
            this.folder.get_settings ().save ();

            FileUtils.rename (old_path, new_path);
            this.file = File.new_for_path (new_path);

            return true;
        } catch (Error e) {
            // we can't rename, undoing
            this.file_name  = old_name;
            ItemSettings is = this.folder.get_settings ().get_item (new_name);
            if (is == null) {
                is = this.folder.get_settings ().get_item (old_name);
            }
            this.folder.get_settings ().set_item (is);
            is.name = old_name;
            this.folder.get_settings ().save ();

            // showing the error
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);

            return false;
        }
    }

    /**
     * @name save_position
     * @description save a new position for the item icon at the folder settings
     */
    public void save_current_position () {
        // the settings need to be modified
        ItemSettings is = this.folder.get_settings ().get_item (this.file_name);
        Gtk.Allocation allocation;
        this.view.get_allocation (out allocation);
        // HELP! don't know why these constants?? maybe padding??
        is.x = allocation.x; // - ItemView.PADDING_X - ItemView.PADDING_X;
        is.y = allocation.y; // - ItemView.PADDING_Y;
        this.folder.get_settings ().set_item (is);
        this.folder.get_settings ().save ();
    }

    /**
     * @name is_desktop_file
     * @description check whether the file is a desktop file or not
     * @return true->yes, it is
     */
    public bool is_desktop_file () {
        int index = this.file_name.index_of (".desktop", 0);
        if (index > 0) {
            return true;
        }
        return false;
    }

    /**
     * @name is_openable_contenttype
     * @description check whether the item file can be executable or not (if not, could be opened instead)
     */
    public bool is_openable_contenttype () {
        bool   uncertain    = false;
        string content_type = GLib.ContentType.guess (this.file_name, null, out uncertain);
        bool   executable   = GLib.ContentType.can_be_executable (content_type);
        debug ("content_type: %s   --  %s", content_type, (executable ? "true" : "false"));
        if (executable) {
            return this.is_executable ();
        } else if (content_type == "application/octet-stream") {
            return this.is_executable ();
        }
        return false;
    }

    /**
     * @name open_in_terminal
     * @description open the folder item in a terminal (it is only called by folder items, see popup)
     * @param string path the path of the folder to open
     */
    public void open_in_terminal (string path) {
        try {
            Environment.set_current_dir (path);
            Process.spawn_command_line_async ("x-terminal-emulator --working-directory \"" + path + "\"");
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name execute
     * @description execute the file associated with this item
     */
    public void execute () {
        // we must launch the file/folder
        try {
            if (this.is_desktop_file ()) {
                GLib.DesktopAppInfo desktopApp = new GLib.DesktopAppInfo.from_filename (this.get_absolute_path ());
                desktopApp.launch_uris (null, null);
            } else if (this.is_openable_contenttype ()) {
                var command = "\"" + this.get_absolute_path () + "\"";
                var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.NONE);
                appinfo.launch_uris (null, null);
            } else {
                var command = "xdg-open \"" + this.folder.get_absolute_path () + "/" + this.file_name + "\"";
                var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
                appinfo.launch_uris (null, null);
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    public void openwith (string filepath) {
        // get content type
        File   file              = File.new_for_path (filepath);
        string file_content_type = "";
        try {
            file_content_type = file.query_info (
                "*", FileQueryInfoFlags.NONE
                ).get_content_type ();
        } catch (Error e) {
            file_content_type = "Unknown";
        }
        // open dialog
        new DesktopFolder.Dialogs.OpenWith (
            file_content_type, filepath
        );
    }

    public void show_info (string filepath) {
        string fname = get_file_name ();
        string fpath = get_absolute_path ();
        new DesktopFolder.Dialogs.ShowInfo (fpath, fname);
    }

    /**
     * @name get_view
     * @description return the view of this manager
     * @return ItemView
     */
    public ItemView get_view () {
        return this.view;
    }

    /**
     * @name get_file_name
     * @description return the file name associated with this item
     * @return string the file name
     */
    public string get_file_name () {
        return this.file_name;
    }

    /**
     * @name get_file
     * @description return the Glib.File associated
     * @return File the file associated
     */
    public GLib.File get_file () {
        return this.file;
    }

    /**
     * @name get_absolute_path
     * @description return the absolute path to this item
     * @return string the absolute path
     */
    public string get_absolute_path () {
        return this.get_file ().get_path ();
    }

    /**
     * @name get_file_type
     * @description return the FileType of this item
     * @return FileType
     */
    public FileType get_file_type () {
        File file = this.get_file ();
        return file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
    }

    /**
     * @name is_folder
     * @description check whether the item is a folder or not
     * @return bool true->the item is a folder
     */
    public bool is_folder () {
        return FileUtils.test (this.get_absolute_path (), FileTest.IS_DIR);
    }

    /**
     * @name cut
     * @description cut the file to the clipboard
     */
    public void cut () {
        Clipboard.ClipboardManager     cm    = Clipboard.ClipboardManager.get_for_display ();
        List <Clipboard.ClipboardFile> items = new List <Clipboard.ClipboardFile> ();
        Gee.List <ItemView> selecteds        = this.folder.get_selected_items ();
        for (int i = 0; i < selecteds.size; i++) {
            items.append (selecteds.@get (i).get_manager ());
        }
        cm.cut_files (items);
    }

    /**
     * @name copy
     * @description copy the file to the clipboard
     */
    public void copy () {
        Clipboard.ClipboardManager     cm    = Clipboard.ClipboardManager.get_for_display ();
        List <Clipboard.ClipboardFile> items = new List <Clipboard.ClipboardFile> ();
        Gee.List <ItemView> selecteds        = this.folder.get_selected_items ();
        for (int i = 0; i < selecteds.size; i++) {
            items.append (selecteds.@get (i).get_manager ());
        }
        cm.copy_files (items);
    }

    /**
     * @name trash
     * @description trash the file or folder associated
     */
    public void trash () {
        if (this.folder.is_sync_running ()) {
            return;
        }

        try {
            this.unselect ();
            if (this.is_folder ()) {
                File file = File.new_for_path (this.get_absolute_path ());
                file.trash ();
            } else {
                File file = File.new_for_path (this.get_absolute_path ());
                file.trash ();
                // FileUtils.remove(this.get_absolute_path());
            }
            this.on_delete ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name trash_selected
     * @descriptionsend to trash all the selected files
     */
    public void trash_selected () {
        Gee.List <ItemView> selecteds = this.get_folder ().get_selected_items ();
        ItemView[]          to_delete = selecteds.to_array ();
        for (int i = 0; i < to_delete.length; i++) {
            ItemView view = to_delete[i];
            if (view != null) {
                view.get_manager ().trash ();
            }
        }
    }

    // ---------------------------------------------------------------------------------------
    // ---------------------------DndView Implementation--------------------------------------
    // ---------------------------------------------------------------------------------------

    public void on_drag_motion () {
        // we force the opened folder icon
        this.view.force_opened_folder_icon ();
    }

    public void on_drag_leave () {
        // restoring the normal icon
        this.view.refresh_icon ();
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
        return this.folder.get_view ();
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
     * @name is_writable
     * @description indicates if the file linked by this view is writable or not
     * @return bool
     */
    public bool is_writable () {
        // TODO
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
        return this.view.get_image ();
    }

    /**
     * @overrided
     */
    public void on_drag_end () {
        this.view.on_drag_end ();
    }

    /**
     * @overrided
     */
    public DragnDrop.DndView[] get_all_selected_views () {
        Gee.List <ItemView> selected_views = this.get_folder ().get_selected_items ();
        DragnDrop.DndView[] result         = new DragnDrop.DndView[selected_views.size];
        for (int i = 0; i < selected_views.size; i++) {
            ItemView view = selected_views.@get (i);
            if (view != null) {
                result[i] = (DragnDrop.DndView)selected_views.@get (i).get_manager ();
            }
        }
        return result;
    }

    // ---------------------------------------------------------------------------------------
    // ---------------------------**********************--------------------------------------
    // ---------------------------------------------------------------------------------------

    /**
     * @name get_folder
     * @description return the folder that contains this item
     * @return FolderManaget that contains the item.
     */
    public FolderManager get_folder () {
        return this.folder;
    }

}
