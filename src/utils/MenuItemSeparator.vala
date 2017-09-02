private class DesktopFolder.MenuItemSeparator : Gtk.MenuItem {
    public MenuItemSeparator () {
        draw.connect (on_draw);
    }

    protected bool on_draw (Cairo.Context cr) {
        int padding=10;
        Gtk.Allocation allocation;
        this.get_allocation(out allocation);
        int middle=allocation.height/2;
        cr.new_path ();
        cr.set_line_width (1.0);
        cr.move_to (padding,middle);
        cr.rel_line_to (allocation.width-padding*2, 0);
        cr.set_source_rgba (0,0,0,0.2);
        cr.stroke();

        cr.close_path ();

        return true;
    }


}
