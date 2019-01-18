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
 * Free Arragement for Panels. User can put icons wherever
 */
public class DesktopFolder.FolderArrangementFree : Object, FolderArrangement {
    public const int SENSITIVITY_WITHOUT_GRID = 1;

    public bool have_margin () {
        return false;
    }

    public bool can_drag () {
        return true;
    }

    public int get_sensitivity () {
        return SENSITIVITY_WITHOUT_GRID;
    }

    public bool can_organize () {
        return true;
    }

    public bool force_organization () {
        return false;
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
