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

    //private const string FIXO_TAGS_COLORS[7] = { null, "#fce94f", "#8ae234", "#729fcf", "#fe44f8", "#FFFFFF", "#000000" };
    private const string FIXO_TAGS_COLORS[9] = { null, "#ffe16b", "#ffa154", "#9bdb4d", "#64baff", "#ad65d6", "#ed5353", "#ffffff", "#000000" };

    //cached shadow photo and fixos
    private Cairo.Surface shadowSurface=null;
    private Cairo.Surface photoSurface=null;
    private Gdk.Pixbuf fixoPixbuf=null;

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
                icon_name: "com.github.spheras.desktopfolder",
                resizable: true,
                skip_taskbar_hint : true,
                decorated:true,
                type_hint:Gdk.WindowTypeHint.DESKTOP,
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
        this.get_style_context ().add_class ("df_transparent");
        this.get_style_context ().add_class ("df_headless");

        // Box:
        Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        box.get_style_context ().add_class ("df_photo_container");
        box.set_border_width(20);
		this.add (box);

        this.show_all();

        //connecting to events
        this.configure_event.connect (this.on_configure);
        this.button_press_event.connect(this.on_press);
        this.button_release_event.connect(this.on_release);
        this.draw.connect(this.draw_background);

        //help: doesn't have the gtk window any active signal? or css :active state?
        Wnck.Screen screen = Wnck.Screen.get_default();
        screen.active_window_changed.connect(on_active_change);
    }

    /**
    * @name on_active_change
    * @description the screen actived window has change signal
    * @param {Wnck.Window} the previous actived window
    */
    private void on_active_change(Wnck.Window? previous){
        string sclass="df_active";
        Gtk.StyleContext style=this.get_style_context();
        if(this.is_active){
            if(!style.has_class(sclass)){
                style.add_class ("df_active");
                //we need to force a queue_draw
                this.queue_draw();
            }
        }else{
            if(style.has_class(sclass)){
                style.remove_class ("df_active");
                this.type_hint=Gdk.WindowTypeHint.DESKTOP;
                //we need to force a queue_draw
                this.queue_draw();
            }
        }
    }


    /**
    * @name on_configure
    * @description the configure event is produced when the window change its dimensions or location settings
    */
    private bool on_configure(Gdk.EventConfigure event){
        if(event.type==Gdk.EventType.CONFIGURE){
            //we are now a dock Window, to avoid minimization when show desktop
            //TODO exists a way to make resizable and moveable a dock window?
            this.type_hint=Gdk.WindowTypeHint.DESKTOP;

            //debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            this.manager.set_new_shape(event.x, event.y, event.width, event.height);

            //reseting cached images
            this.shadowSurface=null;
            this.photoSurface=null;
            this.fixoPixbuf=null;
        }
        return false;
    }

    /**
    * @name on_release
    * @description release event captured.
    * @return bool @see widget on_release signal
    */
    private bool on_release(Gdk.EventButton event){
        //we are now a dock Window, to avoid minimization when show desktop
        //TODO exists a way to make resizable and moveable a dock window?
        this.type_hint=Gdk.WindowTypeHint.DESKTOP;
        return false;
    }

    /**
    * @name on_press
    * @description press event captured. The Window should show the popup on right button
    * @return bool @see widget on_press signal
    */
    private bool on_press(Gdk.EventButton event){
        //we are now a normal Window, to allow resizing and movement
        //TODO exists a way to make resizable and moveable a dock window?
        this.type_hint=Gdk.WindowTypeHint.NORMAL;

        //debug("press:%i,%i",(int)event.button,(int)event.y);
        if (event.type == Gdk.EventType.BUTTON_PRESS &&
            (event.button==Gdk.BUTTON_SECONDARY)) {
            this.show_popup(event);
            return true;
        }else if (event.type == Gdk.EventType.BUTTON_PRESS &&
                 (event.button==Gdk.BUTTON_PRIMARY)) {
            int width = this.get_allocated_width ();
            int height = this.get_allocated_height ();
            int margin=30;
            //debug("x:%d,y:%d,width:%d,height:%d",(int)event.x,(int) event.y,width,height);
            if(event.x>margin && event.y>margin && event.x<width-margin && event.y<height-margin){
                this.begin_move_drag((int)event.button,(int) event.x_root,(int) event.y_root, event.time);
            }
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

            //Forcing Dock mode to avoid minimization in certain extremely cases without on_press signal!
            //TODO exists a way to make resizable and moveable a dock window?
            this.type_hint=Gdk.WindowTypeHint.DESKTOP;

            this.menu = new Gtk.Menu ();

            // new submenu
            Gtk.MenuItem item_new = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_SUBMENU);
            item_new.show();
            menu.append (item_new);

            Gtk.Menu newmenu = new Gtk.Menu ();
            item_new.set_submenu (newmenu);

            //menu to create a new folder
            Gtk.MenuItem item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER);
            item.activate.connect ((item)=>{
                    this.new_desktop_folder();
            });
            item.show();
            newmenu.append (item);

            //menu to create a new note
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_NOTE);
            item.activate.connect ((item)=>{
                    this.new_note();
            });
            item.show();
            newmenu.append (item);

            //menu to create a new photo
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.DESKTOPFOLDER_MENU_NEW_PHOTO);
            item.activate.connect ((item)=>{
                    this.new_photo();
            });
            item.show();
            newmenu.append (item);

            item = new MenuItemSeparator();
            item.show ();
            menu.append (item);

            //option to delete the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.PHOTO_MENU_DELETE_PHOTO);
            item.activate.connect ((item)=>{this.manager.delete();});
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            item = new MenuItemColor(FIXO_TAGS_COLORS);
            ((MenuItemColor)item).color_changed.connect(change_fixo_color);
            item.show();
            menu.append (item);

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
    * @name change_fixo_color
    * @description change event captured from the popup for a new color to the fixo color
    * @param ncolor int the new color for the fixo
    */
    private void change_fixo_color(int ncolor){
        this.manager.get_settings().fixocolor=ncolor;
        //reseting fixo images
        this.fixoPixbuf=null;
        this.queue_draw();
    }

    /**
    * @name new_desktop_folder
    * @description show a dialog to create a new desktop folder
    */
    private void new_desktop_folder(){
        DesktopFolder.Util.create_new_desktop_folder(this);
    }

    /**
    * @name new_note
    * @description show a dialog to create a new note
    */
    private void new_note(){
        DesktopFolder.Util.create_new_note(this);
    }

    /**
    * @name new_photo
    * @description show a dialog to create a new photo
    */
    private void new_photo(){
        DesktopFolder.Util.create_new_photo(this);
    }

    /**
    * @name draw_backgorund
    * @description draw the note window background intercepting the draw signal
    * @param {Cairo.Context} cr the cairo context
    * @bool @see draw signal
    */
    private bool draw_background (Cairo.Context cr) {
        int width = this.get_allocated_width ();
        int height = this.get_allocated_height ();

        cr.set_operator (Cairo.Operator.CLEAR);
        cr.paint ();
        cr.set_operator (Cairo.Operator.OVER);

        try{
            //the image dimenssions
            int pixwidth=width-50;
            int pixheight=height-50;

            //drawing the shadow
            if(this.manager.get_settings().fixocolor==0){
                if(this.shadowSurface==null){
                    var shadowPixbuf=new Gdk.Pixbuf.from_resource("/com/github/spheras/desktopfolder/shadow.png");
                    shadowPixbuf=shadowPixbuf.scale_simple(pixwidth,40,Gdk.InterpType.BILINEAR);
                    this.shadowSurface=Gdk.cairo_surface_create_from_pixbuf(shadowPixbuf, 0, null);
                }
                cr.set_source_surface (this.shadowSurface, width/2 - pixwidth/2,height/2 - pixheight/2 + pixheight-2);
                cr.paint();
            }

            //the photo
            if(photoSurface==null){
                var photopath=this.manager.get_settings().photo_path;
                var photoPixbuf=new Gdk.Pixbuf.from_file(photopath);
                photoPixbuf=photoPixbuf.scale_simple(pixwidth,pixheight,Gdk.InterpType.BILINEAR);
                this.photoSurface=Gdk.cairo_surface_create_from_pixbuf(photoPixbuf, 0, null);
                //DesktopFolder.Util.blur_image_surface((Cairo.ImageSurface)this.photoSurface,4);
            }
            cr.set_source_surface (this.photoSurface, width/2 - pixwidth/2, height/2 - pixheight/2);
            cr.paint();

            //lets draw the fixo
            int fixoWidth=56;
            int fixoHeight=56;
            int fixoMargin=4;
            int fixocolor=this.manager.get_settings().fixocolor;
            var color="";
            switch(fixocolor){
                case 0:
                    color= null;
                    break;
                case 1:
                    color= "banana";
                    break;
                case 2:
                    color= "orange";
                    break;
                case 3:
                    color= "lime";
                    break;
                case 4:
                    color= "blueberry";
                    break;
                case 5:
                    color= "grape";
                    break;
                case 6:
                    color= "strawberry";
                    break;
                case 7:
                    color= "white";
                    break;
                default:
                case 8:
                    color= "black";
                    break;
            }
            if(color!=null){
                if(this.fixoPixbuf==null){
                    this.fixoPixbuf=new Gdk.Pixbuf.from_resource("/com/github/spheras/desktopfolder/fixo-"+color+".svg");
                    //this.fixoPixbuf=fixoPixbuf.scale_simple(100,100,Gdk.InterpType.BILINEAR);
                }
                var fixoSurface=Gdk.cairo_surface_create_from_pixbuf(this.fixoPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, fixoMargin, fixoMargin);
                cr.paint();

                var rotatedPixbuf=this.fixoPixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface=Gdk.cairo_surface_create_from_pixbuf(rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, width-fixoWidth - fixoMargin, fixoMargin);
                cr.paint();

                rotatedPixbuf=rotatedPixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface=Gdk.cairo_surface_create_from_pixbuf(rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, width-fixoWidth - fixoMargin, height-fixoHeight - fixoMargin);
                cr.paint();

                rotatedPixbuf=rotatedPixbuf.rotate_simple(Gdk.PixbufRotation.COUNTERCLOCKWISE);
                fixoSurface=Gdk.cairo_surface_create_from_pixbuf(rotatedPixbuf, 0, null);
                cr.set_source_surface (fixoSurface, fixoMargin, height-fixoHeight - fixoMargin);
                cr.paint();
            }

        } catch (Error e) {
            //error! ??
            stderr.printf ("Error: %s\n", e.message);
        }

        return true;
    }

}
