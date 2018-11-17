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
 * Folder Arragement Interface
 */
public interface DesktopFolder.FolderArrangement : Object {
    public static int ARRANGEMENT_TYPE_FREE    = 1;
    public static int ARRANGEMENT_TYPE_GRID    = 2;
    public static int ARRANGEMENT_TYPE_MANAGED = 3;

    /**
     * @name can_drag
     * @description return whether the items dan be dragged or not
     * @return bool true->yes they can be dragged, false otherwise
     */
    public abstract bool can_drag ();

    /**
     * @name get_sensitivity
     * @description Get the value of sensitivity, used to calculate the alignment of the items
     */
    public abstract int get_sensitivity ();

    /**
     * @name get_margin
     * @description return the margin used to position folders inside the panel
     */
    public abstract int get_margin ();

    /**
     * Factory method to obtain an arragement type
     * @see ARRAGEMENT_TYPE_FREE, ARRAGEMENT_TYPE_GRID, ARRAGEMENT_TYPE_MANAGED constants
     * @param int type the factory type
     * @return FolderArrangement the concrete folder arragement for that type, null if none valid
     */
    public static FolderArrangement ? factory (int type) {
        if (type == FolderArrangement.ARRANGEMENT_TYPE_FREE) {
            return new FreeArrangement ();
        } else if (type == FolderArrangement.ARRANGEMENT_TYPE_GRID) {
            return new GridArrangement ();
        } else if (type == FolderArrangement.ARRANGEMENT_TYPE_MANAGED) {
            return new ManagedArrangement ();
        }
        return null;
    }

}
