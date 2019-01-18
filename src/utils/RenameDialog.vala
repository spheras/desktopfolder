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

public class RenameDialog : Gtk.Dialog {
    private Gtk.Entry entry;

    public signal void on_rename (string new_name);
    public signal void on_cancel ();

    public RenameDialog (Gtk.Window parent, string title, string label_message, string entry_text) {
        if (parent != null) {
            this.set_transient_for (parent);
        }
        this.title        = title;
        this.border_width = 5;
        set_default_size (350, 100);
        this.get_style_context ().add_class ("df_dialog");
        this.set_decorated (true);
        this.window_position = Gtk.WindowPosition.MOUSE;

        create_widgets (label_message, entry_text);
        connect_signals ();
    }

    private void create_widgets (string label_message, string entry_text) {

        var description = new Gtk.Label (label_message);
        description.halign = Gtk.Align.START;
        this.entry         = new Gtk.Entry ();
        this.entry.activate.connect (() => {
            this.response (Gtk.ResponseType.OK);
        });
        this.entry.set_text (entry_text);

        // Layout widgets
        Gtk.Box hbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        hbox.pack_start (description, false, true, 0);
        hbox.pack_start (entry, true, true, 0);

        var grid = new Gtk.Grid ();
        grid.margin = 10;
        grid.attach (hbox, 0, 0, 1, 1);

        Gtk.Box content = this.get_content_area () as Gtk.Box;
        content.pack_start (grid, false, true, 0);
        content.spacing = 10;

        // Add buttons to button area at the bottom
        add_button (DesktopFolder.Lang.DIALOG_OK, Gtk.ResponseType.OK);
        add_button (DesktopFolder.Lang.DIALOG_CANCEL, Gtk.ResponseType.CANCEL);
    }

    private void connect_signals () {
        this.response.connect (on_response);
    }

    private void on_response (Gtk.Dialog source, int response_id) {
        switch (response_id) {
        case Gtk.ResponseType.OK:
            this.on_rename (this.entry.get_text ());
            this.destroy ();
            break;
        case Gtk.ResponseType.CANCEL:
            this.on_cancel ();
            this.destroy ();
            break;
        }
    }

}
