public class DesktopFolder.PhotoSettings : Object {
    public int    x  { get; set; default = 0; }
    public int    y  { get; set; default = 0; }
    public int    w  { get; set; default = 0; }
    public int    h  { get; set; default = 0; }
    public int    original_width { get; set; default = 0; }
    public int    original_height { get; set; default = 0; }
    public int    fixocolor { get; set; default = 0; }
    public string name { get; set; }
    public string photo_path { get; set; }

    private File file;

    public PhotoSettings (string photo_path) {
        this.x          = 110;
        this.y          = 110;
        this.photo_path = photo_path;
        var file = File.new_for_path (photo_path);
        this.name       = file.get_basename ();
        this.fixocolor  = Random.int_range (1, 6);

        try {
            // we calculate an aproximated image size
            var pixbuf = new Gdk.Pixbuf.from_file (photo_path);
            this.w               = pixbuf.get_width ();
            this.h               = pixbuf.get_height ();
            this.original_width  = w;
            this.original_height = h;

            // max a 30% of the screen
            Gdk.Screen screen = Gdk.Screen.get_default ();
            int        MAX    = (screen.get_width () * 30) / 100;

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
        this.file = file;
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
        if (result == null) {
            // some error occurred, lets delete the settings and create again
            try {
                file.trash ();
            } catch (Error e) {
            }
            PhotoSettings new_settings = new PhotoSettings (name);
            new_settings.save_to_file (file);
            return _read_settings (file, name);
        }

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

            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return null as PhotoSettings;
        }
    }

}
