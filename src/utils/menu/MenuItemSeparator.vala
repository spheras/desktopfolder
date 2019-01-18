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

private class DesktopFolder.MenuItemSeparator : Gtk.MenuItem {
    public MenuItemSeparator () {
        draw.connect (on_draw);
    }

    protected bool on_draw (Cairo.Context cr) {
        int padding = 10;
        Gtk.Allocation allocation;
        this.get_allocation (out allocation);
        int middle = allocation.height / 2;
        cr.new_path ();
        cr.set_line_width (1);
        // +0.5 to avoid fuzzy lines?
        // http://stevehanov.ca/blog/index.php?id=28
        cr.move_to (padding + 0.5, middle + 0.5);
        cr.rel_line_to (allocation.width - padding * 2, 0);
        cr.set_source_rgba (0, 0, 0, 0.2);
        cr.stroke ();

        cr.close_path ();

        return true;
    }

}
