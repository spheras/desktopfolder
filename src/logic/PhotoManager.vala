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
public class DesktopFolder.PhotoManager : Object {
    /** parent application */
    private DesktopFolderApp application;
    /** the File object associated with the item */
    private File file;
    /** the view associated with this manager */
    private PhotoWindow view;
    /** name of the photo */
    private string photo_name      = null;
    /** photo Settings of this photo */
    private PhotoSettings settings = null;
    /** flag to get the validity of the photo */
    private bool flag_valid        = true;

    /**
     * @constructor
     * @param DesktopFolderApp application the application of this photo
     * @param string photo_name the name of the photo
     * @param File file the GLib File object for the file associated with this item
     */
    public PhotoManager (DesktopFolderApp application, string photo_name, File file) {
        this.photo_name = photo_name;
        this.file       = file;

        // Let's load the settings of the folder (if exist or a new one)
        if (!this.load_photo_settings ()) {
            // removing the settings file
            if (this.file.query_exists ()) {
                try {
                    this.file.trash ();
                } catch (Error e) {
                }
            }
            this.flag_valid = false;
        } else {
            // First we create a photo Window above the desktop
            this.application = application;
            this.view        = new PhotoWindow (this);
            this.application.add_window (this.view);
            this.view.show ();

            // trying to put it in front of the rest
            this.view.set_keep_below (false);
            this.view.set_keep_above (true);
            this.view.present ();
            this.view.set_keep_above (false);
            this.view.set_keep_below (true);
            // ---------------------------------------
        }
    }

    /**
     * @name on_screen_size_changed
     * @description detecting screen size changes
     */
    public void on_screen_size_changed (Gdk.Screen screen) {
        this.settings.calculate_current_position ();
        this.view.reload_settings ();
    }

    /**
     * @name is_valid
     * @description return the validity of the photo widget
     * @return {bool} true->yes, it is valid
     */
    public bool is_valid () {
        return this.flag_valid;
    }

    /**
     * @name load_photo_settings
     * @description load the settings of this photo.
     * The photo/settings file contains all the info needed to create the photo position, size, etc.. and the text itself
     * @return {bool} true->everything was ok, false->something was bad
     */
    private bool load_photo_settings () {
        // let's search the folder settings file
        var abs_path = this.get_absolute_path ();
        debug ("loading photo settings...%s", abs_path);
        if (!this.file.query_exists ()) {
            warning ("photo file does not exist!");
            return false;
        } else {
            PhotoSettings existent = PhotoSettings.read_settings (this.file, this.get_photo_name ());
            if (existent == null) {
                // something bad occurred, we must delete this photo widget
                return false;
            } else {
                this.settings = existent;
            }
        }
        return true;
    }

    /**
     * @name get_settings
     * @description return the settings of this photo
     * @return PhotoSettings the settings of this photo
     */
    public PhotoSettings get_settings () {
        return this.settings;
    }

    /**
     * @name get_photo_name
     * @description return the photo name
     * @return string the photo name
     */
    public string get_photo_name () {
        return this.photo_name;
    }

    /**
     * @name get_application
     * @description return the desktop folder application
     * @return DesktopFolderApp
     */
    public DesktopFolderApp get_application () {
        return this.application;
    }

    /**
     * @name get_view
     * @description return the view of this manager
     * @return PhotoWindow
     */
    public PhotoWindow get_view () {
        return this.view;
    }

    /**
     * @name show_view
     * @description show the folder
     */
    public void show_view () {
        // setting opacity to stop the folder window flashing at startup
        this.view.opacity = 1;
        this.view.show_all ();
        this.view.fade_in ();
    }

    /**
     * @name hide_view
     * @description hide the folder
     */
    public void hide_view () {
        this.view.fade_out ();
        Timeout.add (160, () => {
            // ditto
            this.view.opacity = 0;
            this.view.hide ();
            return false;
        });
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
     * @name close
     * @description close the item manager and its view
     */
    public void close () {
        this.view.close ();
    }

    /**
     * @name reopen
     * @description close the current view and reopen it again
     */
    public void reopen () {
        this.view.save_current_position_and_size ();
        this.get_settings ().save ();

        // closing
        this.application.remove_window (this.view);
        this.view.close ();
        // reopening
        this.view = new PhotoWindow (this);
        this.application.add_window (this.view);
        this.view.show ();
    }

    /**
     * @name open
     * @description open the photo in the default viewer
     */
    public void open () {
        try {
            var command = "xdg-open \"" + get_settings ().photo_path + "\"";
            var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
            appinfo.launch_uris (null, null);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name delete
     * @description delete the file associated
     */
    public void delete () {
        try {
            File file = File.new_for_path (this.get_absolute_path ());
            file.delete ();
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name set_new_shape
     * @description set a new shape (position and size) of the view
     */
    public void set_new_shape (int x, int y, int width, int height) {
        this.settings.x = x;
        this.settings.y = y;
        this.settings.w = width;
        this.settings.h = height;
        this.settings.save ();
    }

    /**
     * @name rename
     * @description renaming myself
     * @param string name the new name
     * @return bool true->everything is ok, false->something failed, rollback
     */
    public bool rename (string new_name) {
        if (new_name.length <= 0) {
            return false;
        }
        string old_name = this.photo_name;
        string old_path = this.get_absolute_path ();
        this.photo_name = new_name;
        string new_path = DesktopFolderApp.get_app_folder () + "/" + new_name + "." + DesktopFolder.NEW_PHOTO_EXTENSION;

        try {
            PhotoSettings is = this.get_settings ();
            is.name          = new_name;

            FileUtils.rename (old_path, new_path);
            this.file = File.new_for_path (new_path);
            is.save_to_file (this.file);

            return true;
        } catch (Error e) {
            // we can't rename, undoing
            this.photo_name  = old_name;
            PhotoSettings is = this.get_settings ();
            is.name          = old_name;
            is.save ();

            // showing the error
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);

            return false;
        }
    }

}
