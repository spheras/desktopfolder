/*
 * Copyright (c) 2017 José Amuedo (https://github.com/spheras)
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
 */

/**
 * @class
 * Desktop Folder Settings
 */
public class DesktopFolder.FolderSettings : PositionSettings {
    public string name { get; set; }
    public string bgcolor { get; set; }
    public string fgcolor { get; set; }
    public bool textbold { get; set; }
    public bool textshadow { get; set; }
    public bool lockitems { get; set; }
    public bool lockpanel { get; set; }
    public bool align_to_grid { get; set; default = false; }
    public string[] items { get; set; default = new string[0]; }
    public int version {get; set;}
    // default json seralization implementation only support primitive types

    private File file;

    /**
     * @Constructor
     * @param string name the name of the folder
     */
    public FolderSettings (string name) {
        this.reset ();
    }

    /**
     * @name reset
     * @description reset the properties
     */
    public void reset () {
        this.x             = 100;
        this.y             = 100;
        this.w             = 300;
        this.h             = 300;
        this.bgcolor       = "df_black";
        this.fgcolor       = "df_light";
        this.textbold      = true;
        this.textshadow    = true;
        this.align_to_grid = false;
        this.lockitems     = false;
        this.lockpanel     = false;
        this.name          = name;
        this.items         = new string[0];
        this.version       = DesktopFolder.SETTINGS_VERSION;
        check_off_screen ();
    }

    /**
     * @name set_item
     * @description replace the current settings for a certain item with other new info
     * @param ItemSettings item the new settings for the item with the same name
     */
    public void set_item (ItemSettings item) {
        // first, we create the list of itemsettings, and replace the old with the new one content
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == item.name) {
                is = item;
            }
            all.append (is);
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;
    }

    /**
     * @name rename
     * @description rename an item on this folder.
     * @param oldName string the old name of the item
     * @param newName string the new name of the item
     */
    public void rename (string oldName, string newName) {
        // first, we create the list of itemsettings, and replace the old with the new one content
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == oldName) {
                is.name = newName;
            }
            all.append (is);
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;
    }

    /**
     * @name add_item
     * @description add an item setting to the list of items of this folder settings
     * @param item ItemSettings the ItemSettings to be added
     */
    public void add_item (ItemSettings item) {
        int length = this.items.length;
        // i don't know why this can't compile
        // this.items.resize(length+1);
        // this.items[this.items.length-1]=item.to_string();

        // alternative, copying it manually?!! :(
        string[] citems = new string[length + 1];
        for (int i = 0; i < length; i++) {
            citems[i] = this.items[i];
        }
        citems[length] = item.to_string ();
        this.items     = citems;
    }

    /**
     * @name get_item
     * @description get an ItemSettings of an existent item inside this folder
     * @param name string the name to find the item
     * @return ItemSettings the ItemSettings found
     */
    public ItemSettings get_item (string name) {
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            if (is.name == name) {
                return is;
            }
        }
        return (ItemSettings) null;
    }

    /**
     * @name save
     * @description persist the changes to the filesystem. The File is the same as the saved initially.
     */
    public void save () {
        this.save_to_file (this.file);
    }

    /**
     * @name save_to_file
     * @description persist the changes to the filesystem. The file used is passed to the function, and saved for following saves.
     * @param file File the file to be saved
     */
    public void save_to_file (File file) {
        this.file = file;

        store_resolution_position ();

        // string data = Json.gobject_to_data (this, null);
        Json.Node root = Json.gobject_serialize (this);

        // To string: (see gobject_to_data)
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        string data              = generator.to_data (null);
        // debug ("the json generated is:\n%s\n", data);
        try {
            // an output file in the current working directory
            if (file.query_exists ()) {
                file.delete ();
            }

            // creating a file and a DataOutputStream to the file
            /*
                Use BufferedOutputStream to increase write speed:
                var dos = new DataOutputStream (new BufferedOutputStream.sized (file.create (FileCreateFlags.REPLACE_DESTINATION), 65536));
             */
            var dos = new DataOutputStream (file.create (FileCreateFlags.REPLACE_DESTINATION));
            // writing a short string to the stream
            dos.put_string (data);

        } catch (Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }

    /**
     * @name read_settings
     * @description read the settings from a file to create a Folder Settings object
     * @param file File the file where the settings are persisted
     * @param name string the name of the folder
     * @return FolderSettings the FolderSettings created
     */
    public static FolderSettings read_settings (File file, string name) {
        FolderSettings result = _read_settings (file, name);
        if (result == null) {
            // some error occurred, lets delete the settings and create again
            try {
                file.trash ();
            } catch (Error e) {
            }
            FolderSettings new_folder_settings = new FolderSettings (name);
            new_folder_settings.save_to_file (file);
            return _read_settings (file, name);
        }
        return result;
    }

    private static FolderSettings _read_settings (File file, string name) {
        try {
            string content = "";
            var    dis     = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                content = content + line;
            }
            FolderSettings existent = Json.gobject_from_data (typeof (FolderSettings), content) as FolderSettings;
            existent.file = file;
            existent.name = name;

            // regression for classes, now must have a df_ prefix
            if (existent.bgcolor.length > 0 && !existent.bgcolor.has_prefix ("df_")) {
                if (!existent.bgcolor.has_prefix ("rgb")) {
                    existent.bgcolor = "df_" + existent.bgcolor;
                }
            }
            if (existent.fgcolor.length > 0 && !existent.fgcolor.has_prefix ("df_")) {
                existent.fgcolor = "df_" + existent.fgcolor;
            }

            // regression for on top and back
            if (existent.version == 0) {
                existent.version = DesktopFolder.SETTINGS_VERSION;
            }

            existent.check_all ();
            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return (FolderSettings) null;
        }
    }

    /**
     * @name check_all
     * @description check if all the items described exists fisically, and fixes problems
     */
    public void check_all () {
        List <ItemSettings> all = new List <ItemSettings> ();
        for (int i = 0; i < this.items.length; i++) {
            ItemSettings is = ItemSettings.parse (this.items[i]);
            var basePath = Environment.get_home_dir () + "/Desktop/" + this.name;
            var filepath = basePath + "/" + is.name;
            // debug("checking:"+filepath);
            File f       = File.new_for_path (filepath);
            if (f.query_exists ()) {
                all.append (is);
            } else {
                debug ("Alert! doesnt exist: %s", filepath);
                // doesn't exist, we must remove the entry
            }
        }

        // finally, we recreate the string[]
        string[] str_result = new string[all.length ()];
        for (int i = 0; i < all.length (); i++) {
            ItemSettings element = all.nth_data (i);
            var          str     = element.to_string ();
            str_result[i] = str;
        }
        this.items = str_result;

        // and we finally resave it
        this.save ();
    }

}
