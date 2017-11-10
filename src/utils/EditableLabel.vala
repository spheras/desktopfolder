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
    public signal void changed (string new_title);

    private Gtk.Label title_label;
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

        title_label           = new Gtk.Label (title_name);
        title_label.ellipsize = Pango.EllipsizeMode.END;
        title_label.hexpand   = true;
        // title_label.margin_top = 3;
        // This left margin is used to actually align the label to the position
        // of a window title. Only using Gtk.Align.CENTER doesn't do the job.
        // title_label.margin_left = 32;
        title_label.valign = Gtk.Align.CENTER;
        title_label.halign = Gtk.Align.FILL;

        title_label.set_width_chars (14);
        title_label.set_max_width_chars (14);
        title_label.wrap_mode = Pango.WrapMode.WORD_CHAR;
        title_label.set_line_wrap (true);
        title_label.set_justify (Gtk.Justification.CENTER);


        title_entry        = new Gtk.Entry ();
        title_entry.halign = Gtk.Align.FILL;
        title_entry.set_style (title_label.get_style ());

        stack                 = new Gtk.Stack ();
        stack.transition_type = Gtk.StackTransitionType.CROSSFADE;
        stack.add (title_label);
        stack.add (title_entry);
        add (stack);

        this.get_style_context ().add_class ("title");

        // Change the cursor over the title label
        // This event should be managed only by this.title_label
        this.enter_notify_event.connect ((event) => {
            // debug("EditableLabel: enter_notify_event");
            get_window ().set_cursor (new Gdk.Cursor.for_display (Gdk.Display.get_default (), Gdk.CursorType.PENCIL));
            return false;
        });

        // Clicked on the title
        // This event should be managed only by this.title_label
        this.button_release_event.connect ((event) => {
            // debug ("EditableLabel: button_realease_event");
            editing = true;
            return true;
        });

        //// To prevent default popup and parent move
        //// This event should be managed only by this.title_label
        // this.button_press_event.connect ((event) => {
        //// debug ("EditableLabel: button_press_event");
        // return true;
        // });

        // If press intro while editting
        this.title_entry.activate.connect (() => {
            // debug ("title_entry.activate.connect");
            editing = false;
        });

        // focus lost while editing
        this.title_entry.focus_out_event.connect ((event) => {
            // debug ("title_entry.focus_out_event.connect");
            editing = false;
            return false;
        });

        // Shotcuts
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
        int key = (int) event.keyval;
        // debug("event key %d",key);

        var  mods            = event.state & Gtk.accelerator_get_default_mod_mask ();
        bool control_pressed = ((mods & Gdk.ModifierType.CONTROL_MASK) != 0);

        if (control_pressed) {
            if (key == 'z' || key == 'Z') {
                title_entry.text = title_label.label;
            }
        }
        return false;
    }

}
