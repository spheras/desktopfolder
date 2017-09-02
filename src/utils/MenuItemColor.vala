private class DesktopFolder.MenuItemColor : Gtk.MenuItem {
    private new bool has_focus;
    private int height;
    public signal void color_changed (int ncolor);
    private string[] tags_colors;
    //public const string TAGS_COLORS[10] = { null, "#fce94f", "#fcaf3e", "#997666", "#8ae234", "#729fcf", "#ad7fa8", "#ef2929", "#d3d7cf", "#000000" };
    //public const string TAGS_COLORS_CLASS[10] = { "transparent", "yellow", "orange", "brown", "green", "blue", "purple", "red", "gray", "black" };

    public MenuItemColor (string[] tags_colors) {
        this.tags_colors=tags_colors;
        set_size_request (150, 20);
        height = 20;

        button_press_event.connect (button_pressed_cb);
        draw.connect (on_draw);

        select.connect (() => {
            has_focus = true;
        });

        deselect.connect (() => {
            has_focus = false;
        });
    }

    private bool button_pressed_cb (Gdk.EventButton event) {
        determine_button_pressed_event (event);
        return true;
    }

    private void determine_button_pressed_event (Gdk.EventButton event) {
        int i;
        int btnw = 10;
        int btnh = 10;
        int y0 = (height - btnh) /2;
        int x0 = btnw+5;
        int xpad = 9;

        if (event.y >= y0 && event.y <= y0+btnh) {
            for (i=1; i<=this.tags_colors.length; i++) {
                if (event.x>= xpad+x0*i && event.x <= xpad+x0*i+btnw) {
                    color_changed (i-1);
                    break;
                }
            }
        }
    }

    protected bool on_draw (Cairo.Context cr) {
        int i;
        int btnw = 10;
        int btnh = 10;
        int y0 = (height - btnh) /2;
        int x0 = btnw+5;
        int xpad = 9;

        for (i=1; i<=this.tags_colors.length; i++) {
            if (i==1)
                DrawCross (cr,xpad + x0*i, y0+1, btnw-2, btnh-2);
            else {
                DrawRoundedRectangle (cr,xpad + x0*i, y0, btnw, btnh, "stroke", i-1);
                DrawRoundedRectangle (cr,xpad + x0*i, y0, btnw, btnh, "fill", i-1);
                DrawGradientOverlay (cr,xpad + x0*i, y0, btnw, btnh);
            }
        }

        return true;
    }

    private void DrawCross (Cairo.Context cr, int x, int y, int w, int h) {
        cr.new_path ();
        cr.set_line_width (2.0);
        cr.move_to (x, y);
        cr.rel_line_to (w, h);
        cr.move_to (x, y+h);
        cr.rel_line_to (w, -h);
        cr.set_source_rgba (0,0,0,0.6);
        cr.stroke();

        cr.close_path ();
    }

    /*
     * Create a rounded rectangle using the Bezier curve.
     * Adapted from http://cairographics.org/cookbook/roundedrectangles/
     */
    private void DrawRoundedRectangle (Cairo.Context cr, int x, int y, int w, int h, string style, int color) {
        int radius_x=2;
        int radius_y=2;
        double ARC_TO_BEZIER = 0.55228475;

        if (radius_x > w - radius_x)
            radius_x = w / 2;

        if (radius_y > h - radius_y)
            radius_y = h / 2;

        /* approximate (quite close) the arc using a bezier curve */
        double ca = ARC_TO_BEZIER * radius_x;
        double cb = ARC_TO_BEZIER * radius_y;

        cr.new_path ();
        cr.set_line_width (0.7);
        cr.set_tolerance (0.1);
        cr.move_to (x + radius_x, y);
        cr.rel_line_to (w - 2 * radius_x, 0.0);
        cr.rel_curve_to (ca, 0.0, radius_x, cb, radius_x, radius_y);
        cr.rel_line_to (0, h - 2 * radius_y);
        cr.rel_curve_to (0.0, cb, ca - radius_x, radius_y, -radius_x, radius_y);
        cr.rel_line_to (-w + 2 * radius_x, 0);
        cr.rel_curve_to (-ca, 0, -radius_x, -cb, -radius_x, -radius_y);
        cr.rel_line_to (0, -h + 2 * radius_y);
        cr.rel_curve_to (0.0, -cb, radius_x - ca, -radius_y, radius_x, -radius_y);

        switch (style) {
        default:
        case "fill":
            Gdk.RGBA rgba = Gdk.RGBA ();
            rgba.parse (this.tags_colors[color]);
            Gdk.cairo_set_source_rgba (cr, rgba);
            cr.fill ();
            break;
        case "stroke":
            cr.set_source_rgba (0,0,0,0.5);
            cr.stroke ();
            break;
        }

        cr.close_path ();
    }

    /*
     * Draw the overlaying gradient
     */
    private void DrawGradientOverlay (Cairo.Context cr, int x, int y, int w, int h) {
        var radial = new Cairo.Pattern.radial (w, h, 1, 0.0, 0.0, 0.0);
        radial.add_color_stop_rgba (0, 0.3, 0.3, 0.3,0.0);
        radial.add_color_stop_rgba (1, 0.0, 0.0, 0.0,0.5);

        cr.set_source (radial);
        cr.rectangle (x,y,w,h);
        cr.fill ();
    }
}
