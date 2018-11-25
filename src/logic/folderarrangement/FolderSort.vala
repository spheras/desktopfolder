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
public interface DesktopFolder.FolderSort : Object {
    public static int SORT_BY_NAME = 0;
    public static int SORT_BY_SIZE = 1;
    public static int SORT_BY_TYPE = 2;

    /**
     * @name sort
     * @description sort the list of items by the criteria of the concrete sort
     * @param List<ItemManager> items the reference to the list of items
     * @param bool asc if the order is ascendent or not
     */
    public abstract void sort (ref List <ItemManager> items, bool asc);

    /**
     * Factory method to obtain an sort type
     * @see SORT_BY_NAME, SORT_BY_SIZE, SORT_BY_TYPE constants
     * @param int type the factory type
     * @return FolderSort the concrete folder sort for that type, null if none valid
     */
    public static FolderSort ? factory (int type) {
        if (type == FolderSort.SORT_BY_NAME) {
            return new FolderSortByName ();
        } else if (type == FolderSort.SORT_BY_SIZE) {
            return new FolderSortBySize ();
        } else if (type == FolderSort.SORT_BY_TYPE) {
            return new FolderSortByType ();
        }
        return null;
    }

}
