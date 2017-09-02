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
public class DesktopFolder.FolderWindow : Gtk.Window {

    private string folderName=null;
    private Gtk.Fixed container=null;
    private FileMonitor monitor=null;
    private FolderSettings settings=null;
    private List<Item> items=null;
    private Gtk.Menu menu=null;
    private Gtk.Clipboard clipboard {get; set;}

    construct {
        set_keep_below (false);
        stick ();
        this.hide_titlebar_when_maximized = false;
        set_type_hint(Gdk.WindowTypeHint.MENU);
    }

    public FolderWindow (Gtk.Application application, string folderName) {
        Object (application: application,
                icon_name: "org.spheras.desktopfolder",
                resizable: true,
                decorated:true,
                title: (folderName),
                deletable:false,
                height_request: 100,
                width_request: 100);

        this.get_style_context ().add_class ("df_folder");

        Gdk.Display display = this.get_display();
        this.clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);

        this.folderName=folderName;
        this.container=new Gtk.Fixed();
        add(this.container);
        this.enter_notify_event.connect (() => {
            //debug("enter folder");
            return true;
        });

        this.load_folderSettings();
        if(this.settings.w>0){
            this.resize(this.settings.w,this.settings.h);
            this.move(this.settings.x,this.settings.y);
        }
        this.get_style_context ().add_class (this.settings.bgcolor);
        this.get_style_context ().add_class (this.settings.fgcolor);

        syncFiles(0,0);

        //finally, we start monitoring the folder
        this.monitorFolder();
        this.configure_event.connect (this.on_configure);
        this.button_press_event.connect(this.on_press);
        this.key_release_event.connect(this.on_key);
    }


    private bool on_configure(Gdk.EventConfigure event){
        if(event.type==Gdk.EventType.CONFIGURE){
            //debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            this.settings.x=event.x;
            this.settings.y=event.y;
            this.settings.w=event.width;
            this.settings.h=event.height;
            this.settings.save();
        }
        return false;
    }

    private bool on_key(Gdk.EventKey event){
        int key=(int)event.keyval;
        //debug("event key %d",key);
        const int DELETE_KEY=65535;
        if(event.type==Gdk.EventType.KEY_RELEASE && key==DELETE_KEY){ //DELETE KEY
            var children = this.container.get_children ();
            for(int i=0;i<children.length();i++){
                Item element=(Item) children.nth_data(i);
                if(element.is_selected()){
                    element.delete_dialog();
                    return true;
                }
            }
            return false;
        }
        return false;
    }

    private bool on_press(Gdk.EventButton event){
        //debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button==Gdk.BUTTON_SECONDARY)) {
            this.show_popup(event);
            return true;
        }
        return false;
    }

    private void show_popup(Gdk.EventButton event){
        //debug("evento:%f,%f",event.x,event.y);
        //if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!
            this.menu = new Gtk.Menu ();

            string HEAD_TAGS_COLORS[3] = { null, "#ffffff", "#000000"};
            string HEAD_TAGS_COLORS_CLASS[3] = { "headless", "light", "dark"};
            string BODY_TAGS_COLORS[10] = { null, "#fce94f", "#fcaf3e", "#997666", "#8ae234", "#729fcf", "#ad7fa8", "#ef2929", "#d3d7cf", "#000000" };
            string BODY_TAGS_COLORS_CLASS[10] = { "transparent", "yellow", "orange", "brown", "green", "blue", "purple", "red", "gray", "black" };

            Gtk.MenuItem item = new MenuItemColor(HEAD_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect((ncolor)=>{
                string color=HEAD_TAGS_COLORS_CLASS[ncolor];
                for(int i=0;i<HEAD_TAGS_COLORS_CLASS.length;i++){
                    string scolor=HEAD_TAGS_COLORS_CLASS[i];
                    this.get_style_context().remove_class (scolor);
                }
                this.get_style_context ().add_class (color);
                this.settings.fgcolor=color;
                this.settings.save();
                //debug("color:%d,%s",ncolor,color);
            });
            item.show();
            menu.append (item);

            item = new MenuItemColor(BODY_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect((ncolor)=>{
                string color=BODY_TAGS_COLORS_CLASS[ncolor];
                for(int i=0;i<BODY_TAGS_COLORS_CLASS.length;i++){
                    string scolor=BODY_TAGS_COLORS_CLASS[i];
                    this.get_style_context ().remove_class (scolor);
                }
                this.get_style_context ().add_class (color);
                this.settings.bgcolor=color;
                this.settings.save();
                //debug("color:%d,%s",ncolor,color);
            });
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("New Folder"));
            item.activate.connect ((item)=>{
                    this.new_folder(item, (int)event.x, (int)event.y);
            });
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("New Text File"));
            item.activate.connect ((item)=>{
                    this.new_text_file(item, (int)event.x, (int)event.y);
            });
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Rename Folder"));
            item.activate.connect (rename_folder);
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("Delete Folder"));
            item.activate.connect (delete_folder);
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            item = new Gtk.MenuItem.with_label (_("About"));
            item.activate.connect ((item)=>{
                this.show_about();
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

    private void show_about(){
    	string[] authors = {"José Amuedo - spheras"};
    	// Use property names as keys
    	Gtk.show_about_dialog (this,
    		program_name: "Desktop-Folder",
    		copyright: "GNU General Public License v3.0",
    		authors: authors,
    		website: "https://github.com/spheras/Desktop-Folder",
    		website_label: "Desktop-Folder Github Place.");
    }

    private void new_text_file(Gtk.MenuItem item, int x, int y){
        //building the dialog
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
            null,
            this, //parent
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT, //flags
            _("_OK"),Gtk.ResponseType.OK, //response OK
            _("_CANCEL"),Gtk.ResponseType.CANCEL //response CANCEL
            );

        dialog.get_style_context ().add_class ("df_dialog");
        dialog.set_decorated(false);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("df_rename");
        grid.column_spacing = 12;

            var description=new Gtk.Label (_("Enter the name for the File"));
            grid.attach(description,0,0,1,1);
            var entry = new Gtk.Entry();
            entry.activate.connect(()=>{
                dialog.response(Gtk.ResponseType.OK);
            });
            entry.set_text ("new.txt");
            grid.attach (entry, 0, 1, 1, 1);

        dialog.get_content_area().pack_end(grid, true, true, 20);

        dialog.show_all();
        int result=dialog.run();
        var name = entry.get_text();
        dialog.destroy();

        //creating the folder
        if(result==Gtk.ResponseType.OK && name!=""){
            this.monitor.cancel();
            try {
                var command="touch \""+this.get_basePath()+"/"+name+"\"";
                var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
                appinfo.launch_uris (null, null);
            } catch (Error e) {
                warning (e.message);
            }
            this.syncFiles(x,y);
            this.monitorFolder();
        }
    }

    private void new_folder(Gtk.MenuItem item, int x, int y){
        //building the dialog
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
            null,
            this, //parent
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT, //flags
            _("_OK"),Gtk.ResponseType.OK, //response OK
            _("_CANCEL"),Gtk.ResponseType.CANCEL //response CANCEL
            );

        dialog.get_style_context ().add_class ("df_dialog");
        dialog.set_decorated(false);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("df_rename");
        grid.column_spacing = 12;

            var description=new Gtk.Label (_("Enter the name for the folder"));
            grid.attach(description,0,0,1,1);
            var entry = new Gtk.Entry();
            entry.activate.connect(()=>{
                dialog.response(Gtk.ResponseType.OK);
            });
            entry.set_text ("new folder");
            grid.attach (entry, 0, 1, 1, 1);

        dialog.get_content_area().pack_end(grid, true, true, 20);

        dialog.show_all();
        int result=dialog.run();
        var name = entry.get_text();
        dialog.destroy();

        //creating the folder
        if(result==Gtk.ResponseType.OK && name!=""){
            this.monitor.cancel();
            DirUtils.create(this.get_basePath()+"/"+name,0755);
            this.syncFiles(x,y);
            this.monitorFolder();
        }
    }

    private void delete_folder(Gtk.MenuItem item){
        string message=_("This will DELETE the folder and ALL the files inside. Are you sure??!");
        Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, message);
        msg.response.connect ((response_id) => {
            switch (response_id) {
				case Gtk.ResponseType.OK:
                    msg.destroy();
                    message=_("SURE??? (Remember, I will delete everything inside this folder)");
                    msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING, Gtk.ButtonsType.OK_CANCEL, message);
                    msg.response.connect ((response_id) => {
                        switch (response_id) {
            				case Gtk.ResponseType.OK:
                                msg.destroy();
                                //lets delete
                                try{
                                    DesktopFolder.Util.recursive_delete(this.get_basePath());
                                    this.finish();
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
					break;
                default:
                    msg.destroy();
                    break;
                    //uff
            }
        });
        msg.show ();
    }

    private void rename_folder(Gtk.MenuItem item){

        //building the dialog
        Gtk.Dialog dialog = new Gtk.Dialog.with_buttons(
            null,
            this, //parent
            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT, //flags
            _("_OK"),Gtk.ResponseType.OK, //response OK
            _("_CANCEL"),Gtk.ResponseType.CANCEL //response CANCEL
            );

        dialog.get_style_context ().add_class ("df_dialog");
        dialog.set_decorated(false);

        var grid = new Gtk.Grid ();
        grid.get_style_context ().add_class ("df_rename");
        grid.column_spacing = 12;

            var description=new Gtk.Label (_("Enter the new name for the folder"));
            grid.attach(description,0,0,1,1);
            var entry = new Gtk.Entry();
            entry.activate.connect(()=>{
                dialog.response(Gtk.ResponseType.OK);
            });
            entry.set_text (this.folderName);
            grid.attach (entry, 0, 1, 1, 1);

        dialog.get_content_area().pack_end(grid, true, true, 20);

        dialog.show_all();
        int result=dialog.run();
        var newName = entry.get_text();
        dialog.destroy();

        //renaming
        if(result==Gtk.ResponseType.OK && newName!=this.folderName){
            var oldName=this.folderName;
            var oldPath=this.get_basePath();
            this.folderName=newName;
            var newPath=this.get_basePath();
            try{
                this.settings.name=this.folderName;
                this.settings.save();
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
                this.settings.name=this.folderName;
                this.settings.save();
            }
        }

    }

    private void finish(){
        this.monitor.cancel();
        this.close();
    }

    public void unselect_all(){
        foreach (var item in this.items) {
            item.unselect();
        }
    }

    private void monitorFolder(){
        try{
            if(this.monitor!=null){
                this.monitor.cancel();
            }
            var basePath=Environment.get_home_dir ()+"/Desktop/"+this.folderName+"/";
            File directory = File.new_for_path (basePath);
            this.monitor = directory.monitor_directory (FileMonitorFlags.SEND_MOVED,null);
            this.monitor.rate_limit = 100;
            stdout.printf ("Monitoring: %s\n", directory.get_path ());
            this.monitor.changed.connect(this.directory_changed);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    private void directory_changed (GLib.File src, GLib.File? dest, FileMonitorEvent event) {
        string old_filename=src.get_basename ();
        if(old_filename==".desktopfolder"){
            //debug("just changed the settings file");
        }else{
            if(dest!=null){
                string new_filename=dest.get_basename ();
                //debug("something renamed");
                this.settings.rename(old_filename,new_filename);
                this.settings.save();

                var children = this.container.get_children ();
                for(int i=0;i<children.length();i++){
                    Item element=(Item) children.nth_data(i);
                    if(element.fileName==old_filename){
                        element.rename(new_filename);
                    }
                }
                this.show_all();
            }else {
                //debug("something changed");
                syncFiles(0,0);
            }

        }
    }

    private void load_folderSettings(){
        //let's search the folder settings file
        debug("loading folder settings...");
        var basePath=this.get_basePath();
        var settingsFile=basePath+"/.desktopfolder";
        var file = File.new_for_path (settingsFile);
        if (!file.query_exists ()) {
            //we don't have yet a folder settings file, let's create one
            FolderSettings newone=new FolderSettings(this.folderName);
            newone.save_to_file(file);
            this.settings=newone;
        }else{
            FolderSettings existent=FolderSettings.read_settings(file);
            this.settings=existent;
        }
    }

    public string get_basePath(){
        return Environment.get_home_dir ()+"/Desktop/"+this.folderName;
    }

    private void syncFiles(int x, int y){
        //debug("syncingfiles for folder %s, %d, %d",this.folderName, x, y);

        try {
            this.load_folderSettings();
            this.clearAll();
            var basePath=this.get_basePath();
            var directory = File.new_for_path (basePath);
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                string fileName=file_info.get_name();
                File file = File.new_for_commandline_arg (basePath+"/"+fileName);

                    if(fileName.index_of(".",0)!=0){
                        //debug("creating an item...");

                        ItemSettings is=this.settings.get_item(fileName);
                        if(is==null){
                            //we need to create one empty
                            is=new ItemSettings();
                            is.x=x;
                            is.y=y;
                            is.name=fileName;
                            this.settings.add_item(is);
                        }

                        var item=new Item(fileName,file,this, this.container);
                        this.items.append(item);
                        //debug("position:%d,%d",is.x,is.y);
                        this.container.put(item,is.x,is.y);
                    }else{
                        //debug("missing hidden files: %s",fileName);
                        //we don't consider hidden files
                    }
            }
            this.settings.save();
            this.show_all();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    private void clearAll(){
        debug("clearing all items");
        this.items=new List<Item>();
        var children = this.container.get_children ();
        foreach (Gtk.Widget element in children)
            this.container.remove (element);

    }

    public FolderSettings get_folder_settings(){
        return this.settings;
    }

}
