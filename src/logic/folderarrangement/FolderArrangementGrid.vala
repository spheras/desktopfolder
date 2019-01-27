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
public class DesktopFolder.FolderArrangementGrid : Object, FolderArrangement {
    protected const int SENSITIVITY_WITH_GRID = DesktopFolder.ICON_DEFAULT_WIDTH;

    public bool have_margin () {
        return true;
    }

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

    public bool can_organize () {
        return true;
    }

    public bool force_organization () {
        return false;
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

    // util grid map during te item dragging
    private FolderGrid <ItemSettings> drag_grid;

    private ItemView drag_item;
    private Gdk.Point ? init_item_cell;
    private Gdk.Point ? init_item_px;

    private ItemSettings drag_conflict_item;
    private Gdk.Point ? drag_conflict_cell;
    private Gdk.Point ? drag_conflict_px;
    private int drag_padding;

    public Gdk.Point ? get_init_item_cell () {
        return this.init_item_cell;
    }

    public bool is_dragging () {
        return this.drag_item != null;
    }

    public void start_drag (ItemView view) {
        // debug ("start_drag - start");
        this.drag_item      = view;
        this.init_item_px   = Gdk.Point ();
        ItemSettings view_settings = view.get_manager ().get_settings ();
        init_item_px.x      = view_settings.x;
        init_item_px.y      = view_settings.y;
        this.drag_padding   = view.get_manager ().get_folder ().get_settings ().arrangement_padding;
        this.drag_grid      = FolderGrid.build_grid_structure (view.get_manager ().get_folder ().get_view (), this.drag_padding, view_settings);
        this.init_item_cell = this.drag_grid.get_item_cell_position (view_settings,
                (a, b) => {
            return a.name == b.name;
        });
        // debug ("start_drag - end");
    }

    public void motion_drag (int x, int y) {
        // we get the cell at pixel x,y
        Gdk.Point cell_at_xy = this.drag_grid.get_cell (SENSITIVITY_WITH_GRID, this.drag_padding, x, y);
        // debug ("motion_drag - cell(%d,%d)", cell_at_xy.x, cell_at_xy.y);

        // the drag item settings
        ItemSettings drag_item_settings = this.drag_item.get_manager ().get_settings ();

        // checking if we had an old conflict to restore the conflicting item
        if (this.drag_conflict_item != null &&
            (cell_at_xy.x != this.drag_conflict_cell.x ||
            cell_at_xy.y != this.drag_conflict_cell.y)) {
            // restoring conflict item to its original position
            this.drag_grid.replace (drag_item_settings, this.drag_conflict_cell, this.drag_conflict_item, this.init_item_cell);
            ItemManager item_conflict_manager = this.drag_item.get_manager ().get_folder ().get_item_by_filename (this.drag_conflict_item.name);

            if (!item_conflict_manager.is_selected ()) {
                UtilGtkAnimation.animate_move (item_conflict_manager.get_view (), this.drag_conflict_px, 1000);
            }


            this.drag_conflict_item.x = this.drag_conflict_px.x;
            this.drag_conflict_item.y = this.drag_conflict_px.y;

            this.drag_conflict_item   = null;
            this.drag_conflict_cell   = null;
            this.drag_conflict_px     = null;
        } else if (this.drag_conflict_item != null) {
            // debug ("conflict (%d,%d)", this.drag_conflict_cell.x, this.drag_conflict_cell.y);
        }

        // and now the item at that cell in the grid
        ItemSettings item_at_pos = this.drag_grid.get_item_at_cell (cell_at_xy);

        if (item_at_pos != null && item_at_pos.name != drag_item_settings.name) {
            // anotate the conflict
            this.drag_conflict_item = item_at_pos;
            this.drag_conflict_cell = cell_at_xy;
            ItemManager item_at_pos_manager = this.drag_item.get_manager ().get_folder ().get_item_by_filename (item_at_pos.name);

            // interchanging positions in the grid and physically
            this.drag_grid.replace (drag_item_settings, this.init_item_cell, item_at_pos, cell_at_xy);
            this.drag_conflict_px   = Gdk.Point ();
            this.drag_conflict_px.x = item_at_pos.x;
            this.drag_conflict_px.y = item_at_pos.y;
            item_at_pos.x           = init_item_px.x;
            item_at_pos.y           = init_item_px.y;

            if (!item_at_pos_manager.is_selected ()) {
                // this.drag_item.get_manager ().get_folder ().get_view ().move_item (item_at_pos_manager.get_view (), init_item_px.x, init_item_px.y);
                UtilGtkAnimation.animate_move (item_at_pos_manager.get_view (), init_item_px, 500, UtilFx.AnimationMode.EASE_IN_BACK);
            }

        }

        // if no, then restore the item in conflict to the original position
    }

    public void end_drag () {
        // debug ("end_drag - start");
        if (this.drag_conflict_item != null) {
            // debug ("end_drag - saving conflict");
            ItemManager drag_conflict_manager = this.drag_item.get_manager ().get_folder ().get_item_by_filename (this.drag_conflict_item.name);
            drag_conflict_manager.get_folder ().get_settings ().set_item (this.drag_conflict_item);
            drag_conflict_manager.get_folder ().get_settings ().save ();

        }

        this.drag_grid          = null;
        this.drag_item          = null;
        this.init_item_cell     = null;
        this.init_item_px       = null;
        this.drag_conflict_item = null;
        this.drag_conflict_cell = null;
        this.drag_conflict_px   = null;
        // debug("end_drag - end");
    }

}
