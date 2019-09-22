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

private class DesktopFolder.MenuItemColor : Gtk.MenuItem {
    private new bool has_focus;
    private int height;
    public signal void color_changed (int ncolor);
    public signal void custom_changed (string custom);

    private string[] tags_colors;
    private string custom;
    private const int XPAD = 17;

    public MenuItemColor (string[] tags_colors, string ? custom) {
        this.tags_colors   = tags_colors;
        this.custom        = custom;
        set_size_request (160, 20);
        height             = 20;

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
        int y0   = (height - btnh) / 2;
        int x0   = btnw + 5;
        int xpad = XPAD;

        if (event.y >= y0 && event.y <= y0 + btnh) {
            for (i = 1; i <= this.tags_colors.length + 1; i++) {
                if (event.x >= xpad + x0 * i && event.x <= xpad + x0 * i + btnw) {
                    if (i > this.tags_colors.length) {
                        Gtk.ColorSelectionDialog dialog = new Gtk.ColorSelectionDialog (DesktopFolder.Lang.MENU_COLOR_DIALOG_TITLE);
                        dialog.set_transient_for ((Gtk.Window)this.get_toplevel());
                        dialog.get_color_selection ().set_has_opacity_control (true);
                        Gdk.RGBA _rgba = Gdk.RGBA ();
                        _rgba.parse (this.custom);
                        dialog.get_color_selection ().set_current_rgba (_rgba);
                        dialog.get_color_selection ().set_previous_rgba (_rgba);
                        if (dialog.run () == Gtk.ResponseType.OK) {
                            unowned Gtk.ColorSelection widget = dialog.get_color_selection ();
                            string rgba = widget.current_rgba.to_string ();
                            custom_changed (rgba);
                            // uint alpha = widget.current_alpha;
                            // stdout.puts ("Selection\n");
                            // stdout.printf ("  %s\n", rgba);
                            // stdout.printf ("  %u\n", alpha);
                        }
                        dialog.close ();
                    } else {
                        color_changed (i - 1);
                    }
                    break;
                }
            }
        }
    }

    protected bool on_draw (Cairo.Context cr) {
        int i;
        int btnw = 10;
        int btnh = 10;
        int y0   = (height - btnh) / 2;
        int x0   = btnw + 5;
        int xpad = XPAD;

        for (i = 1; i <= this.tags_colors.length + 1; i++) {
            if (i == 1) {
                DrawCross (cr, xpad + x0 * i, y0 + 1, btnw - 2, btnh - 2);
            } else if (i > this.tags_colors.length) {
                if (this.custom != null) {
                    Gdk.RGBA rgba = Gdk.RGBA ();
                    rgba.parse (this.custom);
                    rgba.alpha = 1;
                    string custom_without_alpha = rgba.to_string ();
                    DrawRoundedRectangle (cr, xpad + x0 * i, y0, btnw, btnh, "stroke", custom_without_alpha);
                    DrawRoundedRectangle (cr, xpad + x0 * i, y0, btnw, btnh, "fill", custom_without_alpha);
                    DrawGradientOverlay (cr, xpad + x0 * i, y0, btnw, btnh);
                    DrawInterrogation (cr, xpad + x0 * i, y0 + 1, btnw - 2, btnh - 2);
                }
            } else {
                DrawRoundedRectangle (cr, xpad + x0 * i, y0, btnw, btnh, "stroke", this.tags_colors[i - 1]);
                DrawRoundedRectangle (cr, xpad + x0 * i, y0, btnw, btnh, "fill", this.tags_colors[i - 1]);
                DrawGradientOverlay (cr, xpad + x0 * i, y0, btnw, btnh);
            }
        }

        return true;
    }

    private void DrawCross (Cairo.Context cr, int x, int y, int w, int h) {
        cr.new_path ();
        cr.set_line_width (2.0);
        cr.move_to (x, y);
        cr.rel_line_to (w, h);
        cr.move_to (x, y + h);
        cr.rel_line_to (w, -h);
        cr.set_source_rgba (0, 0, 0, 0.6);
        cr.stroke ();

        cr.close_path ();
    }

    /**
     * @name DrawInterrogation
     * @description draw an interrogation character over the back custom color
     * @param {Cairo.Context} cr the context to use
     * @param {int} the X position
     * @param {int} the Y position
     * @param {int} the Width of the rectangle
     * @param {int} the Height of the rectangle
     */
    private void DrawInterrogation (Cairo.Context cr, int x, int y, int w, int h) {
        string utf8 = "?";

        cr.set_source_rgba (1, 1, 1, 1);
        cr.select_font_face ("Dialog", Cairo.FontSlant.NORMAL, Cairo.FontWeight.BOLD);
        cr.set_font_size (12.0);

        Cairo.TextExtents extents;
        cr.text_extents (utf8, out extents);
        double sx = x + (w / 2) - (extents.width / 2 + extents.x_bearing);
        double sy = y + (y / 2) - (extents.height / 2 + extents.y_bearing);

        cr.move_to (sx, sy);
        cr.show_text (utf8);
    }

    /*
     * Create a rounded rectangle using the Bezier curve.
     * Adapted from http://cairographics.org/cookbook/roundedrectangles/
     */
    private void DrawRoundedRectangle (Cairo.Context cr, int x, int y, int w, int h, string style, string color) {
        int    radius_x      = 2;
        int    radius_y      = 2;
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
            rgba.parse (color);
            Gdk.cairo_set_source_rgba (cr, rgba);
            cr.fill ();
            break;
        case "stroke":
            cr.set_source_rgba (0, 0, 0, 0.5);
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
        radial.add_color_stop_rgba (0, 0.3, 0.3, 0.3, 0.0);
        radial.add_color_stop_rgba (1, 0.0, 0.0, 0.0, 0.5);

        cr.set_source (radial);
        cr.rectangle (x, y, w, h);
        cr.fill ();
    }

}
