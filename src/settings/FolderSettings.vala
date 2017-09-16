public class DesktopFolder.FolderSettings: Object{
    public int x  { get; set; default = 0; }
    public int y  { get; set; default = 0; }
    public int w  { get; set; default = 0; }
    public int h  { get; set; default = 0; }
    public string name { get; set; }
    public string bgcolor { get; set; }
    public string fgcolor { get; set; }
    public string[] items { get; set; default = new string[0]; }
    //default json seralization implementation only support primitive types

    private File file;

    public FolderSettings (string name) {
        this.x=10;
        this.y=10;
        this.bgcolor="black";
        this.fgcolor="light";
        this.name=name;
        this.items=new string[0];
	}

    public void set_item(ItemSettings item){
        //first, we create the list of itemsettings, and replace the old with the new one content
        List<ItemSettings> all=new List<ItemSettings>();
        for(int i=0;i<this.items.length;i++){
            ItemSettings is=ItemSettings.parse(this.items[i]);
            if(is.name==item.name){
                is=item;
            }
            all.append(is);
        }

        //finally, we recreate the string[]
        string[] str_result=new string[all.length()];
        for(int i=0;i<all.length();i++) {
            ItemSettings element=all.nth_data(i);
            var str=element.to_string();
            str_result[i]=str;
        }
        this.items=str_result;
    }

    public void rename(string oldName, string newName){
        //first, we create the list of itemsettings, and replace the old with the new one content
        List<ItemSettings> all=new List<ItemSettings>();
        for(int i=0;i<this.items.length;i++){
            ItemSettings is=ItemSettings.parse(this.items[i]);
            if(is.name==oldName){
                is.name=newName;
            }
            all.append(is);
        }

        //finally, we recreate the string[]
        string[] str_result=new string[all.length()];
        for(int i=0;i<all.length();i++) {
            ItemSettings element=all.nth_data(i);
            var str=element.to_string();
            str_result[i]=str;
        }
        this.items=str_result;
    }

    public void add_item(ItemSettings item){
        int length=this.items.length;
        //i don't know why this can't compile
        //this.items.resize(length+1);
        //this.items[this.items.length-1]=item.to_string();

        //alternative, copying it manually?!! :(
        string[] citems=new string[length+1];
        for(int i=0;i<length;i++){
            citems[i]=this.items[i];
        }
        citems[length]=item.to_string();
        this.items=citems;
    }

    public ItemSettings get_item(string name){
        for(int i=0;i<this.items.length;i++){
            ItemSettings is=ItemSettings.parse(this.items[i]);
            if(is.name==name){
                return is;
            }
        }
        return (ItemSettings) null;
    }

    public void save(){
        this.save_to_file(this.file);
    }

    public void save_to_file(File file){
        this.file=file;
        //string data = Json.gobject_to_data (this, null);
        Json.Node root = Json.gobject_serialize (this);

    	// To string: (see gobject_to_data)
    	Json.Generator generator = new Json.Generator ();
    	generator.set_root (root);
    	string data = generator.to_data (null);

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

    public static FolderSettings read_settings(File file, string name) {
        try{
            string content="";
            var dis = new DataInputStream (file.read());
            string line;
            // Read lines until end of file (null) is reached
            while ((line = dis.read_line (null)) != null) {
                content=content+line;
            }
            FolderSettings existent = Json.gobject_from_data (typeof (FolderSettings), content) as FolderSettings;
            existent.file=file;
            existent.name=name;
            existent.check_all();
            return existent;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            return (FolderSettings) null;
        }
    }

    public void check_all(){
        List<ItemSettings> all=new List<ItemSettings>();
        for(int i=0;i<this.items.length;i++){
            ItemSettings is=ItemSettings.parse(this.items[i]);
            var basePath=Environment.get_home_dir ()+"/Desktop/"+this.name;
            var filepath=basePath+"/"+is.name;
            //debug("checking:"+filepath);
            File f=File.new_for_path (filepath);
            if (f.query_exists ()) {
                    all.append(is);
            }else{
                debug("Alert! doesnt exist: %s",filepath);
                //doesn't exist, we must remove the entry
            }
        }

        //finally, we recreate the string[]
        string[] str_result=new string[all.length()];
        for(int i=0;i<all.length();i++) {
            ItemSettings element=all.nth_data(i);
            var str=element.to_string();
            str_result[i]=str;
        }
        this.items=str_result;

        //and we finally resave it
        this.save();
    }
}
