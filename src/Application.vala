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
 * The Main Application
 */
public class DesktopFolderApp : Gtk.Application {

    /** File Monitor of desktop folder */
    private FileMonitor monitor = null;

    /** List of folder owned by the application */
    private List<DesktopFolder.FolderManager> folders = new List<DesktopFolder.FolderManager>();
    private List<DesktopFolder.NoteManager> notes     = new List<DesktopFolder.NoteManager>();
    private List<DesktopFolder.PhotoManager> photos   = new List<DesktopFolder.PhotoManager>();

    construct {
        /* Needed by Glib.Application */
        this.application_id = DesktopFolder.APP_ID; // Ensures an unique instance.
        this.flags          = ApplicationFlags.FLAGS_NONE;

        /* Needed by Granite.Application */
        /*
           this.program_name = _(DesktopFolder.APP_TITLE);
           this.exec_name = DesktopFolder.APP_NAME;
           this.build_version = DesktopFolder.VERSION;
         */
    }

    /**
     * @constructor
     */
    public DesktopFolderApp () {
        Object (application_id: "com.github.spheras.desktopfolder",
                flags : ApplicationFlags.FLAGS_NONE);
    }

    /**
     * @name activate
     * @override
     * @description activate life cycle
     */
    protected override void activate () {
        base.activate ();
        debug ("activate event");
        // we'll init the app in the activate event
        init ();
    }

    /**
     * @name startup
     * @override
     * @description startup life cycle
     */
    public override void startup () {
        base.startup ();
        debug ("startup event");
    }

    /**
     * @name init
     * @description initialization of the application
     */
    private void init () {
        // only one app at a time
        if (get_windows ().length () > 0) {
            get_windows ().data.present ();
            return;
        }

        create_shortcut ();

        // we need the app folder (desktop folder)
        var desktopFolder = File.new_for_path (DesktopFolderApp.get_app_folder ());
        if (!desktopFolder.query_exists ()) {
            DirUtils.create (DesktopFolderApp.get_app_folder (), 0755);
        }

        // initializing the clipboard manager
        DesktopFolder.Clipboard.ClipboardManager.get_for_display ();

        // providing css style
        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("com/github/spheras/desktopfolder/Application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider,
                                                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        // quit action
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

        // we start creating the folders found at the desktop folder
        this.sync_folders_and_notes ();
        this.monitor_desktop ();
    }

    /**
     * @name get_app_folder
     * @description return the path where the app search folders to be created (the desktop folder)
     * @return string the absolute path directory
     */
    public static string get_app_folder () {
        return Environment.get_home_dir () + "/Desktop";
    }

    /**
     * @name sync_folders_and_notes
     * @description create as many folder and note windows as the desktop folder and note founds
     */
    private void sync_folders_and_notes () {
        try {
            var base_path  = DesktopFolderApp.get_app_folder ();
            var directory  = File.new_for_path (base_path);
            var enumerator = directory.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            List<DesktopFolder.FolderManager> updated_folder_list = new List<DesktopFolder.FolderManager>();
            List<DesktopFolder.NoteManager>   updated_note_list   = new List<DesktopFolder.NoteManager>();
            List<DesktopFolder.PhotoManager>  updated_photo_list  = new List<DesktopFolder.PhotoManager>();
            int totalFolders = 0;
            int totalNotes   = 0;
            int totalPhotos  = 0;
            while ((file_info = enumerator.next_file ()) != null) {
                string   name = file_info.get_name ();
                File     file = File.new_for_commandline_arg (base_path + "/" + name);
                FileType type = file.query_file_type (FileQueryInfoFlags.NONE);

                if (type == FileType.DIRECTORY) {
                    totalFolders++;

                    // Is this folder already known about?
                    DesktopFolder.FolderManager fm = this.find_folder_by_name (name);

                    if (fm == null) {
                        // No, it's a new folder
                        fm = new DesktopFolder.FolderManager (this, name);
                    } else {
                        this.folders.remove (fm);
                    }
                    updated_folder_list.append (fm);
                } else {
                    string basename = file.get_basename ();
                    int    index    = basename.last_index_of (".", 0);
                    if (index > 0) {
                        string ext       = basename.substring (index + 1);
                        string file_name = basename.substring (0, index);
                        if (ext == DesktopFolder.NOTE_EXTENSION) {
                            totalNotes++;

                            // Is this note already known about?
                            DesktopFolder.NoteManager nm = this.find_note_by_name (file_name);

                            if (nm == null) {
                                // No, it's a new note
                                nm = new DesktopFolder.NoteManager (this, basename.substring (0, index), file);
                            } else {
                                this.notes.remove (nm);
                            }
                            updated_note_list.append (nm);
                        } else if (ext == DesktopFolder.PHOTO_EXTENSION) {
                            totalPhotos++;

                            // Is this photo already known about?
                            DesktopFolder.PhotoManager pm = this.find_photo_by_name (file_name);

                            if (pm == null) {
                                // No, it's a new photo
                                pm = new DesktopFolder.PhotoManager (this, basename.substring (0, index), file);
                            } else {
                                this.photos.remove (pm);
                            }
                            updated_photo_list.append (pm);
                        }
                    }
                    // nothing
                    // we only deal with folders to be shown
                }
            }

            // finally we close any other not existent folder
            while (this.folders.length () > 0) {
                DesktopFolder.FolderManager fm = this.folders.nth (0).data;
                fm.close ();
                this.folders.remove (fm);
            }
            this.folders = updated_folder_list.copy ();

            // finally we close any other not existent note
            while (this.notes.length () > 0) {
                DesktopFolder.NoteManager nm = this.notes.nth (0).data;
                nm.close ();
                this.notes.remove (nm);
            }
            this.notes = updated_note_list.copy ();

            // finally we close any other not existent photo
            while (this.photos.length () > 0) {
                DesktopFolder.PhotoManager pm = this.photos.nth (0).data;
                pm.close ();
                this.photos.remove (pm);
            }
            this.photos = updated_photo_list.copy ();

            // by default, at least one folder is needed
            if (totalFolders == 0 && totalPhotos == 0 && totalNotes == 0) {
                DirUtils.create (DesktopFolderApp.get_app_folder () + "/" + DesktopFolder.Lang.APP_FIRST_PANEL, 0755);
                this.sync_folders_and_notes ();
            }
        } catch (Error e) {
            // error! ??
            stderr.printf ("Error: %s\n", e.message);
            DesktopFolder.Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name count_widgets
     * @description return the amount of widgets existing
     * @return {int} the total widgets currently shown
     */
    public uint count_widgets () {
        return this.photos.length () + this.notes.length () + this.folders.length ();
    }

    /**
     * @name find_folder_by_name
     * @description find a foldermanager managed by its name
     * @param string folder_name the name of the folder to find
     * @return FolderManager the Folder found or null if none
     */
    private DesktopFolder.FolderManager ? find_folder_by_name (string folder_name) {
        for (int i = 0 ; i < this.folders.length () ; i++) {
            DesktopFolder.FolderManager fm = this.folders.nth (i).data;
            if (fm.get_folder_name () == folder_name) {
                return fm;
            }
        }
        return null;
    }

    /**
     * @name find_note_by_name
     * @description find a notemanager managed by its name
     * @param string note_name the name of the note to find
     * @return NoteManager the Note found or null if none
     */
    private DesktopFolder.NoteManager ? find_note_by_name (string note_name) {
        for (int i = 0 ; i < this.notes.length () ; i++) {
            DesktopFolder.NoteManager nm = this.notes.nth (i).data;
            if (nm.get_note_name () == note_name) {
                return nm;
            }
        }
        return null;
    }

    /**
     * @name find_photo_by_name
     * @description find a photomanager managed by its name
     * @param string photo_name the name of the photo to find
     * @return PhotoManager the Photo found or null if none
     */
    private DesktopFolder.PhotoManager ? find_photo_by_name (string photo_name) {
        for (int i = 0 ; i < this.photos.length () ; i++) {
            DesktopFolder.PhotoManager nm = this.photos.nth (i).data;
            if (nm.get_photo_name () == photo_name) {
                return nm;
            }
        }
        return null;
    }

    /**
     * @name exist_manager
     * @description Check if the folder_name is being monitored or not
     * @return bool true->yes, it is being monitored
     */
    public bool exist_manager (string folder_name) {
        for (int i = 0 ; i < this.folders.length () ; i++) {
            DesktopFolder.FolderManager fm = this.folders.nth (i).data;
            if (fm.get_folder_name () == folder_name) {
                return true;
            }
        }
        return false;
    }

    /**
     * @name monitor_desktop
     * @description Monitor the desktop folder
     */
    private void monitor_desktop () {
        try {
            if (this.monitor != null) {
                // if we have an existing monitor, we cancel it before to monitor again
                this.monitor.cancel ();
            }
            var  basePath  = DesktopFolderApp.get_app_folder ();
            File directory = File.new_for_path (basePath);
            this.monitor            = directory.monitor_directory (FileMonitorFlags.SEND_MOVED, null);
            this.monitor.rate_limit = 100;
            debug ("Monitoring: %s\n", directory.get_path ());
            this.monitor.changed.connect (this.desktop_changed);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            DesktopFolder.Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name desktop_changed
     * @description We received an event of the monitor that indicates a change
     * @see changed signal of FileMonitor (https://valadoc.org/gio-2.0/GLib.FileMonitor.changed.html)
     */
    private void desktop_changed (GLib.File src, GLib.File ? dest, FileMonitorEvent event) {
        // something changed at the desktop folder
        bool flagNote   = false;
        bool flagPhoto  = false;

        string basename = src.get_basename ();
        int    index    = basename.last_index_of (".", 0);
        if (index > 0) {
            string ext = basename.substring (index + 1);
            if (ext == DesktopFolder.NOTE_EXTENSION) {
                flagNote = true;
            } else if (ext == DesktopFolder.PHOTO_EXTENSION) {
                flagPhoto = true;
            }
        }

        // new content inside
        var file_type = src.query_file_type (FileQueryInfoFlags.NONE);
        if (flagNote || flagPhoto || file_type == FileType.DIRECTORY || !src.query_exists ()) {
            // debug("Desktop - Change Detected");
            // new directory or removed, we need to synchronize
            // removed directory
            this.sync_folders_and_notes ();
        }
    }

    /**
     * @name clear_all
     * @description Close all the folders launched
     */
    protected void clear_all () {
        for (int i = 0 ; i < this.folders.length () ; i++) {
            DesktopFolder.FolderManager fm = this.folders.nth (i).data;
            fm.close ();
        }
        this.folders = new List<DesktopFolder.FolderManager>();
    }

    /**
     * Main application
     */
    public static int main (string[] args) {
        if (args.length > 1 && args[1].up () == DesktopFolder.PARAM_SHOW_DESKTOP.up ()) {
            minimize_all (args);
            return 0;
        } else {
            var app = new DesktopFolderApp ();
            return app.run (args);
        }
    }

    /**
     * @name minimize_all
     * @description Minimize all windows
     * @param args string[] the list of args to initialize Gdk
     */
    private static void minimize_all (string[] args) {
        Gdk.init (ref args);
        Wnck.Screen screen = Wnck.Screen.get_default ();
        while (Gtk.events_pending ()) {
            Gtk.main_iteration ();
        }

        unowned List<Wnck.Window> windows = screen.get_windows ();

        foreach (Wnck.Window w in windows) {
            Wnck.Application window_app = w.get_application ();
            string           name       = window_app.get_name ();
            // debug("app name:%s",name);
            if (name != DesktopFolder.APP_ID) {
                w.minimize ();
            }
        }
    }

    /**
     * @name create_shortcut
     * @description Create shortcut SUPER + D in the system shortcuts to minimize all windows
     */
    private static void create_shortcut () {
        string path                        = "/usr/bin/"; // we expect to have the command at the path
        Pantheon.Keyboard.Shortcuts.CustomShortcutSettings.init ();
        var    shortcut                    = new Pantheon.Keyboard.Shortcuts.Shortcut (100, Gdk.ModifierType.SUPER_MASK);
        string command_conflict            = "";
        string relocatable_schema_conflict = "";
        if (!Pantheon.Keyboard.Shortcuts.CustomShortcutSettings.shortcut_conflicts (shortcut, out command_conflict,
                                                                                    out relocatable_schema_conflict)) {

            debug ("registering hotkey!");
            var relocatable_schema = Pantheon.Keyboard.Shortcuts.CustomShortcutSettings.create_shortcut ();
            Pantheon.Keyboard.Shortcuts.CustomShortcutSettings.edit_command ((string) relocatable_schema,
                                                                             path + "com.github.spheras.desktopfolder " + DesktopFolder.PARAM_SHOW_DESKTOP);
            Pantheon.Keyboard.Shortcuts.CustomShortcutSettings.edit_shortcut ((string) relocatable_schema,
                                                                              shortcut.to_gsettings ());
        }
    }

}
