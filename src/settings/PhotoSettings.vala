public class DesktopFolder.PhotoSettings : Object {
    public int x  { get;set;default = 0; }
    public int y  { get;set;default = 0; }
    public int w  { get;set;default = 0; }
    public int h  { get;set;default = 0; }
    public int fixocolor { get;set;default = 0; }
    public string name { get;set; }
    public string photo_path { get;set; }

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
            this.w = pixbuf.get_width ();
            // max a 30% of the screen
            Gdk.Screen screen = Gdk.Screen.get_default ();
            int        MAX    = (screen.get_width () * 30) / 100;

            this.h = pixbuf.get_height ();
            if (this.w > MAX) {
                int diff = this.w - MAX;
                this.w = MAX;
                this.h = this.h - diff;
            } else if (this.h > MAX)    {
                int diff = this.h - MAX;
                this.h = MAX;
                this.w = this.w - diff;
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
            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return null as PhotoSettings;
        }
    }

}
