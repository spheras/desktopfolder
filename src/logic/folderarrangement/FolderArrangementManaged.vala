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
 * Managed Arragement for Panels - User can't move icons.. all of them
 * are managed by the sytem
 */
public class DesktopFolder.FolderArrangementManaged : Object, FolderArrangement {

    public bool have_margin () {
        return true;
    }

    public bool can_drag () {
        return false;
    }

    public int get_sensitivity () {
        return -1;
    }

    public bool can_organize () {
        return false;
    }

    public bool force_organization () {
        return true;
    }

    public void start_drag (ItemView view) {
        // nothing
    }

    public void motion_drag (int x, int y) {
        // nothing
    }

    public void end_drag () {
        // nothing
    }

}
