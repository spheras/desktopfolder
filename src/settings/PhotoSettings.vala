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

public class DesktopFolder.PhotoSettings : PositionSettings {
    private int _original_width = 0;
    public int original_width {
        get {
            return _original_width;
        }
        set {
            if (_original_width != value) {
                _original_width = value; flagChanged = true;
            }
        }
    }
    private int _original_height = 0;
    public int original_height {
        get {
            return _original_height;
        }
        set {
            if (_original_height != value) {
                _original_height = value; flagChanged = true;
            }
        }
    }
    private int _fixocolor = 0;
    public int fixocolor {
        get {
            return _fixocolor;
        }
        set {
            if (_fixocolor != value) {
                _fixocolor = value; flagChanged = true;
            }
        }
    }
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
    private string _photo_path;
    public string photo_path {
        get {
            return _photo_path;
        }
        set {
            if (_photo_path != value) {
                _photo_path = value; flagChanged = true;
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

    private File file;

    public PhotoSettings (string photo_path, Gdk.Window window) {
        this.x          = 110;
        this.y          = 110;
        this.photo_path = photo_path;
        var file = File.new_for_path (photo_path);
        this.name       = file.get_basename ();
        this.fixocolor  = Random.int_range (1, 6);
        this.version    = DesktopFolder.SETTINGS_VERSION;

        try {
            // we calculate an aproximated image size
            var pixbuf = new Gdk.Pixbuf.from_file (photo_path);
            this.w               = pixbuf.get_width ();
            this.h               = pixbuf.get_height ();
            this.original_width  = w;
            this.original_height = h;

            // max a 30% of the screen
            Gdk.Screen screen = Gdk.Screen.get_default ();
            int        MAX    = (screen.get_display ().get_monitor_at_window (window).get_geometry ().width * 30) / 100;

            if (this.w > MAX) {
                int newWidth  = MAX;
                int newHeight = (this.h * newWidth) / this.w;
                this.w = newWidth;
                this.h = newHeight;
            } else if (this.h > MAX) {
                int newHeight = MAX;
                int newWidth  = (this.w * newHeight) / this.h;
                this.w = newWidth;
                this.h = newHeight;
            }
        } catch (Error e) {
            // error! ??
            stderr.printf ("Error: %s\n", e.message);
        }
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
     * @description read the settings from a file to create a Photo Settings object
     * @param file File the file where the settings are persisted
     * @param name string the name of the photo
     * @return PhotoSettings the PhotoSettings created
     */
    public static PhotoSettings read_settings (File file, string name) {
        PhotoSettings result = _read_settings (file, name);
        if (result != null) {
            // now lets check the existence of the photo linked and if it is valid
            var photo_file = File.new_for_path (result.photo_path);
            if (photo_file.query_exists ()) {
                try {
                    new Gdk.Pixbuf.from_file (result.photo_path);
                } catch (Error error) {
                    return null as PhotoSettings;
                }
            } else {
                return null as PhotoSettings;
            }
        }
        return result;
    }

    public static PhotoSettings _read_settings (File file, string name) {
        try {
            string content = "";
            var    dis     = new DataInputStream (file.read ());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                content = content + line;
            }
            PhotoSettings existent = Json.gobject_from_data (typeof (PhotoSettings), content) as PhotoSettings;
            existent.file = file;
            existent.name = name;

            // old versions don't calculate the original width/height
            if (existent.original_width <= 0 || existent.original_height <= 0) {
                // we calculate an aproximated image size
                var pixbuf = new Gdk.Pixbuf.from_file (existent.photo_path);
                existent.original_width  = pixbuf.get_width ();
                existent.original_height = pixbuf.get_height ();
            }

            // regression for on top and back
            if (existent.version == 0) {
                existent.version = DesktopFolder.SETTINGS_VERSION;
            }

            // the properties have not changed, just loaded
            existent.flagChanged = false;

            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return null as PhotoSettings;
        }
    }

}
