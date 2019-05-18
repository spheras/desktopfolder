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
    public override int get_parent_default_arrangement_orientation_setting () {
        return FolderSettings.ARRANGEMENT_ORIENTATION_VERTICAL;
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
     * @name show_items
     * @description shows the items
     */
    public override void show_items () {
        // debug (@"show_items $(this.get_application ().get_desktop_visibility ())");
        if (this.get_application ().get_desktop_visibility ()) {
            // debug ("showing items");
            base.show_items ();
            base.view.refresh ();
        }
    }

    /**
     * @name hide_items
     * @description hides the items
     */
    public override void hide_items () {
        debug (@"hide_items $(this.get_application ().get_desktop_visibility ())");
        debug ("hiding items");
        base.hide_items ();
    }

    /**
     * @name show_view
     * @description show the items on the desktop
     * @override
     */
    public override void show_view () {
        this.show_items ();
    }

    /**
     * @name hide_view
     * @description hide the items on the desktop
     * @override
     */
    public override void hide_view () {
        this.hide_items ();
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
        // debug ("bounding box result: %d,%d -- %d,%d", boundingbox.x, boundingbox.y, boundingbox.width, boundingbox.height);

        int[] borders = this.get_dock_borders ();

        this.get_view ().move (borders[0], borders[2]); // (-12, -10);
        int w = boundingbox.width - borders[0]; // deprecated -> screen.get_width (); // + 25;
        int h = boundingbox.height - borders[2]; // deprecated -> screen.get_height (); // + 25;
        this.get_view ().resize (w, h);
        this.get_view ().set_default_size (w, h);
        this.get_view ().height_request = h;
        this.get_view ().width_request  = w;

        debug ("DESKTOP SIZE CHANGED! (%d,%d) (%d,%d)", 0, 0, w, h);
    }

    /**
     * @name get_dock_borders
     * @description return an array with the space needed for system docks, i.e. plank
     * @return {int[]} the array with space needed [left, right, top, bottom]
     */
    public int[] get_dock_borders () {
        unowned Wnck.Screen screen = Wnck.Screen.get_default ();
        while (Gtk.events_pending ()) {
            Gtk.main_iteration ();
        }
        unowned List <Wnck.Window> windows = screen.get_windows ();
        Gee.List <Wnck.Window>     docks   = new Gee.ArrayList <Wnck.Window>();
        int[] borders = new int[4];
        foreach (Wnck.Window w in windows) {
            Wnck.Application window_app = w.get_application ();
            string           app_name   = window_app.get_name ();
            if (w.get_window_type () == Wnck.WindowType.DOCK && app_name.index_of ("desktopfolder") < 0) {
                var name = w.get_name ();
                debug ("Dock window found: %s", name);
                docks.add (w);
                string[] strut = this.get_strut (w.get_xid ());
                if (strut != null) {
                    // we get the greatest border
                    for (int i = 0; i < 4; i++) {
                        int istrut = int.parse (strut[i]);
                        if (borders[i] < istrut) {
                            borders[i] = istrut;
                        }
                    }
                }
            }
        }

        return borders;
    }

    /**
     * @name ge_strut
     * @description get the strut- values from xprop, on dock type windows.
     * This function is inspired in the function for Ubuntu Budgie Window Shuffler
     * It is based on the xprop command, check it by using: xprop -id {xid of the window}
     * https://github.com/UbuntuBudgie/window-shuffler/blob/c2df9934fd823f50a2409effccd8349654bf7b5e/shuffler_geo.py#L62
     * @param {ulong} xid the x id of the window
     * @return {string[]} the strut info (or null). An array of 4 positions [left,right,top,bottom]
     */
    private string[] ? get_strut (ulong xid) {
        // get the strut- values from xprop, on dock type windows. Since Plank is
        // an exception, the function indicates if the dock is a plank instance.
        string       output;
        string       cmd            = "xprop -id %d".printf ((int) xid);
        const string STRUT_CARDINAL = "_NET_WM_STRUT(CARDINAL) = ";
        GLib.Process.spawn_command_line_sync (cmd, out output);
        string[] all_lines          = output.split ("\n");
        foreach (string l in all_lines) {
            // debug("XPROP:    %s",l);
            if (l.index_of (STRUT_CARDINAL, 0) >= 0) {
                return l.split ("=")[1].split (",");
            }
        }

        return null;
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
