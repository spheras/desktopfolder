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

namespace DesktopFolder.DragnDrop {

    public class DndBehaviour {
        private bool drop_occurred = false; /* whether the data was dropped */
        private bool drop_data_ready = false; /* whether the drop data was received already */
        private bool drag_has_begun = false;
        /* NEVER USED
        private bool dnd_disabled = false;
        */

        private unowned GLib.List<GLib.File> drag_file_list = null;
        private GLib.List<GLib.File> drop_file_list = null; /* the list of URIs that are contained in the drop data */
        private GLib.List<GLib.File> selected_files = null;
        private Gdk.DragAction current_suggested_action = Gdk.DragAction.DEFAULT;
        private Gdk.DragAction current_actions = Gdk.DragAction.DEFAULT;
        private bool draggable=false;
        private bool droppable=false;
        private DndView view=null;
        private Gdk.Atom current_target_type = Gdk.Atom.NONE;
        private GLib.File drop_target_file = null;

        /* drag support */
        uint drag_scroll_timer_id = 0;
        uint drag_enter_timer_id = 0;
        /* NEVER USED
        uint drag_timer_id = 0;
        int drag_x = 0;
        int drag_y = 0;
        int drag_button;
        */
        protected int drag_delay = 300;
        protected int drag_enter_delay = 1000;
        protected bool should_activate = false;

        public DndBehaviour(DndView view, bool draggable, bool droppable){
            this.view=view;
            this.draggable=draggable;
            this.droppable=droppable;
            this.connect_drag_drop_signals();
        }

        /**
        * @name connect_drag_drop_signals
        * @description connect with the drag and drop signals a widget
        */
        protected void connect_drag_drop_signals () {
            if(this.droppable){
                /* Set up as drop site */
                Gtk.drag_dest_set (this.view.get_widget(), Gtk.DestDefaults.MOTION, drop_targets, Gdk.DragAction.ASK | file_drag_actions);
                this.view.get_widget().drag_drop.connect (on_drag_drop);
                this.view.get_widget().drag_data_received.connect (on_drag_data_received);
                this.view.get_widget().drag_leave.connect (on_drag_leave);
                this.view.get_widget().drag_motion.connect (on_drag_motion);
            }

            if(this.draggable){
                /* Set up as drag source */
                Gtk.drag_source_set (this.view.get_widget(), Gdk.ModifierType.BUTTON1_MASK, drag_targets, file_drag_actions);
                this.view.get_widget().drag_begin.connect (on_drag_begin);
                this.view.get_widget().drag_data_get.connect (on_drag_data_get);
                this.view.get_widget().drag_data_delete.connect (on_drag_data_delete);
                this.view.get_widget().drag_end.connect (on_drag_end);
            }
        }


        private void on_drag_begin (Gdk.DragContext context) {
            drag_has_begun = true;
            should_activate = false;
        }

        private void on_drag_data_get (Gdk.DragContext context,
                                        Gtk.SelectionData selection_data,
                                        uint info,
                                        uint timestamp) {

             drag_file_list = get_selected_files_for_transfer ();

             if (drag_file_list == null) {
                 return;
             }

             /* NEVER USED
             File file = drag_file_list.first ().data;
             */

             /* TODO custom file icon
             if (file != null && file.pix != null)
                 Gtk.drag_set_icon_pixbuf (context, file.pix, 0, 0);
             else
             */
                 Gtk.drag_set_icon_name (context, "stock-file", 0, 0);

             DndHandler.set_selection_data_from_file_list_2 (selection_data, drag_file_list);
         }

         private void on_drag_data_delete (Gdk.DragContext context) {
             /* block real_view default handler because handled in on_drag_end */
             GLib.Signal.stop_emission_by_name (this.view.get_widget(), "drag-data-delete");
         }

         private void on_drag_end (Gdk.DragContext context) {
             //debug("on_drag_end");
             cancel_timeout (ref drag_scroll_timer_id);
             drag_file_list = null;
             drop_target_file = null;
             drop_file_list = null;
             drop_data_ready = false;

             current_suggested_action = Gdk.DragAction.DEFAULT;
             current_actions = Gdk.DragAction.DEFAULT;
             drag_has_begun = false;
             drop_occurred = false;
         }


         public unowned GLib.List<File> get_selected_files () {
             return selected_files;
         }

         protected unowned GLib.List<File> get_selected_files_for_transfer (GLib.List<unowned File> selection = get_selected_files ()) {
            unowned GLib.List<File> list = null;

            selection.@foreach ((file) => {
                list.prepend (file);
            });

            list.reverse ();

            return list;
        }

        /**
        * @name on_drag_drop
        * @description the drag_drop event captured. @see drag_drop signal
        * @param DragContext context @see drag_drop signal
        * @param int x @see drag_drop signal
        * @param int y @see drag_drop signal
        * @param uint timestamp @see drag_drop signal
        * @return bool  @see drag_drop signal
        */
        private bool on_drag_drop (Gdk.DragContext context,
                               int x,
                               int y,
                               uint timestamp) {
            //debug("on_drag_drop");
            Gtk.TargetList list = null;
            string? uri = null;
            bool ok_to_drop = false;

            Gdk.Atom target = Gtk.drag_dest_find_target  (this.view.get_widget(), context, list);

            if (target == Gdk.Atom.intern_static_string ("XdndDirectSave0")) {
                File target_file=this.view.get_file_at(x, y);
                if (target_file != null) {
                    /* get XdndDirectSave file name from DnD source window */
                    string? filename = DndHandler.get_instance().get_source_filename (context);
                    if (filename != null) {
                        /* Get uri of source file when dropped */
                        uri = target_file.resolve_relative_path (filename).get_uri ();
                        /* Setup the XdndDirectSave property on the source window */
                        DndHandler.get_instance().set_source_uri (context, uri);
                        ok_to_drop = true;
                    } else{
                        DesktopFolder.Util.show_error_dialog (DesktopFolder.Lang.CANT_DROP, DesktopFolder.Lang.CANT_DROP_INVALID_FILE_NAME);
                    }
                }
            } else
                ok_to_drop = (target != Gdk.Atom.NONE);

            if (ok_to_drop) {
                drop_occurred = true;
                /* request the drag data from the source (initiates
                 * saving in case of XdndDirectSave).*/
                Gtk.drag_get_data (this.view.get_widget(), context, target, timestamp);
            }

            return ok_to_drop;
        }

        /**
        * @name on_drag_data_received
        * @description the drag_data_received event. @see drag_drop signal
        * @param DragContext context @see drag_drop signal
        * @param x int @see drag_drop signal
        * @param y int @see drag_drop signal
        * @param selectionData selection-data @see drag_drop signal
        * @param uint info @see drag_drop signal
        * @param uint timestamp @see drag_drop signal
        */
        private void on_drag_data_received (Gdk.DragContext context,
                                            int x,
                                            int y,
                                            Gtk.SelectionData selection_data,
                                            uint info,
                                            uint timestamp
                                            ) {
            //debug("on_drag_data_received");
            bool success = false;

            if (!drop_data_ready) {
                /* We don't have the drop data - extract uri list from selection data */
                string? text;
                if (DndHandler.selection_data_is_uri_list (selection_data, info, out text)) {
                    drop_file_list = Util.list_new_from_string (text);
                    drop_data_ready = true;
                }
            }

            if (drop_occurred && drop_data_ready) {
                drop_occurred = false;
                if (current_actions != Gdk.DragAction.DEFAULT) {
                    switch (info) {
                        case TargetType.XDND_DIRECT_SAVE0:
                            success = DndHandler.get_instance().handle_xdnddirectsave  (context,
                                                                          this.view,
                                                                           selection_data);
                            break;

                        case TargetType.NETSCAPE_URL:
                            success = DndHandler.get_instance().handle_netscape_url  (context,
                                                                        this.view,
                                                                        selection_data);
                            break;

                        case TargetType.TEXT_URI_LIST:
                            if ((current_actions & file_drag_actions) != 0) {
                                success = DndHandler.get_instance().handle_file_drag_actions  (this.view.get_widget(),
                                                                        this.view.get_application_window(),
                                                                        context,
                                                                        this.view,
                                                                        drop_file_list,
                                                                        current_actions,
                                                                        current_suggested_action,
                                                                        timestamp);
                            }
                            break;

                        default:
                            break;
                    }
                }
                Gtk.drag_finish (context, success, false, timestamp);
                on_drag_leave (context, timestamp);
            }
        }

        private void on_drag_leave (Gdk.DragContext context, uint timestamp) {
            //debug("on_drag_leave");
            drop_data_ready=false;
        }

        private bool on_drag_motion (Gdk.DragContext context,
                                 int x,
                                 int y,
                                 uint timestamp) {
            //debug("on_drag_motion");
            /* if we don't have drop data already ... */
            if (!drop_data_ready && !get_drop_data (context, x, y, timestamp))
                return false;
            else
            /* We have the drop data - check whether we can drop here*/
                check_destination_actions_and_target_file (context, x, y, timestamp);

            /*if (drag_scroll_timer_id == 0)
                start_drag_scroll_timer (context);
            */


            //depending on the modifier pressed, we will copy move or link
            Gdk.Keymap keymap=Gdk.Keymap.get_default();
            uint modifiers=keymap.get_modifier_state();
            if((modifiers & Gdk.ModifierType.CONTROL_MASK) > 0){
                //lets copy
                current_suggested_action=Gdk.DragAction.COPY;
            }else if((modifiers & Gdk.ModifierType.SHIFT_MASK) > 0 ||
                     (modifiers & Gdk.ModifierType.MOD1_MASK) > 0){
                //lets link
                current_suggested_action=Gdk.DragAction.LINK;
            }else{
                //lets move
                current_suggested_action=Gdk.DragAction.MOVE;
            }

            Gdk.drag_status (context, current_suggested_action, timestamp);

            return true;
        }

        private GLib.File get_drop_target_file (int win_x, int win_y) {
            GLib.File file = null;

            file = this.view.get_file_at(win_x,win_y);
            FileType type=file.query_file_type (FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            bool is_dir=type==FileType.DIRECTORY;

            /* can only drop onto folders and executables */
            if (!is_dir) {//TODO && !file.is_executable ()) {
                file = null;
            }
            return file;
        }

        protected void cancel_timeout (ref uint id) {
            if (id > 0) {
                GLib.Source.remove (id);
                id = 0;
            }
        }


        private bool is_valid_drop_folder (File file) {
            /* Cannot drop onto a file onto its parent or onto itself */
            if (//file.get_uri() != slot.uri &&
                drag_file_list != null &&
                drag_file_list.index (file) < 0)

                return true;
            else
                return false;
        }

        private void check_destination_actions_and_target_file (Gdk.DragContext context, int x, int y, uint timestamp) {
            File file = get_drop_target_file (x, y);
            string uri = file != null ? file.get_uri() : "";
            string current_uri = drop_target_file != null ? drop_target_file.get_uri() : "";

            Gdk.drag_status (context, Gdk.DragAction.MOVE, timestamp);
            if (uri != current_uri) {
                cancel_timeout (ref drag_enter_timer_id);
                drop_target_file = file;
                current_actions = Gdk.DragAction.DEFAULT;
                current_suggested_action = Gdk.DragAction.DEFAULT;

                if (file != null) {
                    if (current_target_type == Gdk.Atom.intern_static_string ("XdndDirectSave0")) {
                        current_suggested_action = Gdk.DragAction.COPY;
                        current_actions = current_suggested_action;
                    } else
                        current_actions = Util.file_accepts_drop(file, drop_file_list, context, out current_suggested_action);

                    //highlight_drop_file (drop_target_file, current_actions, path);

                    if (Util.is_folder (file) && is_valid_drop_folder (file)) {
                        /* open the target folder after a short delay */
                        drag_enter_timer_id = GLib.Timeout.add_full (GLib.Priority.LOW,
                                                                     drag_enter_delay,
                                                                     () => {
                            //load_location (file.get_target_location ());
                            drag_enter_timer_id = 0;
                            return false;
                        });
                    }
                }
            }
        }

        private bool get_drop_data (Gdk.DragContext context, int x, int y, uint timestamp) {
            Gtk.TargetList? list = null;
            Gdk.Atom target = Gtk.drag_dest_find_target (this.view.get_widget(), context, list);
            bool result = false;
            current_target_type = target;
            /* Check if we can handle it yet */
            if (target == Gdk.Atom.intern_static_string ("XdndDirectSave0") ||
                target == Gdk.Atom.intern_static_string ("_NETSCAPE_URL")) {

                /* Determine file at current position (if any) */
                DndView file = this.view;

                if (file != null &&
                    file.is_folder () &&
                    file.is_writable ()) {
                    //icon_renderer.@set ("drop-file", file);
                    //highlight_path (path);
                    drop_data_ready = true;
                    result = true;
                }
            } else if (target != Gdk.Atom.NONE)
                /* request the drag data from the source */
                Gtk.drag_get_data (this.view.get_widget(), context, target, timestamp); /* emits "drag_data_received" */

            return result;
        }
    }
}
