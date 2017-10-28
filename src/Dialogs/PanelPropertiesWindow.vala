/* This code was mostly imported from elementary: https://github.com/elementary/scratch/blob/master/src/Dialogs/PropertiesDialog.vala
*
* Copyright (c) 2011-2017 elementary LLC (https://elementary.io)
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
* Boston, MA 02110-1301 USA.
*
* Authored by: Giulio Collura <random.cpp@gmail.com>
*              Mario Guerriero <mario@elementaryos.org>
*              Fabio Zaramella <ffabio.96.x@gmail.com>
*/

namespace DesktopFolder.Dialogs {
    public class PanelProperties : Gtk.Dialog {
        private Gtk.Stack main_stack;
        private Gtk.Switch highlight_current_line;
        private Gtk.Switch highlight_matching_brackets;
        private Gtk.ComboBoxText style_scheme;
        private Gtk.Switch use_custom_font;
        private Gtk.FontButton select_font;

        public PanelProperties (FolderWindow window) {
            Object (
                border_width: 5,
                deletable:    false,
                resizable:    false,
                title:        _("Properties")
            );
        }

        construct {
            //Scratch.settings.schema.bind ("indent-width", indent_width, "value", SettingsBindFlags.DEFAULT);

            main_stack = new Gtk.Stack ();
            main_stack.margin = 12;
            main_stack.margin_bottom = 18;
            main_stack.margin_top = 24;
            main_stack.add_titled (get_behavior_box (), "behavior", _("Behavior"));
            main_stack.add_titled (get_interface_box (), "interface", _("Interface"));

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.homogeneous = true;
            
            main_stackswitcher.margin_left = 12;
            main_stackswitcher.margin_right = 12;

            var main_grid = new Gtk.Grid ();
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            get_content_area ().add (main_grid);

            var close_button = new Gtk.Button.with_label (_("Close"));
            close_button.clicked.connect (() => {
                destroy ();
            });
            
            add_action_widget (close_button, 0);
        }
        
        private Gtk.Widget get_behavior_box () {
            var general_grid = new Gtk.Grid ();
            general_grid.column_spacing = 12;
            general_grid.row_spacing = 6;
            general_grid.attach (new SettingsHeader (_("Shortcuts")), 0, 0, 2, 1);
            general_grid.attach (new SettingsLabel (_("Show Desktop:")), 0, 1, 1, 1);
            general_grid.attach (new SettingsSwitch ("autosave"), 1, 1, 1, 1);
            
            return general_grid;
        }

        private Gtk.Widget get_interface_box () {
            var content = new Gtk.Grid ();
            content.row_spacing = 6;
            content.column_spacing = 12;

            var editor_header = new SettingsHeader (_("Editor"));

            var highlight_current_line_label = new SettingsLabel (_("Highlight current line:"));
            highlight_current_line = new SettingsSwitch ("highlight-current-line");

            var highlight_matching_brackets_label = new SettingsLabel (_("Highlight matching brackets:"));
            highlight_matching_brackets = new SettingsSwitch ("highlight-matching-brackets");

            var draw_spaces_label = new SettingsLabel (_("Draw Spaces:"));
            var draw_spaces_combo = new Gtk.ComboBoxText ();
            draw_spaces_combo.append ("Small", _("Small"));
            draw_spaces_combo.append ("Medium", _("Medium"));
            draw_spaces_combo.append ("Large", _("Large"));
            //Scratch.settings.schema.bind ("draw-spaces", draw_spaces_combo, "active-id", SettingsBindFlags.DEFAULT);

            var show_right_margin_label = new SettingsLabel (_("Line width guide:"));
            var show_right_margin = new SettingsSwitch ("show-right-margin");

            var right_margin_position = new Gtk.SpinButton.with_range (1, 250, 1);
            right_margin_position.hexpand = true;
            //Scratch.settings.schema.bind ("right-margin-position", right_margin_position, "value", SettingsBindFlags.DEFAULT);
            //Scratch.settings.schema.bind ("show-right-margin", right_margin_position, "sensitive", SettingsBindFlags.DEFAULT);

            var appearance_header = new SettingsHeader (_("Appearance"));

            var icon_size_label = new SettingsLabel (_("Icon size:"));
            
            var icon_size_combo = new Gtk.ComboBoxText ();
            icon_size_combo.append ("small", _("Small"));
            icon_size_combo.append ("medium", _("Medium"));
            icon_size_combo.append ("large", _("Large"));
            icon_size_combo.append ("huge", _("Huge"));
            //settings.schema.bind ("icon-size", icon_size_combo, "active-id", SettingsBindFlags.DEFAULT);
            
            content.attach (appearance_header, 0, 7, 3, 1);
            content.attach (icon_size_label, 0, 8, 1, 1);
            content.attach (icon_size_combo, 1, 8, 2, 1);
            
            //content.attach (editor_header, 0, 0, 3, 1);
            //content.attach (highlight_current_line_label, 0, 1, 1, 1);
            //content.attach (highlight_current_line, 1, 1, 1, 1);
            //content.attach (highlight_matching_brackets_label, 0, 2, 1, 1);
            //content.attach (highlight_matching_brackets, 1, 2, 1, 1);

            //content.attach (show_right_margin_label, 0, 6, 1, 1);
            //content.attach (show_right_margin, 1, 6, 1, 1);
            //content.attach (right_margin_position, 2, 6, 1, 1);

            return content;
        }

        private void populate_style_scheme () {
            string[] scheme_ids;
            var scheme_manager = new Gtk.SourceStyleSchemeManager ();
            scheme_ids = scheme_manager.get_scheme_ids ();

            foreach (string scheme_id in scheme_ids) {
                var scheme = scheme_manager.get_scheme (scheme_id);
                style_scheme.append (scheme.id, scheme.name);
            }
        }

        private class SettingsHeader : Gtk.Label {
            public SettingsHeader (string text) {
                label = text;
                get_style_context ().add_class ("h4");
                halign = Gtk.Align.START;
            }
        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label = text;
                halign = Gtk.Align.END;
                margin_start = 12;
            }
        }

        private class SettingsSwitch : Gtk.Switch {
            public SettingsSwitch (string setting) {
                halign = Gtk.Align.START;
                //Scratch.settings.schema.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
            }
        }
    }
}
