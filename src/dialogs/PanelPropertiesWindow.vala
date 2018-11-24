/* This code was mostly imported from elementary: https://github.com/elementary/scratch/blob/master/src/Dialogs/PropertiesDialog.vala
 *
 * Copyright (c) 2011-2017 elementary LLC (https://elementary.io)
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
 *
 * Authored by: Giulio Collura <random.cpp@gmail.com>
 *              Mario Guerriero <mario@elementaryos.org>
 *              Fabio Zaramella <ffabio.96.x@gmail.com>
 */

namespace DesktopFolder.Dialogs {

    public class OpenWith : Gtk.AppChooserDialog  {
        public OpenWith (string content_type, string path) {
            string cleaned_path = "'" + path.replace ("'", "'\\''") + "'";
            var    dialog       = new Gtk.AppChooserDialog.for_content_type (
                this, 0, content_type
                );
            if (dialog.run () == Gtk.ResponseType.OK) {
                AppInfo info = dialog.get_app_info ();
                if (info != null) {
                    try {
                        Process.spawn_command_line_async (
                            info.get_executable () + " " + cleaned_path);
                    } catch (SpawnError e) {
                        // nothing to be done
                    }
                }
            }
            dialog.close ();
        }

    }

    public class PanelProperties : Gtk.Dialog {
        private enum ResolutionStrategy {
            NONE,
            SCALE,
            STORE
        }
        private Gtk.Stack main_stack;
        private FolderWindow window;
        private FolderManager manager;
        private Gtk.Widget properties_grid;

        public PanelProperties (FolderWindow window) {
            Object (
                border_width: 5,
                deletable:    false,
                resizable:    false,
                modal: true,
                title:        DesktopFolder.Lang.PANELPROPERTIES_PROPERTIES
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
            this.properties_grid     = get_properties_box ();
            main_stack.add_titled (properties_grid, "properties", DesktopFolder.Lang.PANELPROPERTIES_PROPERTIES);
            main_stack.add_titled (get_general_box (), "general", DesktopFolder.Lang.PANELPROPERTIES_GENERAL);

            var version_label = new Gtk.Label ("Version " + DesktopFolder.VERSION.up ());
            version_label.set_size_request (250, -1);
            version_label.xalign = 0;

            var main_stackswitcher = new Gtk.StackSwitcher ();
            main_stackswitcher.set_stack (main_stack);
            main_stackswitcher.homogeneous  = true;

            main_stackswitcher.margin_start = 12;
            main_stackswitcher.margin_end   = 12;

            var main_grid = new Gtk.Grid ();
            main_grid.attach (main_stackswitcher, 0, 0, 1, 1);
            main_grid.attach (main_stack, 0, 1, 1, 1);

            get_content_area ().add (main_grid);

            var close_button = new Gtk.Button.with_label (DesktopFolder.Lang.PANELPROPERTIES_CLOSE);
            close_button.clicked.connect (() => {
                destroy ();
            });

            add_action_widget (version_label, 1);
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

            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT), 0, 1, 1, 1);
            var arrangement_combo = new Gtk.ComboBoxText ();
            arrangement_combo.append ("FREE", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_FREE);
            arrangement_combo.append ("GRID", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_GRID);
            arrangement_combo.append ("MANAGED", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_MANAGED);
            arrangement_combo.active = this.manager.get_settings ().arrangement_type - 1;
            arrangement_combo.changed.connect (() => {
                if (arrangement_combo.get_active_id () == "FREE") {
                    this.manager.on_arrange_change (FolderArrangement.ARRANGEMENT_TYPE_FREE);
                } else if (arrangement_combo.get_active_id () == "GRID") {
                    this.manager.on_arrange_change (FolderArrangement.ARRANGEMENT_TYPE_GRID);
                } else {
                    this.manager.on_arrange_change (FolderArrangement.ARRANGEMENT_TYPE_MANAGED);
                }
            });
            arrangement_combo.expand = true;
            general_grid.attach (arrangement_combo, 1, 1, 1, 1);

            /*
               // align to grid
               general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ALIGN_TO_GRID), 0, 1, 1, 1);
               SettingsSwitch settings_switch = new SettingsSwitch ("align_to_grid");
               settings_switch.set_active (this.manager.get_settings ().align_to_grid);
               general_grid.attach (settings_switch, 1, 1, 1, 1);
               settings_switch.notify["active"].connect (this.window.on_toggle_align_to_grid);
             */


            // lock items
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_ITEMS), 0, 2, 1, 1);
            SettingsSwitch settings_switch = new SettingsSwitch ("lock_items");
            general_grid.attach (settings_switch, 1, 2, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().lockitems);
            settings_switch.notify["active"].connect (this.window.on_toggle_lockitems);

            int top_offset = -1;

            if (this.window.get_type () != typeof (DesktopFolder.DesktopWindow)) {
                top_offset = 0;
                // lock panel
                general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_LOCK_PANEL), 0, 3, 1, 1);
                settings_switch = new SettingsSwitch ("lock_panel");
                general_grid.attach (settings_switch, 1, 3, 1, 1);
                settings_switch.set_active (this.manager.get_settings ().lockpanel);
                settings_switch.notify["active"].connect (this.window.on_toggle_lockpanel);
            }

            // The interface section
            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_APPEARANCE), 0, 4 + top_offset, 2, 1);
            // Tet shadow
            settings_switch = new SettingsSwitch ("text_shadow");
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_SHADOW), 0, 5 + top_offset, 1, 1);
            general_grid.attach (settings_switch, 1, 5 + top_offset, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().textshadow);
            settings_switch.notify["active"].connect (this.window.on_toggle_shadow);
            // text bold
            settings_switch = new SettingsSwitch ("text_bold");
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.DESKTOPFOLDER_MENU_TEXT_BOLD), 0, 6 + top_offset, 1, 1);
            general_grid.attach (settings_switch, 1, 6 + top_offset, 1, 1);
            settings_switch.set_active (this.manager.get_settings ().textbold);
            settings_switch.notify["active"].connect (this.window.on_toggle_bold);

            // the items padding
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_PADDING), 0, 7 + top_offset, 1, 1);
            var scale = new Gtk.SpinButton.with_range (0, 50, 1);
            scale.set_value (this.manager.get_settings ().arrangement_padding);
            scale.value_changed.connect (() => {
                this.manager.get_settings ().arrangement_padding = (int) scale.get_value ();
                if (this.manager.get_arrangement ().force_organization ()) {
                    this.manager.organize_panel_items ();
                }
            });
            general_grid.attach (scale, 1, 7 + top_offset, 1, 1);


            if (this.window.get_type () == typeof (DesktopFolder.DesktopWindow) && (!this.manager.get_application ().get_desktoppanel_enabled () || !this.manager.get_application ().get_desktopicons_enabled ())) {
                general_grid.set_sensitive (false);
            }

            return general_grid;
        }

        /**
         * @name set_property_page_sensitivity
         * @description set sensitivity of properties page items
         */
        private void set_property_page_sensitivity (bool sensitivity) {
            if (this.properties_grid != null) {
                properties_grid.set_sensitive (sensitivity);
            }
        }

        /**
         * @name get_general_box
         * @description build the general section
         * @return {Gtk.Widget} the built Gtk.Grid widget
         */
        private Gtk.Widget get_general_box () {
            var general_grid = new Gtk.Grid ();
            general_grid.row_spacing    = 6;
            general_grid.column_spacing = 12;


            GLib.Settings settings = new GLib.Settings ("com.github.spheras.desktopfolder");

            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_GENERAL), 0, 0, 2, 1);

            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_ICONS), 0, 1, 1, 1);

            SettingsSwitch settings_switch = new SettingsSwitch ("icons-on-desktop");
            settings_switch.halign     = Gtk.Align.START;
            settings_switch.margin_end = 8;
            general_grid.attach (settings_switch, 1, 1, 1, 1);

            settings_switch.set_active (settings.get_boolean ("icons-on-desktop"));
            settings_switch.notify["active"].connect (() => {
                bool desktopicons_enabled = settings.get_boolean ("icons-on-desktop");
                settings.set_boolean ("icons-on-desktop", !desktopicons_enabled);
                if (this.window.get_type () == typeof (DesktopFolder.DesktopWindow)) {
                    this.set_property_page_sensitivity (!desktopicons_enabled);
                }
            });

            // Uncomment the following block when the option to remove DesktopWindow is wanted again
            /*
               general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_PANEL), 0, 2, 1, 1);

               settings_switch = new SettingsSwitch ("desktop_panel");
               settings_switch.halign = Gtk.Align.START;
               settings_switch.margin_end = 8;
               general_grid.attach (settings_switch, 1, 2, 1, 1);

               var icons_on_desktop_help = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
               icons_on_desktop_help.halign = Gtk.Align.START;
               icons_on_desktop_help.hexpand = true;
               icons_on_desktop_help.tooltip_text = DesktopFolder.Lang.PANELPROPERTIES_DESKTOP_PANEL_DESCRIPTION;
               general_grid.attach (icons_on_desktop_help, 2, 2, 1, 1);

               settings_switch.set_active (settings.get_boolean ("desktop-panel"));
               settings_switch.notify["active"].connect (() => {
                bool desktop_enabled = settings.get_boolean ("desktop-panel");
                settings.set_boolean ("desktop-panel", !desktop_enabled);
                if (this.window.get_type () == typeof (DesktopFolder.DesktopWindow)) {
                    this.set_property_page_sensitivity (!desktop_enabled);
                }
               });
             */

            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY), 0, 3, 1, 1);

            var strategy_combo = new Gtk.ComboBoxText ();
            strategy_combo.append ("NONE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_NONE);
            strategy_combo.append ("SCALE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_SCALE);
            strategy_combo.append ("STORE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_STORE);
            settings.bind ("resolution-strategy", strategy_combo, "active-id", GLib.SettingsBindFlags.DEFAULT);
            strategy_combo.margin_end = 8;
            general_grid.attach (strategy_combo, 1, 3, 1, 1);

            var resolution_strategy_help = new Gtk.Image.from_icon_name ("help-info-symbolic", Gtk.IconSize.BUTTON);
            resolution_strategy_help.halign       = Gtk.Align.START;
            resolution_strategy_help.hexpand      = true;
            resolution_strategy_help.tooltip_text = DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_DESCRIPTION;
            general_grid.attach (resolution_strategy_help, 2, 3, 1, 1);

            general_grid.attach (new SettingsHeader (DesktopFolder.Lang.PANELPROPERTIES_ICONS), 0, 4, 2, 1);

            // DEFAULT Panel Arrangement
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_DEFAULT), 0, 5, 1, 1);
            var arrangement_combo = new Gtk.ComboBoxText ();
            arrangement_combo.append ("FREE", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_FREE);
            arrangement_combo.append ("GRID", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_GRID);
            arrangement_combo.append ("MANAGED", DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_MANAGED);
            settings.bind ("default-arrangement", arrangement_combo, "active-id", GLib.SettingsBindFlags.DEFAULT);
            arrangement_combo.margin_end = 8;
            general_grid.attach (arrangement_combo, 1, 5, 1, 1);

            // DEFAULT Panel Arrangement
            general_grid.attach (new SettingsLabel (DesktopFolder.Lang.PANELPROPERTIES_ARRANGEMENT_PADDING_DEFAULT), 0, 6, 1, 1);
            var scale = new Gtk.SpinButton.with_range (0, 50, 1);
            scale.set_value (settings.get_int ("default-arrangement-padding"));
            scale.value_changed.connect (() => {
                settings.set_int ("default-arrangement-padding", (int) scale.get_value ());
            });
            general_grid.attach (scale, 1, 6, 1, 1);

            return general_grid;
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
