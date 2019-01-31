/*
 * This code was partially imported from GNOME: https://github.com/GNOME/ease/blob/master/ease-core/ease-utilities.vala
 *
 * Ease, a GTK presentation application
 * Copyright (C) 2010 Nate Stedman
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

namespace DesktopFolder.Util {

    /**
     * @name get_desktop_bounding_box
     * @description obtain the bounding box of all the desktop, calculating the area of all the get_n_monitors
     * in the past this was done easier, but now the display get_width and height are deprecated
     * @return {Gdk.Rectangle} the bounding box rectangle of all the desktop
     */
    public Gdk.Rectangle get_desktop_bounding_box () {
        Gdk.Rectangle result   = Gdk.Rectangle ();
        Gdk.Screen    screen   = Gdk.Screen.get_default ();
        Gdk.Display   display  = screen.get_display ();
        int           monitors = display.get_n_monitors ();
        for (int i = 0; i < monitors; i++) {
            Gdk.Monitor   monitor = display.get_monitor (i);
            Gdk.Rectangle warea   = monitor.get_workarea ();
            // debug("New rectangle: %d,%d -- %d,%d",warea.x,warea.y,warea.width,warea.height);
            warea.union (result, out result);
        }

        return result;
    }

    /**
     * Display a simple error message.
     * @param title The title of the dialog.
     * @param message The error message.
     */
    public void show_error_dialog (string ? title, string message) {
        var dialog = new Gtk.MessageDialog (null, 0,
                Gtk.MessageType.ERROR,
                Gtk.ButtonsType.CLOSE,
                "%s", message
            );
        dialog.title        = title;
        dialog.border_width = 5;
        dialog.run ();
        dialog.destroy ();
    }

    /**
     * @name FileOperationAction
     * @description delegate function to inform about the copy being operated
     * @param {GLib.File} file the file being operated
     */
    public delegate void FileOperationAction (GLib.File file);

    /**
     * @name copy_recursive
     * @description this function copy recursively from a GLib.File to a GLib.File
     * @param {GLib.File} src the origin file
     * @param {GLib.File} src the destination file
     * @param {GLib.FileCopyFlags} flags the set of flags for the copy operation (NONE by default)
     * @param {GLib.Cancellable} cancellable object to allow cancel the operation
     * @param {FileOperationAction} listener the listener to get the current operation
     * @return bool true->if everything was OK
     */
    public bool copy_recursive (GLib.File src, GLib.File dest, GLib.FileCopyFlags flags = GLib.FileCopyFlags.NONE,
        GLib.Cancellable ? cancellable = null, FileOperationAction ? listener = null) throws GLib.Error {
        GLib.FileType src_type = src.query_file_type (GLib.FileQueryInfoFlags.NONE, cancellable);

        string src_path        = src.get_path ();

        GLib.File real_dest    = dest;

        if (src_path == real_dest.get_path ()) {
            string basename = dest.get_basename ();
            string dirname  = dest.get_path ().replace (basename, "");
            real_dest = GLib.File.new_for_path (dirname + make_next_duplicate_name (basename, dirname));
        }

        if (src_type == GLib.FileType.DIRECTORY) {
            real_dest.make_directory (cancellable);
            src.copy_attributes (real_dest, flags, cancellable);

            GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, cancellable);
            for (GLib.FileInfo ? info = enumerator.next_file (cancellable); info != null; info = enumerator.next_file (cancellable)) {
                copy_recursive (
                    GLib.File.new_for_path (GLib.Path.build_filename (src_path, info.get_name ())),
                    GLib.File.new_for_path (GLib.Path.build_filename (real_dest.get_path (), info.get_name ())),
                    flags,
                    cancellable, listener
                );
            }
        } else if (src_type == GLib.FileType.REGULAR) {
            if (listener != null) {
                listener (real_dest);
            } else {
                debug ("copying %s", real_dest.get_basename ());
            }

            src.copy (real_dest, flags, cancellable);
        }

        return true;
    }

    /**
     * Returns the parent window of the specified widget.
     */
    public Gtk.Window widget_window (Gtk.Widget widg) {
        while (widg.get_parent () != null) widg = widg.get_parent ();
        return widg as Gtk.Window;
    }

    /**
     * Returns an absolute path for the given path.
     */
    public static string absolute_path (string path) {
        var file = GLib.File.new_for_path (path);
        return file.resolve_relative_path (".").get_path ();
    }

    /**
     * Converts the given angle from degrees to radians.
     *
     * @param deg Angle in radians
     * @return Angle in degrees
     */
    public static double deg_to_rad (double deg) {
        return (deg * Math.PI / 180f);
    }

    /**
     * Converts the given angle from radians to degrees.
     *
     * @param rad Angle in degrees
     * @return Angle in radians
     */
    public static double rad_to_deg (double rad) {
        return (rad / Math.PI * 180f);
    }

    /**
     * @name create_new_photo
     * @param {Gtk.Window} window the parent window to show the dialog
     * @description show a dialog to create a new photo
     */
    public static void create_new_photo (Gtk.Window window, int x, int y) {
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            DesktopFolder.Lang.PHOTO_SELECT_PHOTO_MESSAGE, window,
            Gtk.FileChooserAction.OPEN,
            DesktopFolder.Lang.DIALOG_CANCEL,
            Gtk.ResponseType.CANCEL,
            DesktopFolder.Lang.DIALOG_SELECT,
            Gtk.ResponseType.ACCEPT);

        Gtk.FileFilter filter = new Gtk.FileFilter ();
        filter.set_name ("Images");
        filter.add_mime_type ("image");
        filter.add_mime_type ("image/png");
        filter.add_mime_type ("image/jpeg");
        filter.add_mime_type ("image/gif");
        filter.add_pattern ("*.png");
        filter.add_pattern ("*.jpg");
        filter.add_pattern ("*.gif");
        filter.add_pattern ("*.tif");
        filter.add_pattern ("*.xpm");
        chooser.add_filter (filter);

        // Process response:
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var photo_path = chooser.get_filename ();
            debug ("Photo path: " + photo_path);

            try {
                // Check if the image is valid
                new Gdk.Pixbuf.from_file (photo_path);

                PhotoSettings ps = new PhotoSettings (photo_path, window.get_window ());
                ps.x = x;
                ps.y = y;
                string path = DesktopFolderApp.get_app_folder () + "/" + ps.name + "." + DesktopFolder.NEW_PHOTO_EXTENSION;
                File   file = File.new_for_path (path);
                if (file.query_exists ()) {
                    debug ("Photo already exists, not creating.");
                } else {
                    ps.save_to_file (file);
                }
            } catch {
                debug ("Invalid photo: " + photo_path);
            }
        }
        chooser.close ();
    }

    /**
     * @name create_new_desktop_folder
     * @description Create a new panel on the desktop
     * @param {Gtk.Window} window The parent window to show the dialog
     */
    public static void create_new_desktop_folder (Gtk.Window window, int x, int y) {
        string name = sanitize_name (make_next_duplicate_name (DesktopFolder.Lang.NEWLY_CREATED_PANEL, DesktopFolderApp.get_app_folder () + "/"));

        // cancelling the current monitor
        string folder_name              = DesktopFolderApp.get_app_folder () + "/" + name;
        DirUtils.create (folder_name, 0755);
        File file                       = File.new_for_path (folder_name + "/.desktopfolder");
        DesktopFolder.FolderSettings fs = new DesktopFolder.FolderSettings (name);

        fs.x                = x;
        fs.y                = y;
        fs.recently_created = true;
        fs.arrangement_type = get_default_arrangement_setting ();

        fs.save_to_file (file);
    }

    /**
     * @name make_next_duplicate_name
     * @description Find a new name for the file
     * @param {string} The base name to check if there's a duplicate
     * @param {string} The path for the file
     * @return {string} Either the original basename (if there wasn't a duplicate) or a new basename
     */
    public static string make_next_duplicate_name (string basename, string path) {
        // TODO: Copy elementary's way of doing it
        string new_path = sanitize_name (path);
        if (!new_path.has_suffix ("/")) {
            new_path += "/";
        }
        string name        = sanitize_name (basename);
        int    ext_pos     = name.last_index_of (".");
        string ext         = "";
        string name_no_ext = name;
        if (ext_pos != -1) {
            ext         = name.substring (ext_pos);
            name_no_ext = name.replace (ext, "");
            name_no_ext = name_no_ext.strip ();
        }
        try {
            var       regex = new Regex ("([ ]+[0-9]+)$");
            MatchInfo matchinfo;
            if (regex.match (name_no_ext, 0, out matchinfo)) {
                int startpos = 0;
                int endpos   = 0;
                matchinfo.fetch_pos (0, out startpos, out endpos);
                // string regex_output = name_no_ext.slice ((long) startpos, (long) endpos);
                name_no_ext = name_no_ext.splice ((long) startpos, (long) endpos);
            }
        } catch (Error e) {
            debug (@"Error: $(e.message)");
        }

        string new_filename = "";

        for (int i = 2; i < 1000000; i++) {
            new_filename = @"$name_no_ext $i";
            File file = File.new_for_path (new_path + new_filename + ext);
            if (!file.query_exists ()) {
                break;
            }
        }

        // debug ("name: " + name + ", ext_pos: " + ext_pos.to_string () + ", ext: " + ext + ", name_no_ext: " + name_no_ext + ", file_to_check: " + file_to_check);
        return new_filename;
    }

    /**
     * @name create_new_link_panel
     * @description create a new link panel to a folder (this means a link panel)
     * @param {Gtk.Window} window the parent window to show the dialog
     */
    public static void create_new_link_panel (Gtk.Window window, int x, int y) {
        Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
            DesktopFolder.Lang.DESKTOPFOLDER_PANELLINK_MESSAGE, window, Gtk.FileChooserAction.OPEN,
            DesktopFolder.Lang.DIALOG_CANCEL,
            Gtk.ResponseType.CANCEL,
            DesktopFolder.Lang.DIALOG_SELECT,
            Gtk.ResponseType.ACCEPT);

        chooser.set_action (Gtk.FileChooserAction.SELECT_FOLDER);

        // Process response:
        if (chooser.run () == Gtk.ResponseType.ACCEPT) {
            var  folderpath    = chooser.get_filename ();
            var  foldername    = Path.get_basename (folderpath);
            File linkdest      = File.new_for_path (DesktopFolderApp.get_app_folder () + "/" + foldername);
            File settings_file = File.new_for_path (folderpath + "/.desktopfolder");

            var fs             = new FolderSettings (foldername);
            fs.x                = x;
            fs.y                = y;
            fs.arrangement_type = get_default_arrangement_setting ();

            fs.save_to_file (settings_file);

            debug ("creating settings at: %s", folderpath + "/.desktopfolder");
            debug ("file:%s", folderpath);
            debug ("file name:%s", foldername);
            debug ("link path:%s", DesktopFolderApp.get_app_folder () + "/" + foldername);
            if (linkdest.query_exists ()) {
                debug ("Link already exists, not creating.");
            } else {
                try {
                    var command = "ln -s \"" + folderpath + "\" \"" + DesktopFolderApp.get_app_folder () + "\"";
                    var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
                    appinfo.launch_uris (null, null);
                } catch (Error e) {
                    stderr.printf ("Error: %s\n", e.message);
                    Util.show_error_dialog ("Error", e.message);
                }
            }


        }

        chooser.close ();
    }

    /**
     * @name get_default_arrangement_setting
     * @description return the global default arragament for new panels
     */
    private int get_default_arrangement_setting () {
        GLib.Settings settings = new GLib.Settings ("com.github.spheras.desktopfolder");
        string[]      keys     = settings.list_keys ();
        bool          found    = false;
        for (int i = 0; i < keys.length; i++) {
            string key = keys[i];
            if (key == "default-arrangement") {
                found = true;
                break;
            }
        }
        int default_arrangement = FolderArrangement.ARRANGEMENT_TYPE_FREE;
        if (found) {
            default_arrangement = (int) settings.get_enum ("default-arrangement");
        }
        // debug ("default_arrangement: %d", default_arrangement);
        return default_arrangement;
    }

    /**
     * @name create_new_note
     * @description create a new note inside the desktop
     * @param {Gtk.Window} window the parent window to show the dialog
     */
    public static void create_new_note (Gtk.Window window, int x, int y) {
        string newly_created_note = DesktopFolder.Lang.NEWLY_CREATED_NOTE;
        string name               = sanitize_name (make_next_duplicate_name (newly_created_note + "." + DesktopFolder.NEW_NOTE_EXTENSION, DesktopFolderApp.get_app_folder () + "/"));

        string       path         = DesktopFolderApp.get_app_folder () + "/" + name + "." + DesktopFolder.NEW_NOTE_EXTENSION;
        File         file         = File.new_for_path (path);
        NoteSettings ns           = new NoteSettings (name);

        ns.x = x;
        ns.y = y;

        ns.edit_label_on_creation = true;

        ns.save_to_file (file);
    }

    private static string sanitize_name (string new_name) {
        string sanitized_name = new_name.strip ();
        return sanitized_name;
    }

    private static bool check_name (string new_name) {
        if (new_name != "" && !("/" in new_name) && !new_name.has_prefix (".")) {
            return true;
        } else {
            return false;
        }
    }

    delegate void ExecuteAfterError (Gtk.Window window);

    /**
     * @name show_file_exists_error_dialog
     * @description Show an error saying that the file exists.
     */
    private static void show_file_exists_error_dialog (Gtk.Window window, string new_name, string widget_name, ExecuteAfterError ? callback) {
        string message = "<big><b>" +
            _("Could not create \"%'s\"").printf (new_name) +
            "</b></big>\n\n" +
            _(widget_name + " already exists.");
        Gtk.MessageDialog dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, message);
        debug (widget_name + " already exists, not creating.");
        dialog.response.connect ((response_id) => {
            dialog.destroy ();
            if (callback != null) {
                callback (window);
            }
        });
        dialog.set_deletable (false);
        dialog.use_markup = true;
        dialog.show ();
    }

    /**
     * @name show_invalid_name_error_dialog
     * @description Show an error saying that the name is invalid.
     */
    private static void show_invalid_name_error_dialog (Gtk.Window window, string new_name) {
        string message = "<big><b>" +
            _("Could not create \"%'s\"").printf (new_name) +
            "</b></big>\n\n" +
            _("Name is invalid.");
        Gtk.MessageDialog dialog = new Gtk.MessageDialog (window, Gtk.DialogFlags.MODAL,
                Gtk.MessageType.ERROR, Gtk.ButtonsType.OK, message);
        debug ("Invalid name, not creating");
        dialog.response.connect ((response_id) => {
            dialog.destroy ();
        });
        dialog.set_deletable (false);
        dialog.use_markup = true;
        dialog.show ();
    }

    /**
     * Adds a closed sub-path rounded rectangle of the given size and border radius to the current path
     * at position (x, y) in user-space coordinates.
     *
     * @param cr a {@link Cairo.Context}
     * @param x the X coordinate of the top left corner of the rounded rectangle
     * @param y the Y coordinate to the top left corner of the rounded rectangle
     * @param width the width of the rounded rectangle
     * @param height the height of the rounded rectangle
     * @param radius the border radius of the rounded rectangle
     */
    public static void cairo_rounded_rectangle (Cairo.Context cr, double x, double y, double width, double height, double radius) {

        cr.move_to (x + radius, y);
        cr.arc (x + width - radius, y + radius, radius, Math.PI * 1.5, Math.PI * 2);
        cr.arc (x + width - radius, y + height - radius, radius, 0, Math.PI * 0.5);
        cr.arc (x + radius, y + height - radius, radius, Math.PI * 0.5, Math.PI);
        cr.arc (x + radius, y + radius, radius, Math.PI, Math.PI * 1.5);
        cr.close_path ();
    }

    /**
     * @name blur_image_surface
     * @description Performs a simple 2D Gaussian blur of radius @radius on surface @surface.
     */
    public static void blur_image_surface (Cairo.ImageSurface surface, int radius) {
        debug ("start blur1");

        Cairo.ImageSurface tmp;
        int     width, height;
        int     src_stride, dst_stride;
        int     x, y, z, w;
        uchar[] src;
        uchar[] dst;
        int     s, d;
        uint32  a, p;
        int     i, j, k;
        uint8   kernel[17];
        int     size = (int) (17 / sizeof (uint8));
        int     half = (int) ((17 / sizeof (uint8)) / 2);

        if (surface.status () != Cairo.Status.SUCCESS) {
            return;
        }

        width  = surface.get_width ();
        height = surface.get_height ();

        debug ("start blur2");

        switch (surface.get_format ()) {
        case Cairo.Format.A1:
        default:
            /* Don't even think about it! */
            return;
        case Cairo.Format.A8:
            /* Handle a8 surfaces by effectively unrolling the loops by a
             * factor of 4 - this is safe since we know that stride has to be a
             * multiple of uint32_t. */
            width = width / 4;
            break;
        case Cairo.Format.RGB24:
        case Cairo.Format.ARGB32:
            break;
        }

        debug ("start blur2.1");

        tmp = new Cairo.ImageSurface (Cairo.Format.ARGB32, width, height);
        if (tmp.status () != Cairo.Status.SUCCESS)
            return;

        debug ("start blur2.2");
        src        = surface.get_data ();
        debug ("start blur2.3");
        src_stride = surface.get_stride ();
        debug ("start blur2.4");

        debug ("start blur2.5");

        dst        = tmp.get_data ();
        dst_stride = tmp.get_stride ();

        debug ("start blur3");

        a = 0;
        for (i = 0; i < size; i++) {
            double f = i - half;
            kernel[i] = (uint8) (Math.exp (-f * f / 30.0) * 80);
            a         = a + kernel[i];
        }

        /* Horizontally blur from surface -> tmp */
        for (i = 0; i < height; i++) {
            s = i * src_stride;
            d = i * dst_stride;
            for (j = 0; j < width; j++) {
                if (radius < j && j < width - radius) {
                    dst[d + j] = src[s + j];
                    continue;
                }

                x = y = z = w = 0;
                for (k = 0; k < size; k++) {
                    if (j - half + k < 0 || j - half + k >= width) {
                        continue;
                    }

                    p = src[s + j - half + k];

                    x = x + (int) (((p >> 24) & 0xff) * kernel[k]);
                    y = y + (int) (((p >> 16) & 0xff) * kernel[k]);
                    z = z + (int) (((p >> 8) & 0xff) * kernel[k]);
                    w = w + (int) (((p >> 0) & 0xff) * kernel[k]);
                }
                dst[d + j] = (uchar) ((x / a << 24) | (y / a << 16) | (z / a << 8) | w / a);
            }
        }

        debug ("start blur4");

        /* Then vertically blur from tmp -> surface */
        for (i = 0; i < height; i++) {
            s = i * dst_stride;
            d = i * src_stride;
            for (j = 0; j < width; j++) {
                if (radius <= i && i < height - radius) {
                    src[j] = dst[j];
                    continue;
                }

                x = y = z = w = 0;
                for (k = 0; k < size; k++) {
                    if (i - half + k < 0 || i - half + k >= height) {
                        continue;
                    }

                    s = (i - half + k) * dst_stride;
                    p = dst[s + j];

                    x = x + (int) (((p >> 24) & 0xff) * kernel[k]);
                    y = y + (int) (((p >> 16) & 0xff) * kernel[k]);
                    z = z + (int) (((p >> 8) & 0xff) * kernel[k]);
                    w = w + (int) (((p >> 0) & 0xff) * kernel[k]);
                }
                src[d + j] = (uchar) ((x / a << 24) | (y / a << 16) | (z / a << 8) | w / a);
            }
        }

        debug ("start blur5");

        // cairo_surface_destroy (tmp);
        surface.mark_dirty ();
    }

}
