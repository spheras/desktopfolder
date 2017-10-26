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
        this.load_note_settings ();

        // First we create a Note Window above the desktop
        this.application = application;
        this.view        = new NoteWindow (this);
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

    /**
     * @name load_note_settings
     * @description load the settings of this note.
     * The note/settings file contains all the info needed to create the note position, size, etc.. and the text itself
     */
    private void load_note_settings () {
        // let's search the folder settings file
        var abs_path = this.get_absolute_path ();
        debug ("loading note settings...%s", abs_path);
        if (!this.file.query_exists ()) {
            warning ("note file doesnt exist!");
        } else {
            NoteSettings existent = NoteSettings.read_settings (this.file, this.get_note_name ());
            this.settings = existent;
        }
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
     * @name delete
     * @description delete the file or folder associated
     */
    public void move_to_trash () {
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
        if (new_name.length <= 0) {
            return false;
        }
        string old_name = this.note_name;
        string old_path = this.get_absolute_path ();
        this.note_name = new_name;
        string new_path = DesktopFolderApp.get_app_folder () + "/" + new_name + "." + DesktopFolder.NOTE_EXTENSION;

        try {
            NoteSettings is = this.get_settings ();
            is.name         = new_name;

            FileUtils.rename (old_path, new_path);
            this.file = File.new_for_path (new_path);
            is.save_to_file (this.file);

            return true;
        } catch (Error e) {
            // we can't rename, undoing
            this.note_name  = old_name;
            NoteSettings is = this.get_settings ();
            is.name         = old_name;
            is.save ();

            // showing the error
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);

            return false;
        }
    }

}
