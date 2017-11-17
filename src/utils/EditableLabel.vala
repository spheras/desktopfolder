/*
 * Copyright (c) 2017 Lains
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 *
 * Co-authored by: Corentin Noël <corentin@elementary.io>
 *
 */

public class DesktopFolder.EditableLabel : Gtk.EventBox {
    /**
     * @name changed
     * @description Signal when the label has been changed
     */
    public signal void changed (string new_title);

    /**
     * @name on_start_editing
     * @description Signal when the label has changed to entry
     * @deprecated
     */
    public signal void on_start_editing ();

    /**
     * @name on_stop_editing
     * @description Signal when the enyty has changed to label
     * @deprecated
     */
    public signal void on_stop_editing ();

    private Gtk.Label title_label { private set; public get; }
    private Gtk.Entry title_entry;
    private Gtk.Stack stack;

    public string text {
        get {
            return title_label.label;
        }
        set {
            title_label.label = value;
        }
    }

    public bool editing {
        private set {
            if (value) {
                // debug("set editing true");
                title_entry.text = title_label.label;
                stack.set_visible_child (title_entry);
                title_entry.grab_focus_without_selecting ();
            } else {
                // debug("set editing false");
                title_entry.text = title_entry.text.strip ();
                if (title_entry.text.strip () != "" && title_label.label != title_entry.text) {
                    // title_label.label = title_entry.text;
                    changed (title_entry.text);
                }
                stack.set_visible_child (title_label);
            }
        }
        public get {
            return stack.get_visible_child () == title_entry;
        }
    }

    public EditableLabel (string ? title_name) {

        title_label         = new Gtk.Label (title_name);
        title_label.hexpand = true;
        // title_label.margin_top = 3;
        // This left margin is used to actually align the label to the position
        // of a window title. Only using Gtk.Align.CENTER doesn't do the job.
        // title_label.margin_left = 32;
        title_label.valign = Gtk.Align.CENTER;
        title_label.halign = Gtk.Align.FILL;

        title_label.get_style_context ().add_class ("df_label");
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.set_line_wrap (true);
        title_label.set_justify (Gtk.Justification.CENTER);
        title_label.set_ellipsize (Pango.EllipsizeMode.END);
        title_label.set_lines (1);

        title_entry        = new Gtk.Entry ();
        title_entry.halign = Gtk.Align.CENTER;
        title_entry.valign = Gtk.Align.FILL;
        title_entry.set_style (title_label.get_style ());
        // Minimum entry with
        title_entry.set_width_chars (1);

        stack                 = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add (title_label);
        stack.add (title_entry);
        add (stack);

        // Clicked on the title
        // This event should be managed only by this.title_label
        this.button_press_event.connect ((event) => {
            if (event.type == Gdk.EventType.@2BUTTON_PRESS) {
                this.start_editing ();
                return true;
            }
            return false;
        });

        // If press intro while editting
        this.title_entry.activate.connect (() => {
            // debug ("title_entry.activate.connect");
            this.stop_editing ();
        });

        // focus lost while editing
        this.title_entry.focus_out_event.connect ((event) => {
            // debug ("title_entry.focus_out_event.connect");
            this.stop_editing ();
            return false;
        });

        // keyboard shortcuts
        this.key_release_event.connect (this.on_key);
        this.key_press_event.connect (this.on_key);
    }

    /**
     * @name on_key
     * @description the key event captured for the window
     * @param EventKey event the event produced
     * @return bool @see the on_key signal
     */
    private bool on_key (Gdk.EventKey event) {
        // debug ("EditableLabel on_key, event: %s", event.type == Gdk.EventType.KEY_RELEASE ? "KEY_RELEASE" : event.type == Gdk.EventType.KEY_PRESS ? "KEY_PRESS" : "OTRO");
        int key = (int) event.keyval;
        // debug ("EditableLabel event key %d", key);

        var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);

        const int ESCAPE_KEY = 65307;

        if (control_pressed) {
            if (key == 'z' || key == 'Z') {
                this.undo_changes ();
            }
        } else if (key == ESCAPE_KEY) {
            this.undo_changes ();
            this.stop_editing ();
        }

        return true;
    }

    /**
     * @name start_editing
     * @description Actions to be performed to start editing
     */
    public void start_editing () {
        editing = true;
        on_start_editing ();
    }

    /**
     * @name stop_editing
     * @description Actions to be performed to stop editing
     */
    public void stop_editing () {
        if (editing == true) {
            // debug("stop editing");
            editing = false;
            on_stop_editing ();
        }
    }

    /**
     * @name undo_changes
     * @description Actions to be performed to undo chenges when editing
     */
    private void undo_changes () {
        title_entry.text = title_label.label;
    }

    /**
     * @name set_lines
     * @description Sets the number of lines of the Gtk.label component
     * @see Gkt.label
     */
    public void set_lines (int n) {
        this.title_label.set_lines (n);
    }

    /**
     * @name set_lines
     * @description Sets the mode used to ellipsize (add an ellipsis: "...") to
     * the text if there is not enough space to render the entire string.
     * @see Gkt.label
     */
    public void set_ellipsize (Pango.EllipsizeMode mode) {
        this.title_label.set_ellipsize (mode);
    }

}
