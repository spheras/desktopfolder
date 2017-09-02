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
public class DesktopFolder.Item : Gtk.EventBox {

    //NOT SURE ABOUT THESE CONSTANTS!!! TODO!!!!!
    private int PADDING_X=13;
    private int PADDING_Y=41;

    private const int DEFAULT_WIDTH=48;
    private const int DEFAULT_HEIGHT=68;
    private const int DEFAULT_MAX_WIDTH=100;
    private const int MAX_CHARACTERS=25;

    private Gtk.Menu menu=null;
    public string fileName;
    private File file;
    private FolderWindow folder;
    private Gtk.Box container;
    private Gtk.Fixed fixed;
    private Gtk.Label label;
    private int offsetx;
    private int offsety;
    private int px;
    private int py;
    private int maxx;
    private int maxy;
    // higher values make movement more performant
    // lower values make movement smoother
    private const int SENSITIVITY = 10;

    //flag to know that the item has been moved
    private bool flagModified=false;

    //if the item is selected
    private bool selected;

    public signal void delete ();

    public Item(string fileName, File file, FolderWindow folder, Gtk.Fixed fixed){
        this.set_size_request(DEFAULT_WIDTH,DEFAULT_HEIGHT);
        this.get_style_context ().add_class ("df_item");

        //setting properties
        this.fixed=fixed;
        this.file=file;
        this.fileName=fileName;
        this.folder=folder;

        //we connect the enter and leave events
        this.enter_notify_event.connect (this.on_enter);
        this.leave_notify_event.connect(this.on_leave);
        this.button_press_event.connect(this.on_press);
        this.motion_notify_event.connect(this.on_motion);

        //we create the components to put inside the item (icon and label)
        this.container=new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        this.container.margin=0;
        this.container.set_size_request(DEFAULT_WIDTH,DEFAULT_HEIGHT);

        try {
            var fileInfo=file.query_info("standard::icon",FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            var icon=new Gtk.Image.from_gicon(fileInfo.get_icon(),Gtk.IconSize.DIALOG);
            icon.set_size_request(DEFAULT_WIDTH,DEFAULT_HEIGHT);
            icon.get_style_context ().add_class ("df_icon");
            this.label=new Gtk.Label (fileName);
            this.label.set_size_request(DEFAULT_WIDTH,20);
            this.label.get_style_context ().add_class ("df_label");
            this.checkEllipse(fileName);
            this.container.pack_start(icon,true,true);
            this.container.pack_end(label,true,true);
        }catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }

        //debug("packed:"+fileName);

        this.add(this.container);
    }

    public FileType get_file_type() {
        File file = File.new_for_path (this.folder.get_basePath()+"/"+this.fileName);
        return file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
    }

    public bool is_selected(){
        return this.selected;
    }

    public void select(){
        this.folder.unselect_all();
        this.selected=true;
        this.get_style_context ().add_class ("df_selected");
    }

    public void unselect(){
        this.selected=false;
        this.get_style_context ().remove_class ("df_selected");
    }

    public void rename(string newName){
        this.fileName=newName;
        this.label.set_label(newName);
        this.checkEllipse(newName);
    }

    private void checkEllipse(string name){
        if(name.length>MAX_CHARACTERS){
            this.label.set_ellipsize(Pango.EllipsizeMode.MIDDLE);
            this.set_size_request(DEFAULT_MAX_WIDTH,DEFAULT_WIDTH);
        }else{
            this.label.set_ellipsize(Pango.EllipsizeMode.NONE);
            this.set_size_request(DEFAULT_WIDTH,DEFAULT_WIDTH);
        }
    }

    private bool on_enter(Gdk.EventCrossing eventCrossing){
        this.get_style_context ().add_class ("df_item_over");
        //debug("enter item");
        return true;
    }

    private bool on_leave(Gdk.EventCrossing eventCrossing){
        this.get_style_context ().remove_class ("df_item_over");
        if(this.flagModified){
            ItemSettings is=this.folder.get_folder_settings().get_item(this.fileName);
            Gtk.Allocation allocation;
            this.get_allocation(out allocation);
             //HELP! don't know why these constants?? maybe padding??
            is.x=allocation.x - PADDING_X;
            is.y=allocation.y - PADDING_Y;
            this.folder.get_folder_settings().set_item(is);
            this.folder.get_folder_settings().save();
            this.flagModified=false;
        }
        //debug("leave item");
        return true;
    }

    private bool on_press(Gdk.EventButton event){
        //debug("press:%i",(int)event.button);
        if (event.type == Gdk.EventType.BUTTON_PRESS && event.button==Gdk.BUTTON_PRIMARY) {
            this.select();
            Gtk.Widget p = this.parent;
            // offset == distance of parent widget from edge of screen ...
            p.get_window().get_position(out this.offsetx, out this.offsety);
            //debug("offset:%i,%i",this.offsetx,this.offsety);
            // plus distance from pointer to edge of widget

            this.offsetx += (int)event.x+PADDING_X;
            this.offsety += (int)event.y+PADDING_Y;

            // maxx, maxy both relative to the parent
    		// note that we're rounding down now so that these max values don't get
    		// rounded upward later and push the widget off the edge of its parent.
            Gtk.Allocation pAllocation;
            p.get_allocation(out pAllocation);
            Gtk.Allocation thisAllocation;
            this.get_allocation(out thisAllocation);
    		this.maxx = RoundDownToMultiple(pAllocation.width - thisAllocation.width, SENSITIVITY);
    		this.maxy = RoundDownToMultiple(pAllocation.height - thisAllocation.height, SENSITIVITY);
        }else if(event.type == Gdk.EventType.@2BUTTON_PRESS){
            this.select();
            on_double_click();
        }else if(event.type==Gdk.EventType.BUTTON_PRESS && event.button==Gdk.BUTTON_SECONDARY){
            this.select();
            this.show_popup(event);
        }

        return true;
    }

    private void show_popup(Gdk.EventButton event){
        //debug("evento:%f,%f",event.x,event.y);
        //if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!
            this.menu = new Gtk.Menu ();

            Gtk.MenuItem item = new Gtk.MenuItem.with_label (_("Open"));
            item.activate.connect ((item)=>{
                this.on_double_click();
            });
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Cut"));
            item.activate.connect (this.cut_dialog);
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Copy"));
            item.activate.connect (this.copy_dialog);
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Rename"));
            item.activate.connect (this.rename_dialog);
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Delete"));
            item.activate.connect ((item)=>{
                this.delete_dialog();
            });
            item.show();
            menu.append (item);

            menu.show_all();
        //}

        menu.popup(
             null //parent menu shell
            ,null //parent menu item
            ,null //func
            ,event.button // button
            ,event.get_time() //Gtk.get_current_event_time() //time
            );
    }

    public void cut_dialog(Gtk.MenuItem item){
    }

    public void copy_dialog(Gtk.MenuItem item){

    }

    public bool is_folder(){
        bool isdir=true;
        FileType type=this.get_file_type();
        string path=this.folder.get_basePath()+"/"+this.fileName;
        if(type!=FileType.DIRECTORY){
            isdir=false;
        }
        return isdir;
    }

    public void delete_dialog(){
        string message=_("This will DELETE the folder '<b>"+this.fileName+"</b>' and ALL the files inside.Are you sure??!");
        FileType type=this.get_file_type();
        bool isdir=true;
        string path=this.folder.get_basePath()+"/"+this.fileName;
        if(type!=FileType.DIRECTORY){
            isdir=false;
            message=_("This will DELETE the file '<b>"+this.fileName+"</b>'.Are you sure??!");
        }

        Gtk.MessageDialog msg = new Gtk.MessageDialog (this.folder, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, message);
        msg.use_markup=true;
        msg.response.connect ((response_id) => {
            switch (response_id) {
				case Gtk.ResponseType.OK:
                    msg.destroy();
                    if(isdir){
                        message=_("SURE??? (Remember, I will delete everything inside this folder)");
                        msg = new Gtk.MessageDialog (this.folder, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, message);
                        msg.response.connect ((response_id) => {
                            switch (response_id) {
                				case Gtk.ResponseType.OK:
                                    msg.destroy();
                                    //lets delete the folder
                                    try{
                                        DesktopFolder.Util.recursive_delete(path);
                                        this.delete();
                                    }catch(Error error){
                                        stderr.printf ("Error: %s\n", error.message);
                                    }
                                    break;
                                default:
                                    msg.destroy();
                                    break;
                                    //uff
                            }
                        });
                        msg.show ();
                    }else{
                        try{
                            FileUtils.remove(path);
                            this.delete();
                        }catch(Error error){
                            stderr.printf ("Error: %s\n", error.message);
                        }
                    }
					break;
                default:
                    msg.destroy();
                    break;
                    //uff
            }
        });
        msg.show ();
    }

    private void rename_dialog(Gtk.MenuItem item){

        //building the dialog
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
            null,
            this.folder, //parent
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT, //flags
            _("_OK"),Gtk.ResponseType.OK, //response OK
            _("_CANCEL"),Gtk.ResponseType.CANCEL //response CANCEL
            );

        dialog.get_style_context ().add_class ("df_dialog");
        dialog.set_decorated(false);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("df_rename");
        grid.column_spacing = 12;

            var description=new Gtk.Label (_("Enter the new name"));
            grid.attach(description,0,0,1,1);
            var entry = new Gtk.Entry();
            entry.activate.connect(()=>{
                dialog.response(Gtk.ResponseType.OK);
            });
            entry.set_text (this.fileName);
            grid.attach (entry, 0, 1, 1, 1);

        dialog.get_content_area().pack_end(grid, true, true, 20);

        dialog.show_all();
        int result=dialog.run();
        var newName = entry.get_text();
        dialog.destroy();

        //renaming
        if(result==Gtk.ResponseType.OK && newName!=this.fileName){
            /*
            var oldName=this.folderName;
            var oldPath=this.get_basePath();
            this.folderName=newName;
            var newPath=this.get_basePath();
            try{
                FileUtils.rename(oldPath, newPath);
                var directory = File.new_for_path (newPath);
                if(directory.query_exists ()){
                    this.set_title(this.folderName);
                    //forcing to reload settings
                    this.load_folderSettings();
                    this.monitorFolder();
                }else{
                    //we can't rename
                    this.folderName=oldName;
                }
            }catch(Error e){
                stderr.printf ("Error: %s\n", e.message);
                //we can't rename
                this.folderName=oldName;
            }
            */
        }

    }

    private void on_double_click(){
        //debug("doble click! %s",this.fileName);
        //we must launch the file/folder
        try {
            var command="xdg-open \""+this.folder.get_basePath()+"/"+this.fileName+"\"";
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);
        } catch (Error e) {
            warning (e.message);
        }
    }

    private bool on_motion(Gdk.EventMotion event){
        this.flagModified=true;
        // x_root,x_root relative to screen
    	// x,y relative to parent (fixed widget)
    	// px,py stores previous values of x,y

    	// get starting values for x,y
    	int x = (int)event.x_root - this.offsetx;
    	int y = (int)event.y_root - this.offsety;

        // make sure the potential coordinates x,y:
    	//   1) will not push any part of the widget outside of its parent container
    	//   2) is a multiple of Sensitivity
    	x = RoundToNearestMultiple(int.max(int.min(x, this.maxx), 0), SENSITIVITY);
    	y = RoundToNearestMultiple(int.max(int.min(y, this.maxy), 0), SENSITIVITY);
    	if (x != this.px || y != this.py) {
    		this.px = x;
    		this.py = y;
            this.fixed.move(this,x,y);
    	}

    	return true;
    }

    inline static int RoundDownToMultiple( int i,  int m)
    {
    	return i/m*m;
    }

    inline static int RoundToNearestMultiple( int i, int m)
    {
    	if (i % m > (double)m / 2.0d)
    		return (i/m+1)*m;
    	return i/m*m;
    }

    public string get_fileName(){
        return this.fileName;
    }

    public bool is_recent_uri_scheme(){
        return true;
    }

    public string get_display_target_uri(){
        File file = File.new_for_path (this.folder.get_basePath()+"/"+this.fileName);
        var fileInfo=file.query_info(FileAttribute.STANDARD_TARGET_URI,FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
        var uri=fileInfo.get_attribute_as_string(FileAttribute.STANDARD_TARGET_URI);

            return "";
    }

    public File get_target_location(){
        File file = File.new_for_path (this.folder.get_basePath()+"/"+this.fileName);
        return file;
    }
}
