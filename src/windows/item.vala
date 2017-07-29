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
public class Item : Gtk.Box {

    private string baseFolder;
    private string fileName;
    private File file;

    public Item(string baseFolder, string fileName, File file){
        Object (orientation: Gtk.Orientation.VERTICAL, spacing:2);
        this.set_size_request(48,68);
        this.margin=0;
        this.spacing=0;

        this.baseFolder=baseFolder;
        this.fileName=fileName;
        this.file=file;


            var fileInfo=file.query_info("standard::icon",FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            var icon=new Gtk.Image.from_gicon(fileInfo.get_icon(),Gtk.IconSize.DIALOG);
            icon.set_size_request(48,48);
            icon.get_style_context ().add_class ("df_icon");
            var label=new Gtk.Label (fileName);
            label.set_size_request(48,20);
            label.get_style_context ().add_class ("df_label");

        this.pack_start(icon,true,true);
        this.pack_end(label,true,true);

        debug("packed:"+fileName);
    }

}
