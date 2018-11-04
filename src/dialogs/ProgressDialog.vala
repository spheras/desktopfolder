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

public class DesktopFolder.ProgressDialog : Gtk.Dialog {
    private Gtk.Widget status;
    private Gtk.Widget progress_bar;
    private Gtk.Box window_vbox;
    private uint timeout_id = 0;
    private GLib.Cancellable cancellable;

    /**
     * @constructor
     * @param FolderManager manager the manager of this window
     */
    public ProgressDialog (string title, Gtk.Window ? parent) {
        this.resizable   = false;
        this.deletable   = false;
        this.title       = title;

        this.icon_name   = "system-file-manager";
        this.window_vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        this.get_content_area ().set_border_width (10);
        this.get_content_area ().add (window_vbox);
        this.window_vbox.show ();

        this.status = new Gtk.Label (title);
        (this.status as Gtk.Label).set_size_request (500, -1);
        (this.status as Gtk.Label).set_max_width_chars (50);
        (this.status as Gtk.Label).set_ellipsize (Pango.EllipsizeMode.MIDDLE);
        (this.status as Gtk.Label).set_line_wrap (true);
        (this.status as Gtk.Label).set_line_wrap_mode (Pango.WrapMode.WORD_CHAR);
        (this.status as Gtk.Misc).set_alignment ((float) 0.0, (float) 0.5);
        window_vbox.pack_start (status, true, false, 0);

        var window_hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 2);
        this.progress_bar = new Gtk.ProgressBar ();
        window_hbox.pack_start (this.progress_bar, true, true, 0);
        var button = new Gtk.Button.from_icon_name ("process-stop-symbolic", Gtk.IconSize.BUTTON);
        button.get_style_context ().add_class ("flat");
        button.clicked.connect (() => {
            button.sensitive = false;
            this.cancellable.cancel ();
            this.stop ();
        });
        window_hbox.pack_start (button, false, false, 0);
        this.window_vbox.pack_start (window_hbox);

        this.set_transient_for (parent);
        this.show_all ();
    }

    /**
     * @name start
     * @description start the progress dialog
     */
    public GLib.Cancellable start () {
        this.cancellable = new GLib.Cancellable ();
        this.cancellable.cancelled.connect (() => {
            this.stop ();
        });

        this.show ();
        this.timeout_id = GLib.Timeout.add (100, () => {
            // this.prueba.set_text("prueba %d".printf(this.index));
            (this.progress_bar as Gtk.ProgressBar).pulse ();
            (this.status as Gtk.Label).set_text (this.text);
            return true;
        });

        return this.cancellable;
    }

    /**
     * @name stop
     * @description stop the progres bar
     */
    public void stop () {
        if (this.timeout_id > 0) {
            GLib.Source.remove (this.timeout_id);
            this.timeout_id = 0;
        }
        this.close ();
    }

    string text = "";

    /**
     * @name show_action
     * @description show the action in the progress dialog
     * @param {string} action the action to be showed
     */
    public void show_action (string action) {
        text = action;
        debug (action);
    }

}
