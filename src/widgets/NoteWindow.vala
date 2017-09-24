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
    /** container of widgets */
    private Gtk.Fixed container=null;
    /** Context menu of the Folder Window */
    private Gtk.Menu menu=null;

    /** head tags colors */
    private const string HEAD_TAGS_COLORS[3] = { null, "#ffffff", "#000000"};
    private const string HEAD_TAGS_COLORS_CLASS[3] = { "headless", "light", "dark"};
    /** body tags colors */
    private const string BODY_TAGS_COLORS[10] = { null, "#fce94f", "#fcaf3e", "#997666", "#8ae234", "#729fcf", "#ad7fa8", "#ef2929", "#d3d7cf", "#000000" };
    private const string BODY_TAGS_COLORS_CLASS[10] = { "transparent", "yellow", "orange", "brown", "green", "blue", "purple", "red", "gray", "black" };

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
                icon_name: "org.spheras.desktopfolder",
                resizable: true,
                skip_taskbar_hint : true,
                decorated:true,
                title: (manager.get_note_name()),
                deletable:false,
                height_request: 300,
                width_request: 200);

        this.set_skip_taskbar_hint(true);
        this.set_property("skip-taskbar-hint", true);
        //setting the folder name
        this.manager=manager;

        //let's load the settings of the folder (if exist or a new one)
        NoteSettings settings=this.manager.get_settings();
        //we set a class to this window to manage the css
        this.get_style_context ().add_class ("df_folder");
        this.get_style_context ().add_class ("df_note");
        //applying existing colors configuration
        this.get_style_context ().add_class (settings.bgcolor);
        this.get_style_context ().add_class (settings.fgcolor);

        //creating the container widget
        this.container=new Gtk.Fixed();
        add(this.container);

        //connecting to events
        //this.configure_event.connect (this.on_configure);
        this.button_press_event.connect(this.on_press);
        this.draw.connect(this.draw_background);
        //this.key_release_event.connect(this.on_key);
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

            //section to change the window head and body colors
            Gtk.MenuItem item = new MenuItemColor(HEAD_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_head_color);
            item.show();
            menu.append (item);
            item = new MenuItemColor(BODY_TAGS_COLORS);;
            ((MenuItemColor)item).color_changed.connect(change_body_color);
            item.show();
            menu.append (item);

            item = new MenuItemSeparator();
            item.show();
            menu.append (item);

            //Option to rename the current folder
            item = new Gtk.MenuItem.with_label (DesktopFolder.Lang.NOTE_MENU_RENAME_NOTE);
            item.activate.connect ((item)=>{this.rename_note();});
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

        var pixbuf=new Gdk.Pixbuf.from_resource("/org/spheras/desktopfolder/hip-square.png");
        var surface=Gdk.cairo_surface_create_from_pixbuf(pixbuf,1,null);
        var pat = new Cairo.Pattern.for_surface (surface);
        pat.set_extend (Cairo.Extend.REPEAT);
        cr.set_source (pat);
        cr.paint_with_alpha (0.9);

        //drawing border
        shape(cr,width,height);
        cr.set_line_width (3.0);
        cr.set_source_rgba (0, 0, 0, 1);
        cr.stroke();


        base.draw (cr);

        cr.reset_clip();

        //drawing clip
        pixbuf=new Gdk.Pixbuf.from_resource("/org/spheras/desktopfolder/clip.png");
        var clip=Gdk.cairo_surface_create_from_pixbuf(pixbuf, 1, null);
        cr.set_source_surface (clip, 5, 5);
        cr.paint();

        return true;
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
