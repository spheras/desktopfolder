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

/**
 * @class
 * Item Settings
 */
public class DesktopFolder.ItemSettings : Object {
    /** the name of the item*/
    public string name { get; set; }
    /** x position */
    public int x { get; set; }
    /** y position */
    public int y { get; set; }
    /** the icon for this file */
    public string icon { get; set; }

    /**
     * @constructor
     */
    public ItemSettings () {
        this.name = "helloWorld.txt";
        this.x    = 5;
        this.x    = 5;
        this.icon = "";
    }

    /**
     * @name to_string
     * @description convert to string the item
     */
    public string to_string () {
        return "%s;%d;%d;%s".printf (this.name, this.x, this.y, this.icon);
    }

    /**
     * @name parse
     * @description parse an string to create an ItemSettings object
     * @param data string the data to be parsed
     * @return ItemSettings the ItemSettings created
     */
    public static ItemSettings parse (string data) {
        ItemSettings result = new ItemSettings ();
        string[]     split  = data.split (";");
        result.name = split[0];
        result.x    = int.parse (split[1]);
        result.y    = int.parse (split[2]);
        if (split.length > 3) {
            result.icon = split[3];
        }
        return result;
    }

}
