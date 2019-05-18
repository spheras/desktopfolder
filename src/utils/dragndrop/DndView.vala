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

namespace DesktopFolder.DragnDrop {

    public interface DndView : Object {
        /**
         * @name get_widget
         * @description return the widget associated with this view
         * @return Widget the widget
         */
        public abstract Gtk.Widget get_widget ();

        /**
         * @name get_application_window
         * @description return the application window of this view, needed for drag operations
         * @return ApplicationWindow
         */
        public abstract Gtk.ApplicationWindow get_application_window ();

        /**
         * @name get_file
         * @description return the file asociated with this view
         * @return File the file
         */
        public abstract GLib.File get_file ();

        /**
         * @name get_image
         * @description return the image to be shown when dragging
         * @return {Gtk.Image} the image to be rendered
         */
        public abstract Gtk.Image get_image ();

        /**
         * @name get_file_at
         * @name get the file at the position x, y
         * @return File
         */
        public abstract GLib.File get_file_at (int x, int y);

        /**
         * @name is_folder
         * @description check whether the view represents a folder or a file
         * @return bool true->this view represents a folder
         */
        public abstract bool is_folder ();

        /**
         * @name is_writable
         * @description indicates if the file linked by this view is writable or not
         * @return bool
         */
        public abstract bool is_writable ();

        /**
         * @name get_target_location
         * @description return the target File that represents this view
         * @return File the file target of this view
         */
        public abstract GLib.File get_target_location ();

        /**
         * @name is_recent_uri_scheme
         * @description check whether the File is a recent uri scheme?
         * @return bool
         */
        public abstract bool is_recent_uri_scheme ();

        /**
         * @name get_display_target_uri
         * @description return the target uri of this view
         * @return string the target uri
         */
        public abstract string get_display_target_uri ();

        /**
         * @name on_drag_end
         * @description drag finished event
         */
        public abstract void on_drag_end ();

        /**
         * @name on_drag_motion
         * @description the mouse is over the dnd view
         */
        public abstract void on_drag_motion ();

        /**
         * @name on_drag_leave
         * @description the mouse leave the view
         */
        public abstract void on_drag_leave ();

        /**
         * @name get_all_selected_views
         * @description return all the selected views at this moment
         * @return DndView[] the list of DndViews selected
         */
        public abstract DndView[] get_all_selected_views ();

    }
}
