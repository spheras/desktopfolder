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
* Photo Window to show a photo
*/
public class DesktopFolder.PhotoWindow : Gtk.ApplicationWindow{
    /** parent manager of this window */
    private PhotoManager manager=null;
    /** Context menu of the Folder Window */
    private Gtk.Menu menu=null;
    /** the text view */
    private Gtk.TextView text=null;

    static construct {

    }

    construct {
        set_keep_below (true);
        stick ();
        this.hide_titlebar_when_maximized = false;
        set_type_hint(Gdk.WindowTypeHint.MENU);
        set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
    }

    /**
    * @constructor
    * @param FolderManager manager the manager of this window
    */
    public PhotoWindow (PhotoManager manager){
        Object (application: manager.get_application(),
                icon_name: "org.spheras.desktopfolder",
                resizable: true,
                skip_taskbar_hint : true,
                decorated:true,
                title: (manager.get_photo_name()),
                deletable:false,
                width_request: 140,
                height_request: 160
                );

        var headerbar = new Gtk.HeaderBar();
        headerbar.set_title(manager.get_photo_name());
        //headerbar.set_subtitle("HeaderBar Subtitle");
        //headerbar.set_show_close_button(true);
        this.set_titlebar(headerbar);

        this.set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
        //setting the folder name
        this.manager=manager;

        //let's load the settings of the folder (if exist or a new one)
        PhotoSettings settings=this.manager.get_settings();
        if(settings.w>0){
            //applying existing position and size configuration
            this.resize(settings.w,settings.h);
        }
        if(settings.x>0 || settings.y>0){
            this.move(settings.x,settings.y);
        }
        //we set a class to this window to manage the css
        this.get_style_context ().add_class ("df_folder");
        this.get_style_context ().add_class ("df_photo");

        // Box:
        Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        box.get_style_context ().add_class ("df_photo_container");
        box.set_border_width(20);
		this.add (box);

        Gtk.Image photo=new Gtk.Image.from_file (settings.photo_path);
        box.add(photo);

        this.show_all();

        //connecting to events
        this.configure_event.connect (this.on_configure);
    }

    /**
    * @name on_configure
    * @description the configure event is produced when the window change its dimensions or location settings
    */
    private bool on_configure(Gdk.EventConfigure event){
        if(event.type==Gdk.EventType.CONFIGURE){
            //debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            this.manager.set_new_shape(event.x, event.y, event.width, event.height);
        }
        return false;
    }

    /**
    * @name on_press
    * @description press event captured. The Window should show the popup on right button
    * @return bool @see widget on_press signal
    */
    private bool on_press(Gdk.EventButton event){
        //debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button==Gdk.BUTTON_SECONDARY)) {
            this.show_popup(event);
            return true;
        }
        return false;
    }

    /**
    * @name show_popup
    * @description build and show the popup menu
    * @param event EventButton the origin event, needed to position the menu
    */
    private void show_popup(Gdk.EventButton event){
        //debug("evento:%f,%f",event.x,event.y);
        //if(this.menu==null) { //we need the event coordinates for the menu, we need to recreate?!
            this.menu = new Gtk.Menu ();


            Gtk.MenuItem item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //option to delete the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.PHOTO_MENU_DELETE_PHOTO);
            item.activate.connect ((item)=>{this.delete_photo();});
            item.show();
            menu.append (item);


            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //the about option to show a message dialog
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_ABOUT);
            item.activate.connect ((item)=>{
                DesktopFolder.Util.show_about(this);
            });
            item.show();
            menu.append (item);
            menu.show_all();

            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.HINT_SHOW_DESKTOP);
            item.show();
            menu.append (item);
            menu.show_all();

        //}

        //finally we show the popup
        menu.popup(
             null //parent menu shell
            ,null //parent menu item
            ,null //func
            ,event.button // button
            ,event.get_time() //Gtk.get_current_event_time() //time
            );
    }


    /**
    * @name delete_photo
    * @description try to delete the current photo
    */
    private void delete_photo(){
        //we need to ask and be sure
        string message=DesktopFolder.Lang.PHOTO_DELETE_MESSAGE;
        Gtk.MessageDialog msg = new Gtk.MessageDialog (this, Gtk.DialogFlags.MODAL, Gtk.MessageType.WARNING,
                                                       Gtk.ButtonsType.OK_CANCEL, message);
        msg.use_markup=true;
        msg.response.connect ((response_id) => {
            switch (response_id) {
				case Gtk.ResponseType.OK:
                    msg.destroy();
                    this.manager.delete();
					break;
                default:
                    msg.destroy();
                    break;
                    //uff
            }
        });
        msg.show ();
    }


}
