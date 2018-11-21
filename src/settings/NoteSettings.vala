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

public class DesktopFolder.NoteSettings : PositionSettings {
    private string _name;
    public string name {
        get {
            return _name;
        }
        set {
            if (_name != value) {
                _name = value; flagChanged = true;
            }
        }
    }
    private string _bgcolor;
    public string bgcolor {
        get {
            return _bgcolor;
        }
        set {
            if (_bgcolor != value) {
                _bgcolor = value; flagChanged = true;
            }
        }
    }

    private string _fgcolor;
    public string fgcolor {
        get {
            return _fgcolor;
        }
        set {
            if (_fgcolor != value) {
                _fgcolor = value; flagChanged = true;
            }
        }
    }
    private int _clipcolor;
    public int clipcolor {
        get {
            return _clipcolor;
        }
        set {
            if (_clipcolor != value) {
                _clipcolor = value; flagChanged = true;
            }
        }
    }
    private string _texture;
    public string texture {
        get {
            return _texture;
        }
        set {
            if (_texture != value) {
                _texture = value; flagChanged = true;
            }
        }
    }
    private string _text;
    public string text {
        get {
            return _text;
        }
        set {
            if (_text != value) {
                _text = value; flagChanged = true;
            }
        }
    }
    private bool _on_top;
    public bool on_top {
        get {
            return _on_top;
        }
        set {
            if (_on_top != value) {
                _on_top = value; flagChanged = true;
            }
        }
    }
    private bool _on_back;
    public bool on_back {
        get {
            return _on_back;
        }
        set {
            if (_on_back != value) {
                _on_back = value; flagChanged = true;
            }
        }
    }

    // util value to know the settings versions
    private int _version;
    public int version {
        get {
            return _version;
        }
        set {
            if (_version != value) {
                _version = value; flagChanged = true;
            }
        }
    }

    private bool _edit_label_on_creation;
    public bool edit_label_on_creation {
        get {
            return _edit_label_on_creation;
        }
        set {
            if (_edit_label_on_creation != value) {
                _edit_label_on_creation = value; flagChanged = true;
            }
        }
    }

    private File file;

    public NoteSettings (string name) {
        this.x         = 110;
        this.y         = 110;
        this.w         = 300;
        this.h         = 300;
        this.bgcolor   = "df_yellow";
        this.fgcolor   = "df_dark";
        this.texture   = "";
        this.clipcolor = Random.int_range (1, 6);
        this.name      = name;
        this.text      = "Lorem Ipsum";
        this.on_top    = false;
        this.on_back   = true;
        this.version   = DesktopFolder.SETTINGS_VERSION;
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
        if (!flagChanged) {
            return;
        }

        flagChanged = false;
        this.file   = file;

        store_resolution_position ();

        // string data = Json.gobject_to_data (this, null);
        Json.Node root = Json.gobject_serialize (this);

        // To string: (see gobject_to_data)
        Json.Generator generator = new Json.Generator ();
        generator.set_root (root);
        string data              = generator.to_data (null);

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
     * @description read the settings from a file to create a Note Settings object
     * @param file File the file where the settings are persisted
     * @param name string the name of the note
     * @return NoteSettings the NoteSettings created
     */
    public static NoteSettings read_settings (File file, string name) {
        NoteSettings result = _read_settings (file, name);
        if (result == null) {
            // some error occurred, lets delete the settings and create again
            try {
                file.trash ();
            } catch (Error e) {
            }
            NoteSettings new_settings = new NoteSettings (name);
            new_settings.save_to_file (file);
            return _read_settings (file, name);
        }
        return result;
    }

    public static NoteSettings _read_settings (File file, string name) {
        try {
            string content = "";
            var    dis     = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                content = content + line;
            }
            NoteSettings existent = Json.gobject_from_data (typeof (NoteSettings), content) as NoteSettings;
            existent.file = file;
            existent.name = name;

            // regression for classes, now must have a df_ prefix
            if (existent.bgcolor.length > 0 && !existent.bgcolor.has_prefix ("df_")) {
                if (!existent.bgcolor.has_prefix ("rgb")) {
                    existent.bgcolor = "df_" + existent.bgcolor;
                    existent.texture = "square_paper";
                }
            }
            if (existent.fgcolor.length > 0 && !existent.fgcolor.has_prefix ("df_")) {
                // backward compability
                existent.fgcolor = "df_" + existent.fgcolor;
                existent.texture = "square_paper";
            }

            // regression for on top and back
            if (existent.version == 0) {
                existent.version = DesktopFolder.SETTINGS_VERSION;
                existent.on_top  = false;
                existent.on_back = true;
            }

            // the properties have not changed, just loaded
            existent.flagChanged = false;

            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return null as NoteSettings;
        }
    }

}
