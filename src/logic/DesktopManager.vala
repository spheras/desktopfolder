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
        this.get_view ().change_body_color (0);

        Gdk.Screen screen = Gdk.Screen.get_default ();
        this.on_screen_size_changed (screen);

        this.view.show ();
    }

    /**
     * @overrided
     */
    public override void show_items () {
        foreach (ItemManager item in items) {
            item.show_view ();
        }
    }

    /**
     * @overrided
     */
    public override void hide_items () {
        foreach (ItemManager item in items) {
            item.hide_view ();
        }
    }

    /**
     * @name create_view
     * @description create the view associated with this manager
     * @overrided
     */
    protected override void create_view () {
        this.view = new DesktopFolder.DesktopWindow (this);
    }

    /**
     * @name on_screen_size_changed
     * @description detecting screen size changes
     */
    public override void on_screen_size_changed (Gdk.Screen screen) {
        if (screen == null) {
            screen = Gdk.Screen.get_default ();
        }

        Gdk.Rectangle boundingbox = DesktopFolder.Util.get_desktop_bounding_box ();
        // debug("bounding box result: %d,%d -- %d,%d",boundingbox.x,boundingbox.y,boundingbox.width,boundingbox.height);

        this.get_view ().move (0, 0); // (-12, -10);
        int w = boundingbox.width; // deprecated -> screen.get_width (); // + 25;
        int h = boundingbox.height; // deprecated -> screen.get_height (); // + 25;
        this.get_view ().resize (w, h);
        this.get_view ().set_default_size (w, h);

        debug ("DESKTOP SIZE CHANGED! (%d,%d) (%d,%d)", -12, -10, w, h);
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
            if (basename.has_suffix (DesktopFolder.OLD_NOTE_EXTENSION) || basename.has_suffix (DesktopFolder.OLD_PHOTO_EXTENSION)
                || basename.has_suffix (DesktopFolder.NEW_NOTE_EXTENSION) || basename.has_suffix (DesktopFolder.NEW_PHOTO_EXTENSION)) {
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
        File nopanel = File.new_for_path (folder_path + "/.nopanel");
        try {
            if (!nopanel.query_exists ()) {
                nopanel.create (FileCreateFlags.NONE);
            }
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

}
