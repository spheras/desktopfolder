/*
 *  NOTE: This is an adaptation of the ClipboardManager class from elementary Files project.
 *
 *  Copyright (c) 2016 elementary LLC (http://launchpad.net/elementary)
 *
 *  Based on C code imported from Thunar
 *  Copyright (c) 2005-2006 Benedikt Meurer <benny@xfce.org>
 *  Copyright (c) 2009 Jannis Pohlmann <jannis@xfce.org>*
 *  Copyright (c) 2017-2019 José Amuedo (https://github.com/spheras)
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
 *
 *   Author(s):  Jeremy Wootten <jeremy@elementaryos.org>
 *
 */

namespace DesktopFolder.Clipboard {

    public class ClipboardManager : GLib.Object {
        private enum ClipboardTarget {
            GNOME_COPIED_FILES,
            UTF8_STRING
        }

        private static GLib.Quark marlin_clipboard_manager_quark = GLib.Quark.from_string ("marlin-clipboard-manager");
        private static Gdk.Atom x_special_gnome_copied_files = Gdk.Atom.intern_static_string ("x-special/gnome-copied-files");
        private const Gtk.TargetEntry[] clipboard_targets    = {
            { "x-special/gnome-copied-files", 0, ClipboardTarget.GNOME_COPIED_FILES },
            { "UTF8_STRING", 0, ClipboardTarget.UTF8_STRING }
        };

        private Gtk.Clipboard clipboard;
        private GLib.List <ClipboardFile> files = null;

        private bool files_cutted               = false;

        /** Returns TRUE if the contents of the clipboard can be pasted into a folder.
        **/
        public bool can_paste { get; private set; default = false; }

        public signal void changed ();

        private ClipboardManager (Gtk.Clipboard _clipboard) {
            clipboard = _clipboard;
            clipboard.set_qdata (marlin_clipboard_manager_quark, this);

            clipboard.owner_change.connect (owner_changed);
        }

        public static ClipboardManager ? get_for_display (Gdk.Display ? display = Gdk.Display.get_default ()) {
            if (display == null) {
                critical ("ClipboardManager cannot find display");
                assert_not_reached ();
            }

            var clipboard = Gtk.Clipboard.get_for_display (display, Gdk.SELECTION_CLIPBOARD);
            ClipboardManager ? manager = clipboard.get_qdata (marlin_clipboard_manager_quark);

            if (manager != null) {
                return manager;
            } else {
                return new ClipboardManager (clipboard);
            }
        }

        ~ClipboardManager () {
            release_pending_files ();
            clipboard.owner_change.disconnect (owner_changed);
        }

        /** If @file is null, returns whether there are ANY cut files
         * otherwise whether @file is amongst the cut files
         **/
        public bool has_cutted_file (ClipboardFile ? file) {
            // debug("has_cutted_file!!!");
            return files_cutted && (file == null || has_file (file));
        }

        public bool has_file (ClipboardFile file) {
            // debug("has_file!!!");
            return files != null && (files.find (file) != null);
        }

        public void copy_files (GLib.List <ClipboardFile> files) {
            // debug("copy_files!!!");
            transfer_files (true, files);
        }

        public void cut_files (GLib.List <ClipboardFile> files) {
            // debug("cut_files!!!");
            transfer_files (false, files);
        }

        /**
         * @target_file        : the #GFile of the folder to which the contents on the clipboard
         *                       should be pasted.
         * @widget             : a #GtkWidget, on which to perform the paste or %NULL if no widget is
         *                       known.
         * @new_files_callback : a #GCallback to connect to the job's "new-files" signal,
         *                       which will be emitted when the job finishes with the
         *                       list of #GFile<!---->s created by the job, or
         *                       %NULL if you're not interested in the signal.
         *
         * Pastes the contents from the clipboard to the directory
         * referenced by @target_file.
         **/
        public void paste_files (GLib.File target_file,
            Gtk.Widget ?                   widget = null,
            GLib.Callback ?                new_files_callback = null) {

            // debug("paste_files!!!");
            /**
             *  @cb the clipboard.
             *  @sd selection_data returned from the clipboard.
             **/
            clipboard.request_contents (x_special_gnome_copied_files, (cb, sd) => {
                contents_received (sd, target_file, widget, new_files_callback);
            });

        }

        private void contents_received (Gtk.SelectionData sd,
            GLib.File                                     target_file,
            Gtk.Widget ?                                  widget = null,
            GLib.Callback ?                               new_files_callback = null) {

            // debug("contents_received!!!");

            /* check whether the retrieval worked */
            string ? text;

            if (!DragnDrop.DndHandler.selection_data_is_uri_list (sd, DragnDrop.TargetType.TEXT_URI_LIST, out text)) {
                warning ("Selection data not uri_list in Marlin.ClipboardManager contents_received");
                return;
            }

            if (text == null) {
                warning ("Empty selection data in Marlin.ClipboardManager contents_received");
                DesktopFolder.Util.show_error_dialog (null, DesktopFolder.Lang.CLIPBOARD_EMPTY);
                return;
            }

            Gdk.DragAction action = 0;
            if (text.has_prefix ("copy")) {
                action = Gdk.DragAction.COPY;
                text   = text.substring (4);
            } else if (text.has_prefix ("cut")) {
                action = Gdk.DragAction.MOVE;
                text   = text.substring (3);
            } else {
                warning ("Invalid selection data in Marlin.ClipboardManager contents_received");
                DesktopFolder.Util.show_error_dialog (null, DesktopFolder.Lang.CLIPBOARD_EMPTY);
                return;
            }

            List <File> file_list = DragnDrop.Util.list_new_from_string (text);

            if (file_list != null) {
                DragnDrop.Util.copy_move (file_list,
                    target_file,
                    action,
                    widget,
                    new_files_callback,
                    widget);
            }

            /* clear the clipboard if it contained "cutted data"
             * (gtk_clipboard_clear takes care of not clearing
             * the selection if we don't own it)
             */
            if (action != Gdk.DragAction.COPY) {
                clipboard.clear ();
            }
            /* check the contents of the clipboard again if either the Xserver or
             * our GTK+ version doesn't support the XFixes extension */
            if (!clipboard.get_display ().supports_selection_notification ()) {
                owner_changed (null);
            }
        }

        private void owner_changed (Gdk.Event ? owner_change_event) {
            // debug("owner_changed!!!");
            clipboard.request_contents (Gdk.Atom.intern_static_string ("TARGETS"), (cb, sd) => {
                can_paste = false;
                Gdk.Atom[] targets = null;

                sd.get_targets (out targets);
                foreach (var target in targets) {
                    if (target == x_special_gnome_copied_files) {
                        can_paste = true;
                        break;
                    }
                }

                /* notify listeners that we have a new clipboard state */
                changed ();
                notify_property ("can-paste");
            });
        }

        /**
         * Sets the clipboard to contain @files_for_transfer and marks them to be copied
         * or moved according to @copy when the user pastes from the clipboard.
         **/
        private void transfer_files (bool copy, GLib.List <ClipboardFile> files_for_transfer) {
            // debug("transfer_files!!!");
            release_pending_files ();
            files_cutted = !copy;

            /* setup the new file list */
            foreach (var file in files_for_transfer) {
                files.prepend (file);
                file.on_delete.connect (on_file_destroyed);
            }

            /* acquire the Clipboard ownership */
            clipboard.set_with_owner (clipboard_targets, get_callback, clear_callback, this);

            /* Need to fake a "owner-change" event here if the Xserver doesn't support clipboard notification */
            if (!clipboard.get_display ().supports_selection_notification ()) {
                owner_changed (null);
            }
        }

        private void on_file_destroyed (ClipboardFile file) {
            // debug("on_file_destroyed!!!");
            file.on_delete.disconnect (on_file_destroyed);
            files.remove (file);
        }

        public static void get_callback (Gtk.Clipboard cb, Gtk.SelectionData sd, uint target_info, void * parent) {
            // debug("get_callback!!!");
            var manager = parent as ClipboardManager;
            if (manager == null || manager.clipboard != cb) {
                return;
            }

            switch (target_info) {
            case ClipboardTarget.GNOME_COPIED_FILES:
                string prefix = manager.files_cutted ? "cut" : "copy";
                DragnDrop.DndHandler.set_selection_data_from_file_list (sd,
                    manager.files,
                    prefix);
                break;
            case ClipboardTarget.UTF8_STRING: /* Not clear what this is for */
                var str = manager.file_list_to_string ();
                sd.set_text (str, str.length);
                break;
            default:
                assert_not_reached ();
            }
        }

        private string file_list_to_string () {
            // debug("file_list_to_string!!!");
            var  sb         = new StringBuilder ("");
            uint count      = 0;
            uint file_count = files.length ();
            foreach (var file in files) {
                var loc = file.get_target_location ();
                var pn  = loc.get_parse_name ();
                if (pn != null) {
                    sb.append (pn);
                } else {
                    sb.append (loc.get_uri ());
                }

                if (count < file_count) {
                    sb.append ("\n");
                }
                count++;
            }
            return sb.str;
        }

        public static void clear_callback (Gtk.Clipboard cb, void * parent) {
            // debug("clear_callback!!!");
            var manager = (ClipboardManager) parent;
            if (manager == null || manager.clipboard != cb) {
                return;
            }

            manager.release_pending_files ();
        }

        private void release_pending_files () {
            // debug("release_pending_files!!!");
            foreach (var file in this.files) {
                file.on_delete.disconnect (on_file_destroyed);
            }

            files = null;
        }

    }
}
