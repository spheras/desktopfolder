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
 * ATTENTION! MOST OF THIS CODE HAS BEEN TAKEN AND ADAPTED FROM ELEMENTARY OS FILES PROJECT.
 */
namespace DesktopFolder.DragnDrop {

    public enum TargetType {
        STRING,
        TEXT_URI_LIST,
        XDND_DIRECT_SAVE0,
        NETSCAPE_URL
    }

    public const Gtk.TargetEntry[] drag_targets = {
        { "text/plain", Gtk.TargetFlags.SAME_APP, DragnDrop.TargetType.STRING },
        { "text/uri-list", Gtk.TargetFlags.SAME_APP, DragnDrop.TargetType.TEXT_URI_LIST }
    };

    public const Gtk.TargetEntry[] drop_targets = {
        { "text/uri-list", Gtk.TargetFlags.SAME_APP, DragnDrop.TargetType.TEXT_URI_LIST },
        { "text/uri-list", Gtk.TargetFlags.OTHER_APP, DragnDrop.TargetType.TEXT_URI_LIST },
        { "XdndDirectSave0", Gtk.TargetFlags.OTHER_APP, DragnDrop.TargetType.XDND_DIRECT_SAVE0 },
        { "_NETSCAPE_URL", Gtk.TargetFlags.OTHER_APP, DragnDrop.TargetType.NETSCAPE_URL }
    };

    public const Gdk.DragAction file_drag_actions = (Gdk.DragAction.COPY | Gdk.DragAction.MOVE | Gdk.DragAction.LINK);




    /**
     * A set of Util DragNDrop functions
     */
    namespace Util {

        /**
         * @name is_folder
         * @description check if a certain file is a folder or not
         * @param File file the file to check
         * @return boole true->yes, the file is a folder
         */
        public bool is_folder (File file) {
            // debug("Util-is_folder");
            FileType type = file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            return type == FileType.DIRECTORY;
        }

        /**
         * @name is_tarshed
         * @description check whether the file is in trash or not
         * @return bool true->yes, it is in trash
         */
        public bool is_trashed (File file) {
            // debug("Util-is_trashed");
            return file.has_uri_scheme ("trash");
        }

        public string get_display_target_uri (File file) {
            // debug("Util-get_display_target_uri");
            try {
                var fileInfo = file.query_info (FileAttribute.STANDARD_TARGET_URI, FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
                var uri      = fileInfo.get_attribute_as_string (FileAttribute.STANDARD_TARGET_URI);

                if (uri == null) {
                    uri = "" + file.get_uri ();
                }

                return uri;
            } catch (Error error) {
                stderr.printf ("Error: %s\n", error.message);
                return "";
            }
        }

        public bool same_filesystem (File file_a, File file_b) {
            // debug("Util-same_filesystem");
            string filesystem_id_a;
            string filesystem_id_b;

            FileInfo ainfo = null;
            FileInfo binfo = null;
            try {
                ainfo = file_a.query_filesystem_info ("*", null);
                binfo = file_b.query_filesystem_info ("*", null);
            } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
            }

            /* return false if we have no information about one of the files */
            if (ainfo == null || binfo == null)
                return false;

            /* determine the filesystem IDs */
            filesystem_id_a = ainfo.get_attribute_string (FileAttribute.ID_FILESYSTEM);

            filesystem_id_b = binfo.get_attribute_string (FileAttribute.ID_FILESYSTEM);

            /* compare the filesystem IDs */
            return filesystem_id_a == filesystem_id_b;
        }

        /**
         * gof_file_accepts_drop (imported from thunar):
         * @file                    : a #GOFFile instance.
         * @file_list               : the list of #GFile<!---->s that will be droppped.
         * @context                 : the current #GdkDragContext, which is used for the drop.
         * @suggested_action_return : return location for the suggested #GdkDragAction or %NULL.
         *
         * Checks whether @file can accept @path_list for the given @context and
         * returns the #GdkDragAction<!---->s that can be used or 0 if no actions
         * apply.
         *
         * If any #GdkDragAction<!---->s apply and @suggested_action_return is not
         * %NULL, the suggested #GdkDragAction for this drop will be stored to the
         * location pointed to by @suggested_action_return.
         *
         * Return value: the #GdkDragAction<!---->s supported for the drop or
         *               0 if no drop is possible.
         **/

        Gdk.DragAction file_accepts_drop (File file,
            List <File>                        file_list,
            Gdk.DragContext                    context,
            out Gdk.DragAction                 suggested_action_return) {
            // debug("Util-file_accepts_drop");
            Gdk.DragAction suggested_action;
            Gdk.DragAction actions;
            File           ofile;
            File           parent_file;
            uint           n;
            int i = 0;
            suggested_action_return = Gdk.DragAction.PRIVATE;

            /* we can never drop an empty list */
            if (file_list == null)
                return 0;

            /* default to whatever GTK+ thinks for the suggested action */
            suggested_action = context.get_suggested_action ();

            /* check if we have a writable directory here or an executable file */
            if (is_folder (file)) { // TODO && gof_file_is_writable (file))
                // debug("Util-file_accepts_drop");
                /* determine the possible actions */
                actions = context.get_actions () & (Gdk.DragAction.COPY | Gdk.DragAction.MOVE
                    | Gdk.DragAction.LINK | Gdk.DragAction.ASK);


                /* check up to 100 of the paths (just in case somebody tries to
                 * drag around his music collection with 5000 files).
                 */

                for (n = 0, i = 0; i < file_list.length () && n < 100; i++, n++) { // lp = file_list, n = 0; lp != NULL && n < 100; lp = lp->next, ++n)
                    File fi = file_list.nth (i).data;
                    /* we cannot drop a file on itself */
                    if (file.equal (fi))
                        return 0;

                    /* check whether source and destination are the same */
                    parent_file = fi.get_parent ();
                    if (parent_file != null) {
                        if (file.equal (parent_file)) {
                            // this should be forbidden, but I dont know why, it is being memorized in some way,
                            // it is asked only once, and we cannot unset in the future..
                            // So, we allow copy/move/link and after, it is discarded if it was really the same folder.
                            // TODO, need to be further investigated.
                            parent_file.unref ();
                            suggested_action = Gdk.DragAction.COPY; // Gdk.DragAction.ASK;
                            actions          = Gdk.DragAction.COPY | Gdk.DragAction.MOVE | Gdk.DragAction.LINK; // Gdk.DragAction.ASK|Gdk.DragAction.LINK;
                        } else
                            parent_file.unref ();
                    }

                    /* Make these tests at the end so that any changes are not reversed subsequently */
                    string scheme;
                    scheme = fi.get_uri_scheme ();
                    if (!scheme.has_prefix ("file")) {
                        /* do not allow symbolic links from remote filesystems */
                        actions &= ~(Gdk.DragAction.LINK);
                    }

                    /* copy/move/link within the trash not possible */
                    if (is_trashed (fi) && is_trashed (file))
                        return 0;
                }

                /* if the source offers both copy and move and the GTK+ suggested action is copy, try to
                 * be smart telling whether we should copy or move by default by checking whether the
                 * source and target are on the same disk. */
                if ((actions & (Gdk.DragAction.COPY | Gdk.DragAction.MOVE)) != 0
                    && (suggested_action == Gdk.DragAction.COPY)) {
                    /* default to move as suggested action */
                    suggested_action = Gdk.DragAction.MOVE;

                    /* check for up to 100 files, for the reason state above */
                    for (i = 0, n = 0; i < file_list.length () && n < 100; i++, n++) { // for (lp = file_list, n = 0; lp != NULL && n < 100; lp = lp->next, ++n)
                        File fi = file_list.nth (i).data;
                        /* dropping from the trash always suggests move */
                        if (is_trashed (fi))
                            break;

                        /* determine the cached version of the source file */
                        ofile = fi; // gof_file_get(lp->data);
                        FileInfo oinfo = null;
                        try {
                            oinfo = ofile.query_filesystem_info ("*", null);
                        } catch (Error error) {
                            stderr.printf ("Error: %s\n", error.message);
                        }

                        /* we have only move if we know the source and both the source and the target
                         * are on the same disk, and the source file is owned by the current user.
                         */
                        if (ofile == null
                            || !same_filesystem (file, ofile)
                            || (oinfo != null)) {
                            // && ofile->uid > -1
                            // && ofile->uid != effective_user_id ))
                            /* default to copy and get outa here */
                            suggested_action = Gdk.DragAction.COPY;
                            break;
                        }
                    }
                }
            } else if (!is_folder (file)) { // && gof_file_is_executable (file))
                /* determine the possible actions */
                actions = context.get_actions () & (Gdk.DragAction.COPY | Gdk.DragAction.MOVE | Gdk.DragAction.LINK
                    | Gdk.DragAction.PRIVATE);
            } else {
                debug ("Not a valid drop target");
                return 0;
            }

            /* Make these tests at the end so that any changes are not reversed subsequently */
            string scheme;
            scheme = file.get_uri_scheme ();
            /* do not allow symbolic links to remote filesystems */
            if (!scheme.has_prefix ("file"))
                actions &= ~(Gdk.DragAction.LINK);

            /* cannot create symbolic links in the trash or copy to the trash */
            if (is_trashed (file))
                actions &= ~(Gdk.DragAction.COPY | Gdk.DragAction.LINK);

            if (actions == Gdk.DragAction.ASK) {
                /* No point in asking if there are no allowed actions */
                return 0;
            }

            /* determine the preferred action based on the context */
            /* determine a working action */
            if (actions != 0) {
                suggested_action_return = suggested_action;
            } else if ((actions & Gdk.DragAction.ASK) != 0) {
                suggested_action_return = Gdk.DragAction.ASK;
            } else if ((actions & Gdk.DragAction.COPY) != 0) {
                suggested_action_return = Gdk.DragAction.COPY;
            } else if ((actions & Gdk.DragAction.LINK) != 0) {
                suggested_action_return = Gdk.DragAction.LINK;
            } else if ((actions & Gdk.DragAction.MOVE) != 0) {
                suggested_action_return = Gdk.DragAction.MOVE;
            } else {
                suggested_action_return = Gdk.DragAction.PRIVATE;
            }
            /* yeppa, we can drop here */
            return actions;
        }

        /**
         * eel_g_file_list_new_from_string:
         * @string : a string representation of an URI list.
         *
         * Splits an URI list conforming to the text/uri-list
         * mime type defined in RFC 2483 into individual URIs,
         * discarding any comments and whitespace. The resulting
         * list will hold one #GFile for each URI.
         *
         * If @string contains no URIs, this function
         * will return %NULL.
         *
         * Return value: the list of #GFile<!---->s or %NULL.
         **/
        public List <File> list_new_from_string (string str) {
            // debug("Util-list_new_from_string");
            List <File> list = new List <File>();
            string[]    uris;
            uris = Uri.list_extract_uris (str);

            for (int n = 0; uris != null && uris[n] != null; ++n) {
                list.append (File.new_for_uri (uris[n]));
            }

            return list;
        }

        public void copy_move (List <File> files,
            File                           target_dir,
            Gdk.DragAction                 action,
            Gtk.Widget ?                   parent_view,
            GLib.Callback ?                done_callback,
            Gtk.Widget ?                   done_callback_data) {

            if (target_dir.query_exists ()) {
                for (int i = 0; files != null && i < files.length (); i++) {
                    File f = files.nth (i).data;
                    if (f.query_exists ()) {

                        string path        = f.get_path ();
                        string new_name    = f.get_basename ();
                        string target_path = target_dir.get_path ();
                        // string link_to     = DesktopFolder.Lang.LINK_TO;

                        if ((path.has_prefix ("/usr/local/share/applications/") ||
                            path.has_prefix ("/usr/share/") ||
                            path.contains ("/.local/share/applications/")) &&
                            path.has_suffix (".desktop")) {
                            // we don't move user desktop launchers
                            if (action == Gdk.DragAction.MOVE) {
                                action = Gdk.DragAction.COPY;
                            }
                        }

                        debug (@"$action, $(f.get_parent ().get_path ()) -> $target_path");

                        if (action == Gdk.DragAction.COPY) {
                            File final_target               = File.new_for_path (target_path + "/" + f.get_basename ());

                            DesktopFolder.ProgressDialog pd = new DesktopFolder.ProgressDialog (DesktopFolder.Lang.DRAGNDROP_FILE_OPERATIONS, (Gtk.Window)parent_view);
                            GLib.Cancellable cancellable    = pd.start ();

                            try {
                                new Thread <int> .try ("DesktopFolder File Operation", () => {
                                        try {
                                            DesktopFolder.Util.copy_recursive (f,
                                            final_target,
                                            GLib.FileCopyFlags.NONE,
                                            cancellable,
                                            (file) => {
                                                string message = DesktopFolder.Lang.DRAGNDROP_COPYING;
                                                message = message + " " + file.get_path ();
                                                pd.show_action (message);
                                            });
                                        } catch (Error e) {
                                            cancellable.cancel ();
                                            stderr.printf ("Error: %s\n", e.message);
                                        }
                                        pd.stop ();
                                        return 0;
                                    });

                                if (done_callback != null)
                                    done_callback ();

                            } catch (Error error) {
                                cancellable.cancel ();
                                pd.stop ();
                                stderr.printf ("Error: %s\n", error.message);
                            }
                        } else if (action == Gdk.DragAction.MOVE) {
                            try {
                                File final_target = File.new_for_path (target_path + "/" + f.get_basename ());
                                f.move (final_target, FileCopyFlags.NONE, null, null);
                                if (done_callback != null)
                                    done_callback ();
                            } catch (Error error) {
                                stderr.printf ("Error: %s\n", error.message);
                            }
                        } else if (action == Gdk.DragAction.LINK) {
                            try {
                                var target_file = File.new_for_path (@"$target_path/$new_name");
                                if (!target_file.query_exists ()) {
                                    var command = @"ln -s \"$(f.get_path ())\" \"$target_path/$new_name\"";
                                    var appinfo = AppInfo.create_from_commandline (command, null, AppInfoCreateFlags.SUPPORTS_URIS);
                                    appinfo.launch_uris (null, null);
                                }
                            } catch (Error error) {
                                stderr.printf ("Error: %s\n", error.message);
                            }
                        } else {
                            debug ("unknown action!");
                        }
                    }
                }
            }
        }

    }
}
