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

public errordomain NoteManagerIOError {
    FILE_EXISTS,
    MOVE_ERROR
}

/**
 * @class
 * Item Manager that represents an Icon of a File or Folder
 */
public class DesktopFolder.NoteManager : Object {
    /** parent application */
    private DesktopFolderApp application;
    /** the File object associated with the item */
    private File file;
    /** the view associated with this manager */
    private NoteWindow view;
    /** name of the note */
    private string note_name      = null;
    /** Note Settings of this note */
    private NoteSettings settings = null;
    /** flag to get the validity of the note */
    private bool flag_valid       = true;
    /**
     * @constructor
     * @param DesktopFolderApp application the application of this note
     * @param string note_name the name of the note
     * @param File file the GLib File object for the file associated with this item
     */
    public NoteManager (DesktopFolderApp application, string note_name, File file) {
        this.note_name = note_name;
        this.file      = file;

        // Let's load the settings of the folder (if exist or a new one)
        if (!this.load_note_settings ()) {
            // removing the settings file
            if (this.file.query_exists ()) {
                try {
                    this.file.trash ();
                } catch (Error error) {
                    stderr.printf ("Error: %s\n", error.message);
                    Util.show_error_dialog ("Error", error.message);
                }
            }
            this.flag_valid = false;
        } else {
            // First we create a Note Window above the desktop
            this.application = application;
            this.view        = new NoteWindow (this);
            this.application.add_window (this.view);
            this.view.show ();
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
     * @description return the validity of the note widget
     * @return {bool} true->yes, it is valid
     */
    public bool is_valid () {
        return this.flag_valid;
    }

    /**
     * @name load_note_settings
     * @description load the settings of this note.
     * The note/settings file contains all the info needed to create the note position, size, etc.. and the text itself
     */
    private bool load_note_settings () {
        // let's search the folder settings file
        var abs_path = this.get_absolute_path ();
        debug ("loading note settings...%s", abs_path);
        if (!this.file.query_exists ()) {
            warning ("note file does not exist!");
            return false;
        } else {
            NoteSettings existent = NoteSettings.read_settings (this.file, this.get_note_name ());
            if (existent == null) {
                // something bad occurred, we must delete this note widget
                return false;
            } else {
                this.settings = existent;
            }
        }
        return true;
    }

    /**
     * @name reopen
     * @description close the current view and reopen it again
     * (mainly to reposition the window on top or back, and most important, the icon over the status bar)
     */
    public void reopen () {
        this.view.save_current_position_and_size ();
        this.get_settings ().save ();

        // closing
        this.application.remove_window (this.view);
        this.view.close ();
        // reopening
        this.view = new NoteWindow (this);
        this.application.add_window (this.view);
        this.view.show ();
    }

    /**
     * @name on_text_change
     * @description the text change event was produced
     * @param {string} text the new text of the note
     */
    public void on_text_change (string text) {
        this.settings.text = text;
        this.settings.save ();
    }

    /**
     * @name get_settings
     * @description return the settings of this note
     * @return FolderSettings the settings of this note
     */
    public NoteSettings get_settings () {
        return this.settings;
    }

    /**
     * @name get_note_name
     * @description return the note name
     * @return string the note name
     */
    public string get_note_name () {
        return this.note_name;
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
     * @return ItemView
     */
    public NoteWindow get_view () {
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
     * @name trash
     * @description trash the file or folder associated
     */
    public void trash () {
        try {
            File file = File.new_for_path (this.get_absolute_path ());
            file.trash ();
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
     * @name save_head_color
     * @description save a head color to the settings file
     * @param color string the color for the head to be saved
     */
    public void save_head_color (string color) {
        this.settings.fgcolor = color;
        this.settings.save ();
    }

    /**
     * @name save_body_color
     * @description save a body color to the settings file
     * @param color string the color for the body to be saved
     */
    public void save_body_color (string color) {
        this.settings.bgcolor = color;
        this.settings.save ();
    }

    /**
     * @name rename
     * @description renaming myself
     * @param string name the new name
     * @return bool true->everything is ok, false->something failed, rollback
     */
    public bool rename (string new_name) {
        string sanitized_name = DesktopFolder.Util.sanitize_name (new_name);
        if (!DesktopFolder.Util.check_name (sanitized_name)) {
            DesktopFolder.Util.show_invalid_name_error_dialog (this.view, new_name);
            return false;
        }
        string old_name = this.note_name;
        string old_path = this.get_absolute_path ();
        var    old_file = this.file;
        this.note_name = sanitized_name;
        string new_path = DesktopFolderApp.get_app_folder () + "/" + sanitized_name + "." + DesktopFolder.NEW_NOTE_EXTENSION;
        var    new_file = File.new_for_path (new_path);
        try {
            if (new_file.query_exists ()) {
                DesktopFolder.Util.show_file_exists_error_dialog (this.view, sanitized_name, _("Note"), null);
                throw new NoteManagerIOError.FILE_EXISTS ("File already exists");
            }
            NoteSettings note_settings = this.get_settings ();
            note_settings.name = sanitized_name;

            FileUtils.rename (old_path, new_path);
            this.file = File.new_for_path (new_path);
            if (this.file.query_exists ()) {
                note_settings.save_to_file (this.file);
                return true;
            } else {
                throw new NoteManagerIOError.MOVE_ERROR ("Failed to rename note");
            }

        } catch (Error error) {
            warning (error.message);
            // Revert changes
            this.note_name     = old_name;
            NoteSettings note_settings = this.get_settings ();
            note_settings.name = old_name;
            this.file          = old_file;
            note_settings.save ();
            return false;
        }
    }

}
