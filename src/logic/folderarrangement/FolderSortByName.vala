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
 * Sort By File Name
 */
public class DesktopFolder.FolderSortByName : Object, FolderSort {

    public void sort (ref List <ItemManager> items, bool asc) {
        items.sort_with_data ((a, b) => {
            if (a.is_folder () != b.is_folder ()) {
                if (a.is_folder ()) {
                    return -1;
                } else {
                    return 1;
                }
            } else {
                string afn = a.get_file_name ();
                string bfn = b.get_file_name ();
                return (asc) ? afn.ascii_casecmp (bfn) : bfn.ascii_casecmp (afn);
            }
        });
    }

}
