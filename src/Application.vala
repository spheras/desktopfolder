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

public class DesktopFolderApp : Granite.Application {

    public const string APP_NAME = "desktopfolder";
    public const string VERSION = "0.1";

    construct {
        /* Needed by Glib.Application */
        this.application_id = DesktopFolder.APP_ID;  //Ensures an unique instance.
        this.flags = ApplicationFlags.FLAGS_NONE;

        /* Needed by Granite.Application */
        this.program_name = _(DesktopFolder.APP_TITLE);
        this.exec_name = APP_NAME;
        this.build_version = VERSION;
    }

    public DesktopFolderApp () {
        Object (application_id: "org.spheras.desktopfolder",
        flags: ApplicationFlags.FLAGS_NONE);
    }

    protected override void activate () {
        //only one app at a time
        if (get_windows().length () > 0) {
            get_windows().data.present ();
            return;
        }

        //css styles
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("org/spheras/desktopfolder/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        //quit action
        /*
        var quit_action = new SimpleAction ("quit", null);
        add_action (quit_action);
        add_accelerator ("<Control>q", "app.quit", null);
        quit_action.activate.connect (() => {
            if (app_window != null) {
                app_window.destroy ();
            }
        });
        */

        syncFolders();
    }

    private void syncFolders () {
        try {
            var basePath=Environment.get_home_dir ()+"/Desktop";
            var directory = File.new_for_path (basePath);
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                File file = File.new_for_commandline_arg (basePath+"/"+file_info.get_name());
                FileType type = file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                if(type==FileType.DIRECTORY){
                    var fw = new FolderWindow (this,file_info.get_name());
                    add_window(fw);
                    fw.show ();
                }else{
                    //nothing
                    //we only deal with folders to be shown
                }
                //stdout.printf ("%s, %s\n", file_info.get_name (),type.to_string ());
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
    }

    public static int main (string[] args) {
        var app = new DesktopFolderApp ();
        return app.run (args);
    }
}
