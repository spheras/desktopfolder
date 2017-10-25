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
* Folder Window that is shown above the desktop to manage files and folders
*/
public class DesktopFolder.NoteWindow : Gtk.ApplicationWindow{
    /** parent manager of this window */
    private NoteManager manager=null;
    /** Context menu of the Folder Window */
    private Gtk.Menu menu=null;
    /** the text view */
    private Gtk.SourceView text=null;
    /** the texture pattern for the note */
    private Cairo.Pattern texture_pattern=null;
    /** the clip image prepared to be rendered */
    private Cairo.Surface clip_surface=null;

    /** head tags colors */
    private const string HEAD_TAGS_COLORS[3] = { null, "#ffffff", "#000000"};
    private const string HEAD_TAGS_COLORS_CLASS[3] = { "df_headless", "df_light", "df_dark"};
    /** body tags colors */
    private const string BODY_TAGS_COLORS[10] = { null, "#ffe16b", "#ffa154", "#795548", "#9bdb4d", "#64baff", "#ad65d6", "#ed5353", "#d4d4d4", "#000000" };
    private const string BODY_TAGS_COLORS_CLASS[10] = { "df_transparent", "df_yellow", "df_orange", "df_brown", "df_green", "df_blue", "df_purple", "df_red", "df_gray", "df_black" };

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
    public NoteWindow (NoteManager manager){
        Object (application: manager.get_application(),
                icon_name: "com.github.spheras.desktopfolder",
                resizable: true,
                skip_taskbar_hint : true,
                type_hint:Gdk.WindowTypeHint.DESKTOP,
                decorated:true,
                title: (manager.get_note_name()),
                deletable:false,
                width_request: 140,
                height_request: 160
                );

        var headerbar = new Gtk.HeaderBar();
        headerbar.set_title(manager.get_note_name());
        //headerbar.set_subtitle("HeaderBar Subtitle");
        //headerbar.set_show_close_button(true);
        this.set_titlebar(headerbar);

        this.set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
        //setting the folder name
        this.manager=manager;

        //let's load the settings of the folder (if exist or a new one)
        NoteSettings settings=this.manager.get_settings();
        if(settings.w>0){
            //applying existing position and size configuration
            this.resize(settings.w,settings.h);
        }
        if(settings.x>0 || settings.y>0){
            this.move(settings.x,settings.y);
        }
        //we set a class to this window to manage the css
        this.get_style_context ().add_class ("df_folder");
        this.get_style_context ().add_class ("df_note");
        this.get_style_context ().add_class ("df_shadow");
        //applying existing colors configuration
        this.get_style_context ().add_class (settings.bgcolor);
        this.get_style_context ().add_class (settings.fgcolor);

        // Box:
		Gtk.Box box = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        box.get_style_context ().add_class ("df_note_container");
        box.set_border_width(20);
		this.add (box);

        // A ScrolledWindow:
		Gtk.ScrolledWindow scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.get_style_context ().add_class ("df_note_scroll");
		box.pack_start (scrolled, true, true, 0);

        // The TextView:
	    this.text = new Gtk.SourceView(); //Gtk.TextView ();
		this.text.set_wrap_mode (Gtk.WrapMode.WORD);
        this.text.get_style_context ().add_class ("df_note_text");
		this.text.buffer.text = this.manager.get_settings().text;
		scrolled.add (this.text);

        this.show_all();

        //connecting to events
        this.configure_event.connect (this.on_configure);
        this.button_press_event.connect(this.on_press);
        this.button_release_event.connect(this.on_release);
        this.draw.connect(this.draw_background);

        text.focus_out_event.connect(this.on_focus_out);
        //this.key_release_event.connect(this.on_key);

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
                //debug("active");
                style.add_class ("df_active");
                //we need to force a queue_draw
                this.queue_draw();
                this.text.queue_draw();
            }
        }else{
            if(style.has_class(sclass)){
                //debug("inactive");
                style.remove_class ("df_active");
                this.type_hint=Gdk.WindowTypeHint.DESKTOP;
                //we need to force a queue_draw
                this.queue_draw();
                this.text.queue_draw();
            }
        }
    }

    /**
    * @name on_focus_out
    * @description focus out event
    * @param {Gdk.EventFocus} event the event launched
    * @return bool @see focus_out_event signal
    */
    private bool on_focus_out (Gdk.EventFocus event){
        //we are now a dock Window, to avoid minimization when show desktop
        //TODO exists a way to make resizable and moveable a dock window?
        this.type_hint=Gdk.WindowTypeHint.DESKTOP;

        var buffer=this.text.get_buffer();
        var text=buffer.text;
        var saved_text=this.manager.get_settings().text;
        if(text!=saved_text){
            this.manager.on_text_change(text);
        }
        return false;
    }

    /**
    * @name on_configure
    * @description the configure event is produced when the window change its dimensions or location settings
    */
    private bool on_configure(Gdk.EventConfigure event){
        if(event.type==Gdk.EventType.CONFIGURE){
            //we are now a dock Window, to avoid minimization when show desktop
            //TODO exists a way to make resizable and moveable a dock window?
            //this.type_hint=Gdk.WindowTypeHint.DESKTOP;

            //debug("configure event:%i,%i,%i,%i",event.x,event.y,event.width,event.height);
            this.manager.set_new_shape(event.x, event.y, event.width, event.height);
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

            item = new Gtk.CheckMenuItem.with_label(DesktopFolder.Lang.NOTE_MENU_PAPER_NOTE);
            (item as Gtk.CheckMenuItem).set_active (this.manager.get_settings().texture=="square_paper");
            (item as Gtk.CheckMenuItem).toggled.connect ((item)=>{
                this.on_texture("square_paper");
            });
            item.show();
            menu.append (item);


            item = new MenuItemSeparator();
            item.show ();
            menu.append (item);

            //option to delete the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_DELETE_NOTE);
            item.activate.connect ((item)=>{this.manager.delete();});
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show ();
            menu.append (item);

            //Option to rename the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_RENAME_NOTE);
            item.activate.connect ((item)=>{this.rename_note();});
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //section to change the window head and body colors
            item = new MenuItemColor(HEAD_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_head_color);
            item.show();
            menu.append (item);
            item = new MenuItemColor(BODY_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_body_color);
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
    * @name on_texture
    * @description set the texture for the note window
    * @param {string} texture the texture to apply
    */
    private void on_texture(string texture){
        string current_texture=this.manager.get_settings().texture;
        if(current_texture==texture){
            this.manager.get_settings().texture="";
        }else{
            this.manager.get_settings().texture=texture;
        }
        this.manager.get_settings().save();
        this.queue_draw();
    }

    /**
    * @name new_photo
    * @description show a dialog to create a new photo
    */
    private void new_photo(){
        DesktopFolder.Util.create_new_photo(this);
    }

    /**
    * @name new_note
    * @description show a dialog to create a new desktop folder
    */
    private void new_note(){
        DesktopFolder.Util.create_new_note(this);
    }

    /**
    * @name new_desktop_folder
    * @description show a dialog to create a new desktop folder
    */
    private void new_desktop_folder(){
        DesktopFolder.Util.create_new_desktop_folder(this);
    }

    /**
    * @name change_head_color
    * @description change event captured from the popup for a new color to the head window
    * @param ncolor int the new color for the head window
    */
    private void change_head_color(int ncolor){
        string color=HEAD_TAGS_COLORS_CLASS[ncolor];
        for(int i=0;i<HEAD_TAGS_COLORS_CLASS.length;i++){
            string scolor=HEAD_TAGS_COLORS_CLASS[i];
            this.get_style_context().remove_class (scolor);
        }
        this.get_style_context ().add_class (color);
        this.manager.save_head_color(color);
    }

    /**
    * @name rename_note
    * @description try to rename the current note
    */
    private void rename_note(){
        RenameDialog dialog = new RenameDialog (this,
                                                DesktopFolder.Lang.NOTE_RENAME_TITLE,
                                                DesktopFolder.Lang.NOTE_RENAME_MESSAGE,
                                                this.manager.get_note_name());
        dialog.on_rename.connect((new_name)=>{
            if(this.manager.rename(new_name)){
                this.set_title(new_name);
            }
        });
        dialog.show_all ();
    }

    /**
    * @name change_body_color
    * @description change event captured from the popup for a new color to the body window
    * @param ncolor int the new color for the body window
    */
    private void change_body_color(int ncolor){
        string color=BODY_TAGS_COLORS_CLASS[ncolor];
        for(int i=0;i<BODY_TAGS_COLORS_CLASS.length;i++){
            string scolor=BODY_TAGS_COLORS_CLASS[i];
            this.get_style_context().remove_class (scolor);
        }

        this.get_style_context().add_class (color);
        this.manager.save_body_color(color);
        //debug("color:%d,%s",ncolor,color);
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

        /*
        var background_style = this.get_style_context ();
        background_style.render_background (cr, 0, 0, width, height);
        background_style.render_frame (cr, 0, 0, width, height);
        */

        //shaping
        shape(cr,width,height);
        cr.clip ();

        if(this.manager.get_settings().texture=="square_paper"){
            try{
                if(this.texture_pattern==null){
                    var pixbuf=new Gdk.Pixbuf.from_resource("/com/github/spheras/desktopfolder/hip-square.png");
                    var surface=Gdk.cairo_surface_create_from_pixbuf(pixbuf,1,null);
                    this.texture_pattern = new Cairo.Pattern.for_surface (surface);
                    this.texture_pattern.set_extend (Cairo.Extend.REPEAT);
                }

                cr.set_source (this.texture_pattern);
                cr.paint_with_alpha (0.9);
            } catch (Error e) {
                //error! ??
                stderr.printf ("Error: %s\n", e.message);
            }
        }

        //drawing border
        shape(cr,width,height);
        cr.set_line_width (3.0);
        cr.set_source_rgba (0, 0, 0, 0.2);
        cr.stroke();

        //drawing corner
        draw_corner(cr,width,height);
        cr.set_source_rgba (0, 0, 0, 0.4);
        cr.stroke();

        base.draw (cr);

        cr.reset_clip();

        //drawing clip
        try{
            if(this.clip_surface==null){
                int clipcolor=this.manager.get_settings().clipcolor;
                var color="";
                switch(clipcolor){
                    case 1:
                        color= "blue";
                        break;
                    case 2:
                        color= "green";
                        break;
                    case 3:
                        color= "orange";
                        break;
                    case 4:
                        color= "pink";
                        break;
                    case 5:
                        color= "red";
                        break;
                    default:
                    case 6:
                        color= "yellow";
                        break;
                }
                var pixbuf=new Gdk.Pixbuf.from_resource("/com/github/spheras/desktopfolder/clip-"+color+".png");
                this.clip_surface=Gdk.cairo_surface_create_from_pixbuf(pixbuf, 1, null);
            }
            cr.set_source_surface (this.clip_surface, 5, 5);
            cr.paint();
        } catch (Error e) {
            //error! ??
            stderr.printf ("Error: %s\n", e.message);
        }

        return true;
    }

    private void draw_corner(Cairo.Context cr, double width, double height){
        int margin=15;
        int rightRadius=25;
        cr.move_to(width-margin-rightRadius,margin);
        cr.line_to(width-margin-rightRadius,margin+rightRadius);
        cr.line_to(width-margin,margin+rightRadius);
    }

    /**
    * @name shape
    * @description shape the window with the shape of a note
    * @param {Cairo.Context} cr the context to draw
    * @param double width the width of the window
    * @param double height the height of the window
    */
    private void shape (Cairo.Context cr, double width, double height) {
        int margin=15;
        int radius=2;
        int rightRadius=25;

        cr.move_to (margin,margin+radius);

        //  /
        cr.line_to (margin+radius,margin);
        // -
        cr.line_to (width-margin-rightRadius, margin);
        // \
        cr.line_to (width-margin, margin+rightRadius);
        // |
        cr.line_to (width-margin,height-margin-radius);
        // /
        cr.line_to (width-margin-radius,height-margin);
        // -
        cr.line_to (margin+radius,height-margin);
        // \
        cr.line_to (margin,height-margin-radius);
        // |
        cr.line_to(margin,margin+radius);
        cr.close_path ();
    }
}
