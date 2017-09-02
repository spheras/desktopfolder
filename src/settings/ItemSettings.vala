public class DesktopFolder.ItemSettings: Object{
    public string name {get; set;}
    public int x { get; set; }
    public int y { get; set; }

    public ItemSettings () {
        this.name="helloWorld.txt";
        this.x=5;
        this.x=5;
	}

    public string to_string(){
        return this.name + ";%d;%d".printf(this.x ,this.y);
    }

    public static ItemSettings parse(string data){
        ItemSettings result=new ItemSettings();
        string[] split=data.split(";");
        result.name=split[0];
        result.x=int.parse(split[1]);
        result.y=int.parse(split[2]);
        return result;
    }
}
