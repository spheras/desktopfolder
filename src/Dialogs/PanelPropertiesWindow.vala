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
        private enum ResolutionStrategy {
            NONE,
            SCALE,
            STORE
        }
        private Gtk.Stack main_stack;
        private Gtk.Switch highlight_current_line;
        private Gtk.Switch highlight_matching_brackets;
        private Gtk.ComboBoxText style_scheme;
        private Gtk.Switch use_custom_font;
        private Gtk.FontButton select_font;
        private FolderWindow window;
        private FolderManager manager;

        public PanelProperties (FolderWindow window) {
            Object (
                border_width: 5,
                deletable:    false,
                resizable:    false,
                title:        _("Properties")
            );

            this.window  = window;
            this.manager = this.window.get_manager ();
            build ();
        }

        /**
         * @name build
         * @description build the window components
         */
        private void build () {
            main_stack               = new Gtk.Stack ();
            main_stack.margin        = 12;
            main_stack.margin_bottom = 18;
            main_stack.margin_top    = 24;
            main_stack.add_titled (get_properties_box (), "properties", DesktopFolder.Lang.PANELPROPERTIES_PROPERTIES);
            main_stack.add_titled (get_general_box (), "general", DesktopFolder.Lang.PANELPROPERTIES_GENERAL);

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.homogeneous  = true;

            main_stackswitcher.margin_left  = 12;
            main_stackswitcher.margin_right = 12;

            var main_grid = new Gtk.Grid ();
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            get_content_area ().add (main_grid);

            var close_button = new Gtk.Button.with_label (DesktopFolder.Lang.PANELPROPERTIES_CLOSE);
            close_button.clicked.connect (() => {
                destroy ();
            });

            add_action_widget (close_button, 0);
        }

        /**
         * @name get_properties_box
         * @description build the properties section
         * @return {Gtk.Widget} the built Gtk.Grid widget
         */
        private Gtk.Widget get_properties_box () {
            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing    = 6;
            general_grid.column_spacing = 12;

            // The behavior section
            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_BEHAVIOR), 0, 0, 2, 1);
            // align to grid
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ALIGN_TO_GRID), 0, 1, 1, 1);
            SettingsSwitch settings_switch = new SettingsSwitch ("align_to_grid");
            general_grid.attach (settings_switch, 1, 1, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().align_to_grid);
            settings_switch.notify["active"].connect (this.window.on_toggle_align_to_grid);
            // lock items
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_ITEMS), 0, 2, 1, 1);
            settings_switch = new SettingsSwitch ("lock_items");
            general_grid.attach (settings_switch, 1, 2, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().lockitems);
            settings_switch.notify["active"].connect (this.window.on_toggle_lockitems);
            // lock panel
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_PANEL), 0, 3, 1, 1);
            settings_switch = new SettingsSwitch ("lock_panel");
            general_grid.attach (settings_switch, 1, 3, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().lockpanel);
            settings_switch.notify["active"].connect (this.window.on_toggle_lockpanel);

            // The interface section
            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_INTERFACE), 0, 4, 2, 1);
            // Tet shadow
            settings_switch = new SettingsSwitch ("text_shadow");
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_SHADOW), 0, 5, 1, 1);
            general_grid.attach (settings_switch, 1, 5, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().textshadow);
            settings_switch.notify["active"].connect (this.window.on_toggle_shadow);
            // text bold
            settings_switch = new SettingsSwitch ("text_bold");
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_BOLD), 0, 6, 1, 1);
            general_grid.attach (settings_switch, 1, 6, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().textbold);
            settings_switch.notify["active"].connect (this.window.on_toggle_bold);

            return general_grid;
        }

        private Gtk.Widget get_general_box () {
            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing    = 6;
            general_grid.column_spacing = 12;


            GLib.Settings settings = new GLib.Settings ("com.github.spheras.desktopfolder");

            // PANEL OVER DESKTOP
            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_PANEL), 0, 0, 2, 1);
            Gtk.Label description = new Gtk.Label (DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_PANEL_DESCRIPTION);
            description.set_single_line_mode (false);
            description.wrap = true;
            description.set_size_request (100, -1);
            description.set_max_width_chars (50);
            description.set_line_wrap (true);
            description.set_line_wrap_mode (Pango.WrapMode.WORD_CHAR);
            general_grid.attach (description, 0, 1, 2, 2);

            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_PANEL), 0, 3, 1, 1);
            SettingsSwitch settings_switch = new SettingsSwitch ("desktop_panel");
            general_grid.attach (settings_switch, 1, 3, 1, 1);

            settings_switch.set_active (settings.get_boolean ("desktop-panel"));
            settings_switch.notify["active"].connect (() => {
                settings.set_boolean ("desktop-panel", !settings.get_boolean ("desktop-panel"));
            });


            // RESOLUTION STRATEGY
            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY), 0, 4, 2, 1);
            description      = new Gtk.Label (DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_DESCRIPTION);
            description.set_single_line_mode (false);
            description.wrap = true;
            description.set_size_request (100, -1);
            description.set_max_width_chars (50);
            description.set_line_wrap (true);
            description.set_line_wrap_mode (Pango.WrapMode.WORD_CHAR);
            general_grid.attach (description, 0, 5, 2, 2);

            var strategy_combo = new Gtk.ComboBoxText ();
            strategy_combo.append ("NONE", _("None"));
            strategy_combo.append ("SCALE", _("Scale"));
            strategy_combo.append ("STORE", _("Store"));
            settings.bind ("resolution-strategy", strategy_combo, "active-id", GLib.SettingsBindFlags.DEFAULT);
            general_grid.attach (strategy_combo, 0, 7, 1, 1);

            return general_grid;
        }

        private void populate_style_scheme () {
            string[] scheme_ids;
            var      scheme_manager = new Gtk.SourceStyleSchemeManager ();
            scheme_ids = scheme_manager.get_scheme_ids ();

            foreach (string scheme_id in scheme_ids) {
                var scheme = scheme_manager.get_scheme (scheme_id);
                style_scheme.append (scheme.id, scheme.name);
            }
        }

        private class SettingsHeader : Gtk.Label {
            public SettingsHeader (string text) {
                label  = text;
                get_style_context ().add_class ("h4");
                halign = Gtk.Align.START;
            }

        }

        private class SettingsLabel : Gtk.Label {
            public SettingsLabel (string text) {
                label        = text;
                halign       = Gtk.Align.END;
                margin_start = 12;
            }

        }

        private class SettingsSwitch : Gtk.Switch {
            public SettingsSwitch (string setting) {
                halign = Gtk.Align.START;
                // Scratch.settings.schema.bind (setting, this, "active", SettingsBindFlags.DEFAULT);
            }

        }
    }
}
