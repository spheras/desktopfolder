public class DesktopFolder.NoteSettings : Object {
    public int x  { get;set;default = 0; }
    public int y  { get;set;default = 0; }
    public int w  { get;set;default = 0; }
    public int h  { get;set;default = 0; }
    public string name { get;set; }
    public string bgcolor { get;set; }
    public string fgcolor { get;set; }
    public int clipcolor { get;set; }
    public string texture { get;set; }
    public string text { get;set; }

    private File file;

    public NoteSettings (string name) {
        this.x         = 110;
        this.y         = 110;
        this.w         = 350;
        this.h         = 400;
        this.bgcolor   = "df_yellow";
        this.fgcolor   = "df_dark";
        this.texture   = "";
        this.clipcolor = Random.int_range (1, 6);
        this.name      = name;
        this.text      = "";
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
     * @description read the settings from a file to create a Note Settings object
     * @param file File the file where the settings are persisted
     * @param name string the name of the note
     * @return NoteSettings the NoteSettings created
     */
    public static NoteSettings read_settings (File file, string name) {
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
                // backward compability
                existent.bgcolor = "df_" + existent.bgcolor;
                existent.texture = "square_paper";
            }
            if (existent.fgcolor.length > 0 && !existent.fgcolor.has_prefix ("df_")) {
                // backward compability
                existent.fgcolor = "df_" + existent.fgcolor;
                existent.texture = "square_paper";
            }

            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return null as NoteSettings;
        }
    }

}
