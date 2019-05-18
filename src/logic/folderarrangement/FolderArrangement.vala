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
    public static int DEFAULT_PADDING          = 10;
    public static int DEFAULT_EXTERNAL_MARGIN  = 10;
    public static int ARRANGEMENT_TYPE_FREE    = 1;
    public static int ARRANGEMENT_TYPE_GRID    = 2;
    public static int ARRANGEMENT_TYPE_MANAGED = 3;

    /**
     * @name have_margin
     * @description indicates whether the arrangment have internal margins at the panel
     * to put items inside the panel
     * @return bool true->yes we have margins, false otherwise
     */
    public abstract bool have_margin ();

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
     * @name can_organize
     * @description return whether the arrangement allow the reorganization of items, asked manually
     * @return bool true->yes, it is allowed, false otherwise
     */
    public abstract bool can_organize ();

    /**
     * @name force_organization
     * @description indicates whether the arrangement must force the organization when the panel is resized
     * @return bool true->yes, force, othwerise false
     */
    public abstract bool force_organization ();

    /**
     * @name start_drag
     * @description a itemview has started being dragged into the arrangement
     * @param {ItemView} view the view that is being dragged
     */
    public abstract void start_drag (ItemView view);

    /**
     * @name motion_drag
     * @description a itemview is being moved (the started was notified previously)
     * @param {int} x the x new position
     * @param {int} y the y new position
     */
    public abstract void motion_drag (int x, int y);

    /**
     * @name end_drag
     * @description the item drag was finished
     */
    public abstract void end_drag ();



    /**
     * Factory method to obtain an arragement type
     * @see ARRAGEMENT_TYPE_FREE, ARRAGEMENT_TYPE_GRID, ARRAGEMENT_TYPE_MANAGED constants
     * @param int type the factory type
     * @return FolderArrangement the concrete folder arragement for that type, null if none valid
     */
    public static FolderArrangement ? factory (int type) {
        if (type == FolderArrangement.ARRANGEMENT_TYPE_FREE) {
            return new FolderArrangementFree ();
        } else if (type == FolderArrangement.ARRANGEMENT_TYPE_GRID) {
            return new FolderArrangementGrid ();
        } else if (type == FolderArrangement.ARRANGEMENT_TYPE_MANAGED) {
            return new FolderArrangementManaged ();
        }
        return null;
    }

    /**
     * @name organize_items
     * @desription organize the list of items in a panel sorted
     * @param parent_window FolderWindow the parent panel of the items
     * @param items List<ItemManager> the reference for the list of items to organize. Items are positioned to foce the new organization
     * @param sort_by_type int the sort type @see FolderSort constants
     * @param asc bool to indicate ascendent sort or descent (true->ascendent)
     */
    public static void organize_items (FolderWindow parent_window, ref List <ItemManager> items, int sort_by_type, bool asc, bool vertically) {
        Organize.Thread fot = new Organize.Thread (parent_window, ref items, sort_by_type, asc, vertically);
        fot.start ();
    }

}

/**
 * Class to represent a desired movement of an item to a different positions after a reorganization
 */
private class DesktopFolder.Organize.ItemMove {
    /** the view to move */
    public ItemView view { get; set; }
    /** the new point x,y to put the item view*/
    public Gdk.Point point { get; set; }

    public ItemMove (ItemView view, Gdk.Point point) {
        this.view  = view;
        this.point = point;
    }
}

/**
 * Thread to organize items following a grid
 */
private class DesktopFolder.Organize.Thread {
    private FolderWindow parent_window;
    private List <ItemManager> items;
    private int sort_by_type;
    private bool asc;
    private bool vertically;

    public Thread (FolderWindow parent_window, ref List <ItemManager> items, int sort_by_type, bool asc, bool vertically) {
        this.parent_window = parent_window;

        // HELP! how to copy a ref variable in vala!?
        this.items = new List <ItemManager>();
        items.foreach ((i) => {
            this.items.append (i);
        }) ;
        // ******************************************

        this.asc          = asc;
        this.sort_by_type = sort_by_type;
        this.vertically   = vertically;
    }

    /**
     * @name start
     * @description start the thread
     */
    public void start () {
        parent_window.show_loading ();
        try {
            new GLib.Thread <bool> .try ("sync_thread", this.organize);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog ("Error", e.message);
        }
    }

    /**
     * @name organize
     * @description organize algorithm
     */
    private bool organize () {
        debug ("ORGANIZE THREAD -> INIT");
        FolderSort folder_sort = FolderSort.factory (sort_by_type);
        folder_sort.sort (ref items, asc);

        // window width
        int width       = parent_window.get_manager ().get_settings ().w;
        int height      = parent_window.get_manager ().get_settings ().h;
        // left margin to start the grid
        int left_margin = FolderArrangement.DEFAULT_EXTERNAL_MARGIN;

        // cursors pixel
        int cursor_x = left_margin;
        int cursor_y = 0;
        int padding  = parent_window.get_manager ().get_settings ().arrangement_padding;
        Gee.HashMap <string, ItemSettings> managed_items = parent_window.get_manager ().get_settings ().get_items_parsed ();
        Gee.List <Organize.ItemMove>       item_moves    = new Gee.ArrayList <Organize.ItemMove>();

        for (int i = 0; i < items.length (); i++) {
            ItemManager item = items.nth_data (i);

            // moving in the view to the correct position
            // parent_window.move_item (item.get_view (), cursor_x, cursor_y);
            Gdk.Point px = Gdk.Point ();
            px.x = cursor_x;
            px.y = cursor_y;

            // add the movement to the pending movements to be executed in the gtk thread
            item_moves.add (new Organize.ItemMove (item.get_view (), px));

            // saving settings for the new position
            ItemSettings is = managed_items[item.get_file_name ()];

            is.x            = cursor_x;
            is.y            = cursor_y;

            // moving the cursor horizontally
            if (vertically) {
                cursor_y = cursor_y + DesktopFolder.ICON_DEFAULT_WIDTH + padding;
                if (cursor_y + DesktopFolder.ICON_DEFAULT_WIDTH > height) {
                    // we need to move to the next rows
                    cursor_x = cursor_x + DesktopFolder.ICON_DEFAULT_WIDTH + padding;
                    cursor_y = 0;
                }
            } else {
                cursor_x = cursor_x + DesktopFolder.ICON_DEFAULT_WIDTH + padding;
                if (cursor_x + DesktopFolder.ICON_DEFAULT_WIDTH + left_margin > width) {
                    // we need to move to the next rows
                    cursor_x = left_margin;
                    cursor_y = cursor_y + DesktopFolder.ICON_DEFAULT_WIDTH + padding;
                }
            }
        }


        // only last to put the items in their positions, this is something can only be done in the gtk main thread
        GLib.Idle.add_full (GLib.Priority.LOW, () => {
            const int MAX = 5;
            int cursor = 0;

            while (cursor < MAX && item_moves.size > 0) {
                Organize.ItemMove move = item_moves.remove_at (0);
                UtilGtkAnimation.animate_move (move.view, move.point, 500, UtilFx.AnimationMode.EASE_IN_BACK);
                cursor++;
            }

            if (item_moves.size > 0) {
                // next iteration in the main gtk thread
                return true;
            } else {
                parent_window.get_manager ().get_settings ().serialize_array (managed_items.values.to_array ());
                parent_window.get_manager ().get_settings ().save ();

                this.parent_window.hide_loading ();
                debug ("ORGANIZE THREAD -> END");
                return false;
            }
        });

        return true;
    }

}


private class GridRow {

}
