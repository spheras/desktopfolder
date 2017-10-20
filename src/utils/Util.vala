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
    * @name FileOperationAction
    * @description delegate function to inform about the copy being operated
    * @param {GLib.File} file the file being operated
    */
    public delegate void FileOperationAction(GLib.File file);

    /**
    * @name copy_recursive
    * @description this function copy recursively from a GLib.File to a GLib.File
    * @param {GLib.File} src the origin file
    * @param {GLib.File} src the destination file
    * @param {GLib.FileCopyFlags} flags the set of flags for the copy operation (NONE by default)
    * @param {GLib.Cancellable} cancellable object to allow cancel the operation
    * @param {FileOperationAction} listener the listener to get the current operation
    * @return bool true->if everything was OK
    */
    public bool copy_recursive (GLib.File src, GLib.File dest, GLib.FileCopyFlags flags = GLib.FileCopyFlags.NONE,
        GLib.Cancellable? cancellable = null,FileOperationAction? listener=null ) throws GLib.Error {
        GLib.FileType src_type = src.query_file_type (GLib.FileQueryInfoFlags.NONE, cancellable);
        if ( src_type == GLib.FileType.DIRECTORY ) {
            dest.make_directory (cancellable);
            src.copy_attributes (dest, flags, cancellable);

            string src_path = src.get_path ();
            string dest_path = dest.get_path ();
            GLib.FileEnumerator enumerator = src.enumerate_children (GLib.FileAttribute.STANDARD_NAME, GLib.FileQueryInfoFlags.NONE, cancellable);
            for ( GLib.FileInfo? info = enumerator.next_file (cancellable) ; info != null ; info = enumerator.next_file (cancellable) ) {
                copy_recursive (
                    GLib.File.new_for_path (GLib.Path.build_filename (src_path, info.get_name ())),
                    GLib.File.new_for_path (GLib.Path.build_filename (dest_path, info.get_name ())),
                    flags,
                    cancellable, listener);
            }
        } else if ( src_type == GLib.FileType.REGULAR ) {
            if(listener!=null){
                listener(dest);
            }else{
                debug("copying %s",dest.get_basename());
            }
            src.copy (dest, flags, cancellable);
        }

        return true;
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

	/**
	* @name blur_image_surface
	* @description Performs a simple 2D Gaussian blur of radius @radius on surface @surface.
	*/
	public static void blur_image_surface (Cairo.ImageSurface surface, int radius) {
		debug("start blur1");

		Cairo.ImageSurface tmp;
		int width, height;
		int src_stride, dst_stride;
		int x, y, z, w;
		uchar[] src;
		uchar[] dst;
		int s, d;
		uint32 a, p;
		int i, j, k;
		uint8 kernel[17];
		int size =(int) (17 / sizeof (uint8));
		int half =(int) ((17 / sizeof(uint8)) / 2);

		if (surface.status()!=Cairo.Status.SUCCESS){
			return;
		}

		width = surface.get_width ();
		height = surface.get_height ();

		debug("start blur2");

		switch (surface.get_format()) {
			case Cairo.Format.A1:
			default:
				/* Don't even think about it! */
				return;
			case Cairo.Format.A8:
				/* Handle a8 surfaces by effectively unrolling the loops by a
				* factor of 4 - this is safe since we know that stride has to be a
				* multiple of uint32_t. */
				width = width / 4;
				break;
			case Cairo.Format.RGB24:
			case Cairo.Format.ARGB32:
				break;
		}

		debug("start blur2.1");

		tmp = new Cairo.ImageSurface(Cairo.Format.ARGB32, width, height);
		if (tmp.status()!=Cairo.Status.SUCCESS)
			return;

			debug("start blur2.2");
		src = surface.get_data();
		debug("start blur2.3");
		src_stride = surface.get_stride();
		debug("start blur2.4");

		debug("start blur2.5");

		dst = tmp.get_data();
		dst_stride = tmp.get_stride();

		debug("start blur3");

		a = 0;
		for (i = 0; i < size; i++) {
			double f = i - half;
			kernel[i] = (uint8) (Math.exp (- f * f / 30.0) * 80);
			a = a+kernel[i];
		}

		/* Horizontally blur from surface -> tmp */
		for (i = 0; i < height; i++) {
			s = i*src_stride;
			d = i*dst_stride;
			for (j = 0; j < width; j++) {
				if (radius < j && j < width - radius) {
					dst[d+j] = src[s+j];
					continue;
				}

				x = y = z = w = 0;
				for (k = 0; k < size; k++) {
					if (j - half + k < 0 || j - half + k >= width){
						continue;
					}

					p = src[s+ j - half + k];

					x = x + (int) (((p >> 24) & 0xff) * kernel[k]);
					y = y + (int) (((p >> 16) & 0xff) * kernel[k]);
					z = z + (int) (((p >>  8) & 0xff) * kernel[k]);
					w = w + (int) (((p >>  0) & 0xff) * kernel[k]);
				}
				dst[d+j] = (uchar) ((x / a << 24) | (y / a << 16) | (z / a << 8) | w / a);
			}
		}

		debug("start blur4");

		/* Then vertically blur from tmp -> surface */
		for (i = 0; i < height; i++) {
			s = i* dst_stride;
			d = i * src_stride;
			for (j = 0; j < width; j++) {
				if (radius <= i && i < height - radius) {
					src[j] = dst[j];
					continue;
				}

				x = y = z = w = 0;
				for (k = 0; k < size; k++) {
					if (i - half + k < 0 || i - half + k >= height){
						continue;
					}

					s = (i - half + k) * dst_stride;
					p = dst[s+j];

					x = x + (int) (((p >> 24) & 0xff) * kernel[k]);
					y = y + (int) (((p >> 16) & 0xff) * kernel[k]);
					z = z + (int) (((p >>  8) & 0xff) * kernel[k]);
					w = w + (int) (((p >>  0) & 0xff) * kernel[k]);
				}
				src[d+j] = (uchar) ((x / a << 24) | (y / a << 16) | (z / a << 8) | w / a);
			}
		}

		debug("start blur5");

		//cairo_surface_destroy (tmp);
		surface.mark_dirty ();
	}

}
