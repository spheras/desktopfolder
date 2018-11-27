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


    public class ShowInfo : Gtk.Window {

        private string filepath;
        private File file;
        FileInfo general_info;

        public ShowInfo(string fpath, string fname) {

            // general
            this.filepath = fpath;
            this.file = File.new_for_commandline_arg(this.filepath ); 
            general_info = this.file.query_info ("*", FileQueryInfoFlags.NONE);
            // essential info we need to decide on the gui elements
            bool is_a_link = FileUtils.test (this.filepath , FileTest.IS_SYMLINK);
            bool is_a_folder = FileUtils.test (this.filepath , FileTest.IS_DIR);
            // window props
            this.set_title(DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_FILEINFO);
            this.set_modal(true);
            this.set_default_size (400, 200);
            // get file icon & maingrid
            Gtk.Image fileicon = get_fileicon();
            var maingrid = new Gtk.Grid();
            maingrid.attach(fileicon, 1, 1, 1, 2);
            maingrid.set_column_spacing(20);
            maingrid.set_row_spacing(10);
            maingrid.attach(new Gtk.Label(""), 0, 0, 1, 1);
            maingrid.attach(new Gtk.Label(""), 100, 100, 1, 1);
            // name
            var name_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_FILENAME.concat(":"));
            var name_value = new Gtk.Label(fname);
            // location
            string location = filepath.replace("/" + fname, "");
            var location_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_LOCATION.concat(":"));
            var location_value = new Gtk.Label(location);
            // content type
            var content_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_CONTENTTYPE.concat(":"));
            var content_value = new Gtk.Label("");

            Gtk.Label[] labels = {
                name_label, location_label, content_label
            };

            Gtk.Label[] values = {
                name_value, location_value, content_value
            };

            // content type & fill in gui, depending on type
            string content = get_filetype();
            if (is_a_link) {
                content = "inode/symlink"; // overrule possibly different output from get_filetype()
                var target_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_SHOW_TARGET.concat(":"));
                labels += target_label;
                string target = general_info.get_symlink_target ();
                var target_value = new Gtk.Label(target);
                values += target_value;
            }
            else if (is_a_folder) {
                // get n-files
                int64[] folderdata = get_folderdata();
                // labels / values
                var n_items_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_CONTENT.concat(":"));
                labels += n_items_label;
                var total_size_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_TOTALSIZE.concat(":"));
                labels += total_size_label;
                string n_items = folderdata[0].to_string().concat(" ", DesktopFolder.Lang.ITEM_PROPSWINDOW_N_ITEMS);
                var n_items_value = new Gtk.Label(n_items);
                values += n_items_value;
                string totalsize = get_readablesize(folderdata[1]);
                var total_size_value = new Gtk.Label(totalsize);
                values += total_size_value;
                if (folderdata[0] == -1) {
                    n_items_value.set_text("?");
                    total_size_value.set_text("?");
                }
            }
            else {
                var filesize_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_FILESIZE.concat(":"));
                labels += filesize_label;
                string filesize = get_readablesize(general_info.get_size());
                var filesize_value = new Gtk.Label(filesize);
                values += filesize_value;
                // executable, unfortunately, we cannot add it to attach-list; its not a Label
                maingrid.attach(new Gtk.Label(""), 1, 10, 1, 1);
                var executable_label = new Gtk.Label(DesktopFolder.Lang.ITEM_MENU_EXECUTE.concat(":"));
                maingrid.attach(executable_label, 2, 11, 1, 1);
                var executable_value = new Gtk.CheckButton.with_label(DesktopFolder.Lang.ITEM_PROPSWINDOW_ALLOWEXECUTE);
                bool isexec = FileUtils.test (this.filepath, FileTest.IS_EXECUTABLE);
                executable_value.set_active(isexec);
                maingrid.attach(executable_value, 3, 11, 1, 1);
                executable_value.toggled.connect(toggle_executable);
            }

            content_value.set_text(content);
            // separate acces/modify time
            labels += new Gtk.Label("");
            values += new Gtk.Label("");
            string[] timedata = get_filetime();            
            if (!is_a_folder) {
                var last_accessed_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_LASTUSED.concat(":"));
                labels += last_accessed_label;
                var last_accessed_value = new Gtk.Label(timedata[0]);
                values += last_accessed_value;
            }
            var last_modified_label = new Gtk.Label(DesktopFolder.Lang.ITEM_PROPSWINDOW_LASTMODIFIED.concat(":"));
            labels += last_modified_label;
            var last_modified_value = new Gtk.Label(timedata[1]);
            values += last_modified_value;
            int labelpos = 1;
            foreach (Gtk.Label l in labels) {
                l.set_xalign(0);
                maingrid.attach(l, 2, labelpos, 1, 1);
                labelpos += 1;
            }
            int valuepos = 1;
            foreach (Gtk.Label l in values) {
                l.set_xalign(0);
                l.set_ellipsize(Pango.EllipsizeMode.END);
                l.set_selectable(true);
                maingrid.attach(l, 3, valuepos, 1, 1);
                valuepos += 1;
            }

            this.add(maingrid);
            maingrid.show_all();
            this.show_all();
        }

        public string get_readablesize (int64 bytes) {
            // convert to readable size, decide on unit
            string unit;
            double size;
            if (bytes >= 1000000000000) {
                size = bytes/1000000000000.0;
                unit = "TB";
            }
            else if (bytes >= 1000000000) {
                size = bytes/1000000000.0;
                unit = "GB";
            }
            else if (bytes >= 1000000) {
                size = bytes/1000000.0;
                unit = "MB";
            }
            else if (bytes >= 1000) {
                size = bytes/1000.0;
                unit = "kB";
            }
            else {
                size = bytes;
                unit = "byte";
            }
            // prevent silly .0 if first decimal is 0
            return "%.1f".printf(size).replace(".0", "").replace(",0", "").concat(" ", unit);
        }

        private int64[] get_folderdata () {
            // folder properties: count items
            string cmd = "find \"" + this.filepath + "\"";
            string output;
            try {
                GLib.Process.spawn_command_line_sync(cmd, out output);
                string[] all_lines = output.split("\n");
                string[] real_files = all_lines[1:all_lines.length -1];
                int64 totalsize = 0;
                foreach (string l in real_files) {
                    File file = File.new_for_path(l);
                    int64 size = file.query_info ("*", FileQueryInfoFlags.NONE).get_size();
                    totalsize += size;
                }
                int lines = real_files.length;
                return {lines, totalsize};
            } 
            catch (SpawnError e) {
                return {-1, -1};
            }
        }

        private string[] get_filetime () {
            int64 last_edit = (int64) general_info.get_attribute_uint64(FileAttribute.TIME_MODIFIED);
            int64 last_access = (int64) general_info.get_attribute_uint64(FileAttribute.TIME_ACCESS);
            return {
                new DateTime.from_unix_local(last_access).to_string(), 
                new DateTime.from_unix_local(last_edit).to_string()
            };
        }

        private void toggle_executable (Gtk.ToggleButton button) {
            bool ex = button.get_active();
            string cmd = "chmod +x \"" + this.filepath + "\"";
            if (!ex) {cmd = "chmod -x \"" + this.filepath + "\"";}
            try {
                Process.spawn_command_line_async(cmd);
            }
            catch (SpawnError e) {
                // nothing to be done
            }
        }

        private Gtk.Image get_fileicon () {
            // get file icon, fallback to icon name "unknown" on error (which exists!)
            string icon_name = "unknown";
            try {
                string[] icondata = general_info.get_icon ().to_string().split(" ");
                int len_icons = icondata.length;
                icon_name = icondata[len_icons - 1];
                if (len_icons >= 4) {
                    icon_name = icondata[3];
                }
                print ("%s\n", icon_name);
            }
            catch (Error error) {
                print ("Error: %s\n", error.message);
            }
            Gtk.Image fileicon = new Gtk.Image.from_icon_name(icon_name, Gtk.IconSize.DIALOG);
            return fileicon;
        }

        private string get_filetype () {
            string ftype = DesktopFolder.Lang.ITEM_PROPSWINDOW_UNKNOWN;
            try {
                ftype = general_info.get_content_type();
                print ("%s\n", ftype);
            }
            catch (Error error) {
                print ("Error: %s\n", error.message);
            }
            return ftype;
        }
    }

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
            main_stack.add_titled (get_properties_box (), "properties", DesktopFolder.Lang.PANELPROPERTIES_PROPERTIES);
            main_stack.add_titled (get_general_box (), "general", DesktopFolder.Lang.PANELPROPERTIES_GENERAL);

            var version_label = new Gtk.Label ("version " + DesktopFolder.VERSION.up ());
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
            strategy_combo.append ("NONE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_NONE);
            strategy_combo.append ("SCALE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_SCALE);
            strategy_combo.append ("STORE", DesktopFolder.Lang.PANELPROPERTIES_RESOLUTION_STRATEGY_STORE);
            settings.bind ("resolution-strategy", strategy_combo, "active-id", GLib.SettingsBindFlags.DEFAULT);
            general_grid.attach (strategy_combo, 0, 7, 1, 1);

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
