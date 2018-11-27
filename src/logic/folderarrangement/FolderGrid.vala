public class DesktopFolder.FolderGrid <T> {
    public List <FolderGridRow <T> > rows;
    public int total_cols = 0;

    /**
     * Constructor
     * @param int total_cols the total cols for the grid (grid can grow rows but not columns)
     */
    public FolderGrid (int total_cols) {
        this.rows       = new List <FolderGridRow>();
        this.total_cols = total_cols;
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
     * @return {Gdk.Point} the x,y point to draw the item
     */
    public Gdk.Point get_next_gap (FolderWindow parent_window, T item) {
        // getting the header panel
        int margin = FolderArrangement.DEFAULT_EXTERNAL_MARGIN;

        for (int irow = 0; irow < this.rows.length (); irow++) {
            FolderGridRow row = this.rows.nth_data (irow);
            for (int icol = 0; icol < row.cols.length; icol++) {
                if (row.cols[icol] == null) {
                    row.cols[icol] = item;
                    Gdk.Point point = Gdk.Point ();
                    point.y        = irow * DesktopFolder.ICON_DEFAULT_WIDTH;
                    point.x        = margin + (icol * DesktopFolder.ICON_DEFAULT_WIDTH);
                    return point;
                }
            }
        }

        // no gap found, lets create a new row
        int last_row = (int) this.rows.length ();
        this.util_create_row (last_row);
        this.rows.nth_data (last_row).cols[0] = item;
        Gdk.Point point = Gdk.Point ();
        point.y = last_row * DesktopFolder.ICON_DEFAULT_WIDTH;
        point.x = 0;
        return point;
    }

    /**
     * @name build_grid_structure
     * @description build an array describing the grid structure inside the panel.
     * This map is useful to try to structure and align all the items inside the panel
     * @param FolderWindow parent_window the parent panel in which the items are placed
     * @return List with the ItemSettings inside, null are empty places
     */
    public static FolderGrid build_grid_structure (FolderWindow parent_window) {
        FolderSettings settings = parent_window.get_manager ().get_settings ();
        int width               = settings.w;

        // getting all the items defined
        List <ItemSettings> items = new List <ItemSettings> ();
        for (int i = 0; i < settings.items.length; i++) {
            ItemSettings is = ItemSettings.parse (settings.items[i]);
            items.append (is);
        }

        // getting the header panel
        int margin     = FolderArrangement.DEFAULT_EXTERNAL_MARGIN;
        width = width - margin - margin; // removing margin
        int total_cols = width / DesktopFolder.ICON_DEFAULT_WIDTH;

        // we create a cell structure of allowed items, it is a list of rows,
        // inside each row is an array with all the columns
        FolderGrid <ItemSettings> grid = new FolderGrid <ItemSettings> (total_cols);

        // now, ordering current items in the structure to see gaps
        for (int i = 0; i < items.length (); i++) {
            ItemSettings item = items.nth_data (i);
            int          x    = item.x;
            int          y    = item.y;

            int row           = (int) (y / DesktopFolder.ICON_DEFAULT_WIDTH);
            int col           = (int) (x / DesktopFolder.ICON_DEFAULT_WIDTH);

            if (row < 0) {
                row = 0;
            }
            if (col < 0) {
                col = 0;
            }
            // filling the gap with the item
            grid.put (row, col, item);
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
