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
 * Desktop Manager
 */
public class DesktopFolder.DesktopManager : DesktopFolder.FolderManager {

    /**
     * @constructor
     * @param DesktopFolderApp application the application owner of this window
     * @param string folder_name the name of the folder
     */
    public DesktopManager (DesktopFolderApp application) {
        // first, let's check the folder
        var directory = File.new_for_path (DesktopFolderApp.get_app_folder ()); // + "/" + DesktopFolder.DesktopWindow.DESKTOP_FAKE_FOLDER_NAME);
        if (!directory.query_exists ()) {
            DirUtils.create (directory.get_path (), 0755);
        }

        base (application, "");

        // we cannot be moved
        this.is_moveable = false;
        this.get_view ().set_type_hint (Gdk.WindowTypeHint.DOCK);

        Gdk.Screen screen = Gdk.Screen.get_default ();
        this.get_view ().move (-12, -10);
        this.get_view ().resize (screen.get_width () + 25, screen.get_height () + 25);

        this.get_view ().set_titlebar (new Gtk.Label (""));
        this.get_view ().change_body_color (0);
    }

    /**
     * @name skip_file
     * @description we must skip the widget setting files
     * @override
     */
    protected override bool skip_file (File file) {
        string basename = file.get_basename ();

        if (FileUtils.test (file.get_path (), FileTest.IS_DIR)) {
            // is a panel?
            string flagfilepath = file.get_path () + "/.desktopfolder";
            // debug("is a panel? %s",flagfilepath);
            File flagfile       = File.new_for_commandline_arg (flagfilepath);
            return flagfile.query_exists ();
        } else {
            if (basename.has_suffix (".dfn") || basename.has_suffix (".dfp")) {
                return true;
            }
        }

        return base.skip_file (file);
    }

    /**
     * @overrided
     * we must create a .nopanel inside to avoid creating a panel from this folder
     */
    protected override void create_new_folder_inside (string folder_path) {
        debug ("esta si que si");
        File nopanel = File.new_for_path (folder_path + "/.nopanel");
        try{
            nopanel.create (FileCreateFlags.NONE);
        }catch(Error e){
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

}
