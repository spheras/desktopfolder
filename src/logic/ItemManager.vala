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

    /**
    * @constructor
    * @param string file_name the name of the file/folder that this item represents
    * @param File file the GLib File object for the file associated with this item
    * @param FolderManager folder the folder parent
    */
    public ItemManager(string file_name, File file, FolderManager folder){
        this.file_name=file_name;
        this.file=file;
        this.folder=folder;
        this.selected=false;
        this.view=new ItemView(this);
    }

    /**
    * @name is_selected
    * @description check if the item is selected or not
    * @return bool true->the item is selected
    */
    public bool is_selected(){
        return this.selected;
    }

    /**
    * @name is_link
    * @description check whether the item is a link to other folder/file or not
    * @return {bool} true-> yes it is a link
    */
    public bool is_link(){
        var file=this.get_file();
        var path=file.get_path();
        return FileUtils.test (path, FileTest.IS_SYMLINK);
    }

    /**
    * @name is_executable
    * @description check whether the item is a executable
    * @return {bool} true-> yes it is a executable
    */
    public bool is_executable(){
        var file=this.get_file();
        var path=file.get_path();
        if(!this.is_folder()) {
            return FileUtils.test (path, FileTest.IS_EXECUTABLE);
        }else{
            return false;
        }
    }

    /**
    * @name select
    * @description the item is selected
    */
    public void select(){
        this.selected=true;
    }

    /**
    * @name unselect
    * @description unselect the item
    */
    public void unselect(){
        this.selected=false;
    }

    /**
    * @name change_icon
    * @description change the icon for the item
    */
    public void change_icon(string filename){
        ItemSettings is=this.folder.get_settings().get_item(this.get_file_name());
        is.icon=filename;
        this.folder.get_settings().set_item(is);
        this.folder.get_settings().save();
        this.view.refresh_icon();
    }


    /**
    * @name get_settings
    * @description return the settings of the item
    * @return ItemSettings the settings
    */
    public ItemSettings get_settings() {
        return this.folder.get_settings().get_item(this.get_file_name());
    }

    /**
    * @name rename
    * @description rename the current item (file or folder)
    * @param new_name string the new name for this item
    * @return bool true->the operation was succesfull
    */
    public bool rename(string new_name){
        if(new_name.length<=0){
            return false;
        }
        string old_name=this.file_name;
        string old_path=this.get_absolute_path();
        this.file_name=new_name;
        string new_path=this.folder.get_absolute_path()+"/"+new_name;

        try{
            this.folder.get_settings().rename(old_name,new_name);
            this.folder.get_settings().save();

            FileUtils.rename(old_path, new_path);
            this.file=File.new_for_path (new_path);

            debug("try13");
            return false;
        }catch(Error e){
            debug("try-error1");
            //we can't rename, undoing
            this.file_name=old_name;
            ItemSettings is=this.folder.get_settings().get_item(new_name);
            if(is==null) {
                is=this.folder.get_settings().get_item(old_name);
            }
            this.folder.get_settings().set_item(is);
            is.name=old_name;
            this.folder.get_settings().save();

            //showing the error
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog("Error",e.message);

            return false;
        }
    }

    /**
    * @name save_position
    * @description save a new position for the item icon at the folder settings
    * @param int x the x position
    * @param int y the y position
    */
    public void save_position(int x, int y){
        //the settings need to be modified
        ItemSettings is=this.folder.get_settings().get_item(this.file_name);
        Gtk.Allocation allocation;
        this.view.get_allocation(out allocation);
         //HELP! don't know why these constants?? maybe padding??
        is.x=allocation.x - ItemView.PADDING_X;
        is.y=allocation.y - ItemView.PADDING_Y;
        this.folder.get_settings().set_item(is);
        this.folder.get_settings().save();
    }

    /**
    * @name is_desktop_file
    * @description check whether the file is a desktop file or not
    * @return true->yes, it is
    */
    public bool is_desktop_file(){
        int index=this.file_name.index_of(".desktop",0);
        if(index>0){
            return true;
        }
        return false;
    }

    /**
    * @name execute
    * @description execute the file associated with this item
    */
    public void execute(){
        //we must launch the file/folder
        try {
            if(this.is_desktop_file()){
                GLib.DesktopAppInfo desktopApp=new GLib.DesktopAppInfo.from_filename(this.get_absolute_path());
                desktopApp.launch_uris(null,null);
            }else if(this.is_executable()){
                var command="\""+this.get_absolute_path()+"\"";
                var appinfo = AppInfo.create_from_commandline(command,null,AppInfoCreateFlags.NONE);
                appinfo.launch_uris (null, null);
            }else{
                var command="xdg-open \""+this.folder.get_absolute_path()+"/"+this.file_name+"\"";
                var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
                appinfo.launch_uris (null, null);
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog("Error",e.message);
        }
    }

    /**
    * @name get_view
    * @description return the view of this manager
    * @return ItemView
    */
    public ItemView get_view(){
        return this.view;
    }

    /**
    * @name get_file_name
    * @description return the file name associated with this item
    * @return string the file name
    */
    public string get_file_name(){
        return this.file_name;
    }

    /**
    * @name get_file
    * @description return the Glib.File associated
    * @return File the file associated
    */
    public GLib.File get_file(){
        return this.file;
    }

    /**
    * @name get_absolute_path
    * @description return the absolute path to this item
    * @return string the absolute path
    */
    public string get_absolute_path(){
        return this.get_file().get_path();
    }

    /**
    * @name get_file_type
    * @description return the FileType of this item
    * @return FileType
    */
    public FileType get_file_type() {
        File file = this.get_file();
        return file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
    }

    /**
    * @name is_folder
    * @description check whether the item is a folder or not
    * @return bool true->the item is a folder
    */
    public bool is_folder(){
        return FileUtils.test (this.get_absolute_path(), FileTest.IS_DIR);
    }

    /**
    * @name cut
    * @description cut the file to the clipboard
    */
    public void cut(){
        Clipboard.ClipboardManager cm=Clipboard.ClipboardManager.get_for_display ();
        List<Clipboard.ClipboardFile> items=new List<Clipboard.ClipboardFile>();
        items.append(this);
        cm.cut_files(items);
    }

    /**
    * @name copy
    * @description copy the file to the clipboard
    */
    public void copy(){
        Clipboard.ClipboardManager cm=Clipboard.ClipboardManager.get_for_display ();
        List<Clipboard.ClipboardFile> items=new List<Clipboard.ClipboardFile>();
        items.append(this);
        cm.copy_files(items);
    }

    /**
    * @name delete
    * @description delete the file or folder associated
    */
    public void delete(){
        try{
            if(this.is_folder()){
                File file=File.new_for_path (this.get_absolute_path());
                file.trash();
            }else{
                File file=File.new_for_path (this.get_absolute_path());
                file.trash();
                //FileUtils.remove(this.get_absolute_path());
            }
            this.on_delete();
        }catch(Error e){
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog("Error",e.message);
        }
    }


    //---------------------------------------------------------------------------------------
    //---------------------------DndView Implementation--------------------------------------
    //---------------------------------------------------------------------------------------

    /**
    * @name get_widget
    * @description return the widget associated with this view
    * @return Widget the widget
    */
    public Gtk.Widget get_widget(){
        return this.view;
    }

    /**
    * @name get_application_window
    * @description return the application window of this view, needed for drag operations
    * @return ApplicationWindow
    */
    public Gtk.ApplicationWindow get_application_window(){
        return this.folder.get_view();
    }

    /**
    * @name get_file_at
    * @name get the file at the position x, y
    * @return File
    */
    public GLib.File get_file_at(int x, int y){
        return this.get_file();
    }

    /**
    * @name is_writable
    * @description indicates if the file linked by this view is writable or not
    * @return bool
    */
    public bool is_writable(){
        //TODO
        return true;
    }

    /**
    * @name get_target_location
    * @description return the target File that represents this view
    * @return File the file target of this view
    */
    public GLib.File get_target_location(){
        return this.get_file();
    }

    /**
    * @name is_recent_uri_scheme
    * @description check whether the File is a recent uri scheme?
    * @return bool
    */
    public bool is_recent_uri_scheme(){
        return true;
    }

    /**
    * @name get_display_target_uri
    * @description return the target uri of this view
    * @return string the target uri
    */
    public string get_display_target_uri(){
        return DragnDrop.Util.get_display_target_uri(this.get_file());
    }

    //---------------------------------------------------------------------------------------
    //---------------------------**********************--------------------------------------
    //---------------------------------------------------------------------------------------

    /**
    * @name get_folder
    * @description return the folder that contains this item
    * @return FolderManaget that contains the item.
    */
    public FolderManager get_folder(){
        return this.folder;
    }
}
