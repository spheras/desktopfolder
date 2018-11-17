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
 * Grid Arragement - User can move icons wherever following a grid
 */
public class DesktopFolder.GridArrangement : Object, FolderArrangement {
    protected const int SENSITIVITY_WITH_GRID = 100;

    public bool can_drag () {
        return true;
    }

    /**
     * @name get_sensitivity
     * @description Get the value of sensitivity, used to calculate the alignment of the items
     */
    public int get_sensitivity () {
        return SENSITIVITY_WITH_GRID;
    }

    /**
     * @name on_toggle_align_to_grid
     * @description the toggle align to grid event. The align to grid property must change
     */
    public void on_toggle_align_to_grid () {
        /*
           if (this.get_sensitivity () == SENSITIVITY_WITH_GRID) {
              this.set_sensitivity (SENSITIVITY_WITHOUT_GRID);
              this.manager.get_settings ().align_to_grid = false;
           } else {
              this.set_sensitivity (SENSITIVITY_WITH_GRID);
              this.manager.get_settings ().align_to_grid = true;
           }
           this.manager.get_settings ().save ();
           this.clear_all ();
           this.manager.sync_files (0, 0);
         */
    }

}
