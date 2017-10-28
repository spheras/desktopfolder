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
        var directory = File.new_for_path (application.get_app_folder () + "/" + DesktopFolder.DesktopWindow.DESKTOP_FAKE_FOLDER_NAME);
        if (!directory.query_exists ()) {
            DirUtils.create (directory.get_path (), 0755);
        }

        base (application, DesktopFolder.DesktopWindow.DESKTOP_FAKE_FOLDER_NAME);

        // we cannot be moved
        this.is_moveable = false;
        this.get_view ().set_type_hint (Gdk.WindowTypeHint.DOCK);

        Gdk.Screen screen = Gdk.Screen.get_default ();
        this.get_view ().move (-12, -10);
        this.get_view ().resize (screen.get_width () + 25, screen.get_height () + 25);

        this.get_view ().set_titlebar (new Gtk.Label (""));
        this.get_view ().change_body_color (0);
    }

}
