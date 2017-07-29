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
public class FolderWindow : Gtk.Window {

    private string folderName=null;
    private Gtk.Fixed container=null;

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

        this.folderName=folderName;
        this.container=new Gtk.Fixed();
        add(this.container);
        syncFiles();
        this.show_all ();
    }

    private void syncFiles(){
        debug("syncingfiles for folder %s",this.folderName);
        try {
            var basePath=Environment.get_home_dir ()+"/Desktop/"+this.folderName;
            var directory = File.new_for_path (basePath);
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                string fileName=file_info.get_name();
                File file = File.new_for_commandline_arg (basePath+"/"+fileName);
                FileType type = file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                if(type!=FileType.DIRECTORY){
                    if(fileName.index_of(".",0)>0){
                        debug("creating an item...");

                        var item=new Item(basePath,fileName,file);
                        this.container.put(item,0,0);
                    }else{
                        //we don't consider hidden files
                    }
                }else{
                    //nothing
                    //we only deal with files to be shown
                }
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

}
