/*  This code was partially imported from GNOME: https://github.com/GNOME/ease/blob/master/ease-core/ease-utilities.vala

    Ease, a GTK presentation application
    Copyright (C) 2010 Nate Stedman

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace DesktopFolder.Util
{

	/**
    * @name show_about
    * @description show the about dialog
    */
    private void show_about(Gtk.Window parent){
        // Configure the dialog:
    	Gtk.AboutDialog dialog = new Gtk.AboutDialog ();
    	dialog.set_destroy_with_parent (true);
    	dialog.set_transient_for (parent);
    	dialog.set_modal (true);

    	dialog.authors = {"José Amuedo - spheras - Just for learning", "José Ignacio Centeno - Arrow Keys selection"};
        /*
        dialog.artists = {"Darkwing Duck", "Launchpad McQuack"};
    	dialog.documenters = null; // Real inventors don't document.
    	dialog.translator_credits = null; // We only need a scottish version.
        */
    	dialog.program_name = "Desktop-Folder";
    	dialog.comments = DesktopFolder.Lang.APP_DESCRIPTION;
    	dialog.copyright = "GNU General Public License v3.0";
    	dialog.version = "1.0";

        string license="This program is free software: you can redistribute it and/or modify " +
        "it under the terms of the GNU General Public License as published by "+
        "the Free Software Foundation, either version 3 of the License, or "+
        "(at your option) any later version.\n\n"+
        "This program is distributed in the hope that it will be useful, "+
        "but WITHOUT ANY WARRANTY; without even the implied warranty of "+
        "MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the "+
        "GNU General Public License for more details.\n\n"+
        "You should have received a copy of the GNU General Public License "+
        "along with this program.  If not, see <http://www.gnu.org/licenses/>.";

    	dialog.license = license;
    	dialog.wrap_license = true;

        try{
            var pixbuf=new Gdk.Pixbuf.from_resource("/org/spheras/desktopfolder/icon.png");
            dialog.set_logo(pixbuf);
            dialog.set_icon(pixbuf);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
            Util.show_error_dialog("Error",e.message);
        }


    	dialog.website = "https://github.com/spheras/Desktop-Folder";
    	dialog.website_label = "Desktop-Folder Github Place.";

    	dialog.response.connect ((response_id) => {
    		if (response_id == Gtk.ResponseType.CANCEL || response_id == Gtk.ResponseType.DELETE_EVENT) {
    			dialog.hide_on_delete ();
    		}
    	});

    	// Show the dialog:
    	dialog.present ();
    }

	/**
	 * Display a simple error message.
	 * @param title The title of the dialog.
	 * @param message The error message.
	 */
	public void show_error_dialog (string? title, string message){
		var dialog = new Gtk.MessageDialog(null, 0,
		                                   Gtk.MessageType.ERROR,
		                                   Gtk.ButtonsType.CLOSE,
		                                   "%s", message);
		dialog.title = title;
		dialog.border_width = 5;
		dialog.run();
		dialog.destroy();
	}


	/**
	 * Performs a recursive iteration on a directory, with callbacks.
	 *
	 * The caller can provide two {@link RecursiveDirAction}s: one for files,
	 * and another for directories. These callbacks can both be null
	 * (although if they both were, the call would do nothing). The directory
	 * callback is executed before the recursion continues.
	 * recursive_directory_after does the opposite.
	 *
	 * The directory callback is not performed on the toplevel directory.
	 *
	 * @param directory The directory to iterate.
	 * @param directory_action A {@link RecursiveDirAction} to perform on all
	 * directories.
	 * @param file_action A {@link RecursiveDirAction} to perform on all files.
	 */
	public void recursive_directory(string directory,
	                                RecursiveDirAction? directory_action,
	                                RecursiveDirAction? file_action)
	                                throws Error
	{
		do_recursive_directory(directory,
		                       directory_action,
		                       file_action,
		                       "",
		                       true);
	}

	/**
	 * Performs a recursive iteration on a directory, with callbacks.
	 *
	 * The caller can provide two {@link RecursiveDirAction}s: one for files,
	 * and another for directories. These callbacks can both be null
	 * (although if they both were, the call would do nothing). The directory
	 * callback is executed after the recursion continues. recursive_directory
	 * does the opposite.
	 *
	 * The directory callback is not performed on the toplevel directory.
	 *
	 * @param directory The directory to iterate.
	 * @param directory_action A {@link RecursiveDirAction} to perform on all
	 * directories.
	 * @param file_action A {@link RecursiveDirAction} to perform on all files.
	 */
	public void recursive_directory_after(string directory,
	                                      RecursiveDirAction? directory_action,
	                                      RecursiveDirAction? file_action)
	                                      throws Error
	{
		do_recursive_directory(directory,
		                       directory_action,
		                       file_action,
		                       "",
		                       false);
	}

	/**
	 * Used for execution of recursive_directory(). Should never be called,
	 * except by that function.
	 */
	private void do_recursive_directory(string directory,
	                                    RecursiveDirAction? directory_action,
	                                    RecursiveDirAction? file_action,
	                                    string rel_path,
	                                    bool dir_first)
	                                    throws Error
	{
		var dir = GLib.Dir.open(directory, 0);
		string child_path;

		while ((child_path = dir.read_name()) != null)
		{
			var child_full_path = Path.build_filename(directory, child_path);
			var child_rel_path = Path.build_filename(rel_path, child_path);
			if (FileUtils.test(child_full_path, FileTest.IS_DIR))
			{
				if (directory_action != null && dir_first)
				{
					directory_action(child_rel_path, child_full_path);
				}

				// recurse
				do_recursive_directory(child_full_path,
				                       directory_action, file_action,
				                       child_rel_path,
				                       dir_first);

				if (directory_action != null && !dir_first)
				{
					directory_action(child_rel_path, child_full_path);
				}
			}
			else // the path is a file
			{
				if (file_action != null)
				{
					file_action(child_rel_path, child_full_path);
				}
			}
		}
	}

	public delegate void RecursiveDirAction(string path, string full_path)
	                                       throws GLib.Error;

	/**
	 * Recursively removes a directory.
	 *
	 * @param path The directory to be recursively deleted.
	 */
	public void recursive_delete(string path) throws GLib.Error
	{
		var dir = GLib.Dir.open(path, 0);

		if (dir == null)
		{
			throw new FileError.NOENT("Directory to remove doesn't exist: "+ path);
		}

		recursive_directory_after(path,
			(p, full_path) => {
				DirUtils.remove(full_path);
			},
			(p, full_path) => {
				FileUtils.unlink(full_path);
			});

		DirUtils.remove(path);
	}

	/**
	 * Recursive copies a directory.
	 *
	 * @param from_dir The directory to copy from.
	 * @param to_dir The directory to copy to.
	 */
	public void recursive_copy(string from_dir, string to_dir) throws GLib.Error
	{
		var top = File.new_for_path(to_dir);
		if (!top.query_exists(null))
		{
			top.make_directory_with_parents(null);
		}

		recursive_directory(from_dir,
			(path, full_path) => {
				var dir = File.new_for_path(Path.build_filename(to_dir, path));
				if (!dir.query_exists(null)) dir.make_directory(null);
			},
			(path, full_path) => {
				var from = File.new_for_path(full_path);
				var to = File.new_for_path(Path.build_filename(to_dir, path));
				from.copy(to, FileCopyFlags.OVERWRITE, null, null);
			});
	}

	/**
	 * Returns the parent window of the specified widget.
	 */
	public Gtk.Window widget_window(Gtk.Widget widg)
	{
		while (widg.get_parent() != null) widg = widg.get_parent();
		return widg as Gtk.Window;
	}

	/**
	 * Returns an absolute path for the given path.
	 */
	public static string absolute_path(string path)
	{
		var file = GLib.File.new_for_path(path);
		return file.resolve_relative_path(".").get_path();
	}

	/**
	 * Converts the given angle from degrees to radians.
	 *
	 * @param deg Angle in radians
	 * @return Angle in degrees
	 */
	public static double deg_to_rad (double deg) {
		return (deg * Math.PI / 180f);
	}

	/**
	 * Converts the given angle from radians to degrees.
	 *
	 * @param rad Angle in degrees
	 * @return Angle in radians
	 */
	public static double rad_to_deg (double rad) {
		return (rad / Math.PI * 180f);
	}

	/**
	* @name create_new_photo
	* @param {Gtk.Window} window the parent window to show the dialog
	* @description show a dialog to create a new photo
	*/
	public static void create_new_photo(Gtk.Window window){
		Gtk.FileChooserDialog chooser = new Gtk.FileChooserDialog (
				DesktopFolder.Lang.PHOTO_SELECT_PHOTO_MESSAGE, window,
				Gtk.FileChooserAction.OPEN,
				DesktopFolder.Lang.DIALOG_CANCEL,
				Gtk.ResponseType.CANCEL,
				DesktopFolder.Lang.DIALOG_SELECT,
				Gtk.ResponseType.ACCEPT);

		Gtk.FileFilter filter = new Gtk.FileFilter();
		filter.set_name("Images");
		filter.add_mime_type("image");
		filter.add_mime_type("image/png");
		filter.add_mime_type("image/jpeg");
		filter.add_mime_type("image/gif");
		filter.add_pattern("*.png");
		filter.add_pattern("*.jpg");
		filter.add_pattern("*.gif");
		filter.add_pattern("*.tif");
		filter.add_pattern("*.xpm");
		chooser.add_filter(filter);


		// Process response:
		if (chooser.run () == Gtk.ResponseType.ACCEPT) {
			  var photo_path=chooser.get_filename();
			  PhotoSettings ps=new PhotoSettings(photo_path);
	          string path=DesktopFolderApp.get_app_folder()+"/"+ps.name+"."+DesktopFolder.PHOTO_EXTENSION;
	          File f=File.new_for_path (path);
	          ps.save_to_file(f);
		}
		chooser.close();
	}


	/**
    * @name create_new_desktop_folder
    * @description create a new folder inside the desktop
	* @param {Gtk.Window} window the parent window to show the dialog
    */
    public static void create_new_desktop_folder(Gtk.Window window){
		RenameDialog dialog = new RenameDialog (window,
                                                DesktopFolder.Lang.DESKTOPFOLDER_ENTER_TITLE,
                                                DesktopFolder.Lang.DESKTOPFOLDER_ENTER_NAME,
                                                DesktopFolder.Lang.DESKTOPFOLDER_NEW);
        dialog.on_rename.connect((new_name)=>{
            //creating the folder
            if(new_name!=""){
				//cancelling the current monitor
		        DirUtils.create(DesktopFolderApp.get_app_folder()+"/"+new_name,0755);
            }
        });
        dialog.show_all ();
    }

    /**
    * @name create_new_note
    * @description create a new note inside the desktop
	* @param {Gtk.Window} window the parent window to show the dialog
    */
    public static void create_new_note(Gtk.Window window){
		RenameDialog dialog = new RenameDialog (window,
												DesktopFolder.Lang.NOTE_ENTER_TITLE,
												DesktopFolder.Lang.NOTE_ENTER_NAME,
												DesktopFolder.Lang.NOTE_NEW);
		dialog.on_rename.connect((new_name)=>{
			//creating the folder
			if(new_name!=""){
				NoteSettings ns=new NoteSettings(new_name);
		        string path=DesktopFolderApp.get_app_folder()+"/"+new_name+"."+DesktopFolder.NOTE_EXTENSION;
		        File f=File.new_for_path (path);
		        ns.save_to_file(f);
			}
		});
		dialog.show_all ();
    }
}
