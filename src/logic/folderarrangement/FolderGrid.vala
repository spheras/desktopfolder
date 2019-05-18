public class DesktopFolder.FolderGrid <T> {
    public List <FolderGridRow <T> > rows;
    public int total_cols = 0;
    public int total_rows = 0;

    /**
     * Constructor
     * @param int total_cols the total cols for the grid (grid can grow rows but not columns)
     */
    public FolderGrid (int total_cols, int total_rows) {
        this.rows       = new List <FolderGridRow>();
        this.total_cols = total_cols;
        this.total_rows = total_rows;
        this.util_create_row (total_rows - 1);
    }

    public void print () {
        debug ("printing grid:");
        for (int irow = 0; irow < this.rows.length (); irow++) {
            FolderGridRow row  = this.rows.nth_data (irow);
            string        srow = "";
            for (int icol = 0; icol < row.cols.length; icol++) {
                T col = row.cols[icol];
                srow = srow + (col == null ? "0" : "X");
            }
            debug (srow);
        }
    }

    /**
     * @name replace
     * @descriptin replace in the grid the item1 with the item2
     * @param {T} item1 the item1 to replace
     * @param {Gdk.Point} pos1 the position of the item1 in the grid
     * @param {T} item2 the item2 to replace
     * @param {Gdk.Point} pos2 the position of the item2 in the grid
     */
    public void replace (T item1, Gdk.Point pos1, T item2, Gdk.Point pos2) {
        // debug ("replace - start");
        this.rows.nth_data (pos1.y).cols[pos1.x] = item2;
        this.rows.nth_data (pos2.y).cols[pos2.x] = item1;
        // debug ("replace - end");
    }

    /**
     * @name CompareAllocations
     * @description Comparator of GtkAllocation objects to order the selection with the keyboard
     * @return {bool} if the a element is greater than the b element
     */
    public delegate bool IsSame <T> (T a, T b);

    /**
     * @name get_item_cell_position
     * @description return the position for a certain item inside the grid
     * @param {T} item the item to search
     * @param {IsSame} comparator the items comparator implementation
     * @return {Point} the point (row,col) which is occupied by the item (null if none there)
     */
    public Gdk.Point ? get_item_cell_position (T item, IsSame <T> comparator) {
        for (int irow = 0; irow < this.rows.length (); irow++) {
            FolderGridRow row = this.rows.nth_data (irow);
            for (int icol = 0; icol < row.cols.length; icol++) {
                T col = row.cols[icol];
                if (col != null && comparator (col, item)) {
                    var point = Gdk.Point ();
                    point.x = icol;
                    point.y = irow;
                    return point;
                }
            }
        }
        return null;
    }

    /**
     * @name get_item_at_cell
     * @description return the item at the cell specified
     * @param {Gdk.Point} the cell x,y position
     * @return {T} the item at that cell or null if none
     */
    public T ? get_item_at_cell (Gdk.Point pos) {
        // debug ("get_item_at_cell: %d, %d", pos.x, pos.y);
        if (this.rows.length () > pos.y) {
            if (this.rows.nth_data (pos.y).cols.length > pos.x) {
                // debug ("this.rows.length(%d) - cols(%d)", (int) this.rows.length (), this.rows.nth_data (pos.y).cols.length);
                return this.rows.nth_data (pos.y).cols[pos.x];
            }
        }

        return null;
    }

    /**
     * @name get_cell
     * @description return the cell for the pixel x,y
     * @param {int} sensitivity the sensitivity used at the arrangement
     * @param {int} padding the padding used at the arrangmeent
     * @param {int} x the x pixel
     * @param {int} y the y pixel
     * @return {Gdk.Point} the cell(x,y)
     */
    public Gdk.Point get_cell (int sensitivity, int padding, int x, int y) {
        int cell_x = (x + DesktopFolder.ICON_DEFAULT_WIDTH / 2) / (sensitivity + padding);
        int cell_y = (y + DesktopFolder.ICON_DEFAULT_WIDTH / 2) / (sensitivity + padding);
        var point  = Gdk.Point ();
        point.x = cell_x;
        point.y = cell_y;

        if (point.x < 0) {
            point.x = 0;
        }
        if (point.y < 0) {
            point.y = 0;
        }
        return point;
    }

    /**
     * @name put
     * @description put a new data into the grid at a concrete position
     * @param int row the row position of the grid
     * @param int col the column position of the grid
     * @param T data the data to put
     */
    public void put (int row, int col, T data) {
        util_create_row (row);
        this.rows.nth_data (row).cols[col] = data;
    }

    /**
     * @name util_create_row
     * @description create a new row for the list of cells (we can grow vertically)
     *
     */
    private void util_create_row (int row) {
        if (rows.length () <= row) {
            // we must create enough rows
            for (int i = ((int) this.rows.length ()) - 1; i < row; i++) {
                FolderGridRow <T> new_row = new FolderGridRow <T> (total_cols);
                this.rows.append (new_row);
            }
        }
    }

    /**
     * @name get_next_gap
     * @description find a gap inside the current structure and put there the item
     * @param FolderWindow parent_window the parent panel in which the items are placed
     * @param T item the item to put at the gap position
     * @param int padding the padding between cells
     * @param {bool} vertically if the sort orientation is vertically or not
     * @return {Gdk.Point} the x,y point to draw the item
     */
    public Gdk.Point get_next_gap (FolderWindow parent_window, T item, int padding, bool vertically) {
        // getting the header panel
        int margin = FolderArrangement.DEFAULT_EXTERNAL_MARGIN;

        if (vertically) {
            if (this.rows.length () > 0) {
                FolderGridRow first_row = this.rows.nth_data (0);
                for (int icol = 0; icol < first_row.cols.length; icol++) {
                    for (int irow = 0; irow < this.rows.length (); irow++) {
                        FolderGridRow row = this.rows.nth_data (irow);
                        if (row.cols[icol] == null) {
                            row.cols[icol] = item;
                            Gdk.Point point = Gdk.Point ();
                            point.y        = (irow * DesktopFolder.ICON_DEFAULT_WIDTH) + (irow * padding);
                            point.x        = margin + (icol * DesktopFolder.ICON_DEFAULT_WIDTH) + (icol * padding);
                            return point;
                        }
                    }
                }
            }
        } else {
            for (int irow = 0; irow < this.rows.length (); irow++) {
                FolderGridRow row = this.rows.nth_data (irow);
                for (int icol = 0; icol < row.cols.length; icol++) {
                    if (row.cols[icol] == null) {
                        row.cols[icol] = item;
                        Gdk.Point point = Gdk.Point ();
                        point.y        = (irow * DesktopFolder.ICON_DEFAULT_WIDTH) + (irow * padding);
                        point.x        = margin + (icol * DesktopFolder.ICON_DEFAULT_WIDTH) + (icol * padding);
                        return point;
                    }
                }
            }
        }


        // no gap found, lets create a new row
        int last_row = (int) this.rows.length ();
        this.util_create_row (last_row);
        this.rows.nth_data (last_row).cols[0] = item;
        Gdk.Point point = Gdk.Point ();
        point.y = (last_row * DesktopFolder.ICON_DEFAULT_WIDTH) + (last_row * padding);
        point.x = margin;
        return point;
    }

    /**
     * @name build_grid_structure
     * @description build an array describing the grid structure inside the panel.
     * This map is useful to try to structure and align all the items inside the panel
     * @param FolderWindow parent_window the parent panel in which the items are placed
     * @param {int} padding the internal padding for elements
     * @param {ItemSettings} lookin_for_item (optiona) the item we are trying to look in the structure (in case there are various items in the same cell, the looked one is prefered)
     * @return List with the ItemSettings inside, null are empty places
     */
    public static FolderGrid build_grid_structure (FolderWindow parent_window, int padding, ItemSettings ? looking_for_item = null) {
        FolderSettings settings = parent_window.get_manager ().get_settings ();
        int width               = settings.w;
        int height              = settings.h;

        // getting all the items defined
        List <ItemSettings> items = new List <ItemSettings> ();
        for (int i = 0; i < settings.items.length; i++) {
            ItemSettings is = ItemSettings.parse (settings.items[i]);
            items.append (is);
        }

        int margin = FolderArrangement.DEFAULT_EXTERNAL_MARGIN;

        Gtk.Allocation title_allocation;
        parent_window.get_titlebar ().get_allocation (out title_allocation);
        int header = title_allocation.height + margin;

        width  = width - margin - margin; // removing margin
        height = height - header;
        int total_cols = width / (DesktopFolder.ICON_DEFAULT_WIDTH + padding);
        int total_rows = height / (DesktopFolder.ICON_DEFAULT_WIDTH + padding);

        // we create a cell structure of allowed items, it is a list of rows,
        // inside each row is an array with all the columns
        FolderGrid <ItemSettings> grid = new FolderGrid <ItemSettings> (total_cols, total_rows);

        // now, ordering current items in the structure to see gaps
        for (int i = 0; i < items.length (); i++) {
            ItemSettings item = items.nth_data (i);
            int          x    = item.x;
            int          y    = item.y;

            int row           = (int) (y / (DesktopFolder.ICON_DEFAULT_WIDTH + padding));
            int col           = (int) (x / (DesktopFolder.ICON_DEFAULT_WIDTH + padding));

            if (col >= total_cols) {
                col = total_cols - 1;
            }

            if (row < 0) {
                row = 0;
            }
            if (col < 0) {
                col = 0;
            }
            // filling the gap with the item
            if (looking_for_item == null) {
                grid.put (row, col, item);
            } else {
                // checking if in the same position is already an item
                if (grid.rows.length () > row && grid.rows.nth_data (row).cols.length > col) {
                    ItemSettings current = grid.rows.nth_data (row).cols[col];
                    if (current == null || current.name != looking_for_item.name) {
                        // replacing
                        grid.put (row, col, item);
                    } else {
                    }
                } else {
                    grid.put (row, col, item);
                }
            }
        }

        return grid;
    }

}

public class DesktopFolder.FolderGridRow <T> {
    public T[] cols;

    public FolderGridRow (int total_cols) {
        this.cols = new T[total_cols];
    }
}
