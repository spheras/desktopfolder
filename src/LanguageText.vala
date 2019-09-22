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

namespace DesktopFolder.Lang {
    // Application Description
    public const string APP_DESCRIPTION                          = _("Come back to life your minimalist Desktop \n Organize files at your Desktop using Panes.");
    // Generic Dialog OK Button
    public const string DIALOG_OK                                = _("_Ok");
    // Generic Dialog CANCEL Button
    public const string DIALOG_CANCEL                            = _("_Cancel");
    // Generic Dialog Select Button
    public const string DIALOG_SELECT                            = _("_Select");
    // Trying to paste and the clipboard is empty
    public const string CLIPBOARD_EMPTY                          = _("There is nothing on the clipboard to paste");
    // Dialog Error Title: Invalid Filename provided
    public const string CANT_DROP                                = _("Cannot drop this file");
    // Dialog Error Message while trying to drop
    public const string CANT_DROP_INVALID_FILE_NAME              = _("Invalid file name provided");
    // Title dialog for File Operations
    public const string DRAGNDROP_FILE_OPERATIONS                = _("File Operations");
    // Copying File message for progress dialog
    public const string DRAGNDROP_COPYING                        = _("Copying");
    // Drop Menu - Copy
    public const string DROP_MENU_COPY                           = _("Copy Here");
    // Drop Menu - Move
    public const string DROP_MENU_MOVE                           = _("Move Here");
    // Drop Menu - Link
    public const string DROP_MENU_LINK                           = _("Link Here");
    // Drop Menu - Cancel
    public const string DROP_MENU_CANCEL                         = _("Cancel");
    // desktopfolder menu - create a new Desktop-Folder Pane
    public const string DESKTOPFOLDER_MENU_NEW_DESKTOP_FOLDER    = _("Panel");
    // desktopfolder menu - create a new Desktop-Folder Pane
    public const string DESKTOPFOLDER_MENU_LINK_PANEL            = _("Link Panel");
    // desktopfolder menu - enable/disable lock items
    public const string DESKTOPFOLDER_MENU_LOCK_ITEMS            = _("Lock icons:");
    // desktopfolder menu - enable/disable lock panel
    public const string DESKTOPFOLDER_MENU_LOCK_PANEL            = _("Lock panel:");
    // desktopfolder menu - enable/disable text shadows
    public const string DESKTOPFOLDER_MENU_TEXT_SHADOW           = _("Text shadow:");
    // desktopfolder menu - enable/disable text bolds
    public const string DESKTOPFOLDER_MENU_TEXT_BOLD             = _("Text bold:");
    // desktopfolder menu - create a new Note
    public const string DESKTOPFOLDER_MENU_NEW_NOTE              = _("Note");
    // desktopfolder menu - create a new Folder
    public const string DESKTOPFOLDER_MENU_NEW_FOLDER            = _("Folder");
    // desktopfolder menu - create a new empty Text File
    public const string DESKTOPFOLDER_MENU_NEW_EMPTY_FILE        = _("Empty File");
    // desktopfolder menu - rename a Desktop-Folder Pane
    public const string DESKTOPFOLDER_MENU_RENAME_DESKTOP_FOLDER = _("Rename");
    // desktopfolder menu - remove a Desktop-Folder Pane
    public const string DESKTOPFOLDER_MENU_REMOVE_DESKTOP_FOLDER = _("Move to Trash");
    // desktopfolder menu - past from clipboard to the desktop-folder
    public const string DESKTOPFOLDER_MENU_PASTE                 = _("Paste");
    // desktopfolder - The default name for the new folder to be created
    public const string DESKTOPFOLDER_NEW_FOLDER_NAME            = _("untitled folder");
    // desktopfolder - The default name for the new text file to be created
    public const string DESKTOPFOLDER_NEW_TEXT_FILE_NAME         = _("new file");
    // desktopfolder - The message to confirm the deletion of a Desktop Folder
    public const string DESKTOPFOLDER_DELETE_TOOLTIP             = _("Move to Trash");
    // desktopfolder - The message to confirm the deletion of a Desktop Folder
    public const string DESKTOPFOLDER_PROPERTIES_TOOLTIP         = _("Properties");
    // desktopfolder - Title for a Dialog Text to ask the new name for the Desktop-Folder
    public const string NOTE_NEW                   = _("New Note");
    // Note - popup option to set the paper texture or not
    public const string NOTE_MENU_PAPER_NOTE       = _("Paper Texture");
    // Note - popup option to set allways on top or not
    public const string NOTE_MENU_ON_TOP           = _("Always on top");
    // Note - popup option to set allways on back or not
    public const string NOTE_MENU_ON_BACK          = _("Always on back");
    // Menu popup option to rename the note
    public const string NOTE_MENU_RENAME_NOTE      = _("Rename");
    // Menu popup option to delete the note
    public const string NOTE_MENU_DELETE_NOTE      = _("Move to Trash");
    // Item Menu - Open the file
    public const string ITEM_MENU_OPEN             = _("Open");
    // Item Menu - Execute the file
    public const string ITEM_MENU_OPEN_WITH        = _("Open With Other Application...");
    // Item Menu - Execute the file
    public const string ITEM_MENU_EXECUTE          = _("Execute");
    // Item Menu - cut the file/folder
    public const string ITEM_MENU_CUT              = _("Cut");
    // Item Menu - copy the file/folder
    public const string ITEM_MENU_COPY             = _("Copy");
    // Item Menu - rename the file/folder
    public const string ITEM_MENU_RENAME           = _("Rename");
    // Item Menu - trash the file/folder
    public const string ITEM_MENU_TRASH            = _("Move to Trash");
    // Item Menu - delete the file/folder
    public const string ITEM_MENU_DELETE           = _("Delete");
    // Item Menu - change icon
    public const string ITEM_MENU_CHANGEICON       = _("Change Icon");
    // Item - Delete Folder Item Dialog message
    public const string ITEM_DELETE_FOLDER_MESSAGE = _("This action will DELETE the folder and ALL its content.\n<b>Are you sure?</b>");
    // Item - Delete File Item Dialog message
    public const string ITEM_DELETE_FILE_MESSAGE   = _("This action will DELETE the file.\n<b>Are you sure?</b>");
    // Item - Delete File Link Dialog message
    public const string ITEM_DELETE_LINK_MESSAGE   = _("This action will DELETE the link (just the link).\n<b>Are you sure?</b>");
    // Item - Change icon dialog message to select an image file
    public const string ITEM_CHANGEICON_MESSAGE    = _("Select the image icon to be used.");
    // Name of the first desktop-folder panel, when no panels found
    public const string APP_FIRST_PANEL            = _("My First Panel");
    // Hint to show desktop shortcut
    // public const string HINT_SHOW_DESKTOP=_("Press ⌘-D to Show Desktop");
    // Menu option to create a link to a file
    public const string DESKTOPFOLDER_MENU_NEW_FILE_LINK                = _("Link to File");
    // Menu option to create a link to a folder
    public const string DESKTOPFOLDER_MENU_NEW_FOLDER_LINK              = _("Link to Folder");
    // Dialog message to create a new link
    public const string DESKTOPFOLDER_LINK_MESSAGE                      = _("Select the destination file/folder of the link");
    // Dialog message to create a new link panel
    public const string DESKTOPFOLDER_PANELLINK_MESSAGE                 = _("Select the destination folder for the Panel");
    // Menu popup option to remove a photo
    public const string PHOTO_MENU_DELETE_PHOTO                         = _("Remove");
    // desktopfolder menu - create a new Photo
    public const string DESKTOPFOLDER_MENU_NEW_PHOTO                    = _("Photo");
    // dialog message to select an image file to be shown at the desktop
    public const string PHOTO_SELECT_PHOTO_MESSAGE                      = _("Select the picture to show");
    // desktopfolder menu - create a new empty Text File
    public const string DESKTOPFOLDER_MENU_NEW_SUBMENU                  = _("New");
    // panel properties - Properties section
    public const string PANELPROPERTIES_PROPERTIES                      = _("This Panel");
    // panel properties - General section
    public const string PANELPROPERTIES_GENERAL                         = _("General");
    // panel properties - Behavior section
    public const string PANELPROPERTIES_BEHAVIOR                        = _("Behavior");
    // panel properties - Appearance section
    public const string PANELPROPERTIES_APPEARANCE                      = _("Appearance");
    // panel properties - Close button
    public const string PANELPROPERTIES_CLOSE                           = _("Close");
    // panel properties - Panel over Desktop title
    public const string PANELPROPERTIES_DESKTOP_ICONS                   = _("Icons on desktop:");
    // panel properties - Panel over Desktop title
    public const string PANELPROPERTIES_DESKTOP_PANEL                   = _("Enable desktop:");
    // panel properties - Panel over desktop description
    public const string PANELPROPERTIES_DESKTOP_PANEL_DESCRIPTION       = _("This change will require you to log out and in again");
    // panel properties - Resolution Strategy title
    public const string PANELPROPERTIES_RESOLUTION_STRATEGY             = _("When changing resolution:");
    // panel properties - Resolution Strategy Description
    public const string PANELPROPERTIES_RESOLUTION_STRATEGY_DESCRIPTION = _("This is how panels, notes and photos will resize when you change the screen resolution");
    // panel properties - Resolution Strategy NONE
    public const string PANELPROPERTIES_RESOLUTION_STRATEGY_NONE        = _("Do nothing");
    // panel properties - Resolution Strategy NONE
    public const string PANELPROPERTIES_RESOLUTION_STRATEGY_SCALE       = _("Scale to new resolution");
    // panel properties - Resolution Strategy NONE
    public const string PANELPROPERTIES_RESOLUTION_STRATEGY_STORE       = _("Store per resolution");
    // change desktop menu
    public const string DESKTOPFOLDER_MENU_CHANGEDESKTOP                = _("Change Wallpaper");
    // open terminal here
    public const string DESKTOPFOLDER_MENU_OPENTERMINAL                 = _("Open Terminal Here");
    // open terminal here
    public const string DESKTOPFOLDER_MENU_OPEN_IN_TERMINAL             = _("Open in terminal");
    // file properties window - properties
    public const string ITEM_PROPSWINDOW_SHOW_FILEINFO                  = _("Properties");
    // file properties window - file name
    public const string ITEM_PROPSWINDOW_SHOW_FILENAME                  = _("Name");
    // file properties window - file type
    public const string ITEM_PROPSWINDOW_SHOW_CONTENTTYPE               = _("Type");
    // file properties window - file location
    public const string ITEM_PROPSWINDOW_SHOW_LOCATION                  = _("Location");
    // file properties window - link target
    public const string ITEM_PROPSWINDOW_SHOW_TARGET                    = _("Target");
    // file properties window - property value is unknown
    public const string ITEM_PROPSWINDOW_UNKNOWN                        = _("Unknown");
    // file properties window - property value - number of items
    public const string ITEM_PROPSWINDOW_N_ITEMS                        = _("items");
    // file properties window - content
    public const string ITEM_PROPSWINDOW_CONTENT                        = _("Content");
    // file properties window - total folder size
    public const string ITEM_PROPSWINDOW_TOTALSIZE                      = _("Total size");
    // file properties window - file size
    public const string ITEM_PROPSWINDOW_FILESIZE                       = _("File size");
    // file properties window - file is executable?
    public const string ITEM_PROPSWINDOW_ALLOWEXECUTE                   = _("Allow execution");
    // file properties window - last time used
    public const string ITEM_PROPSWINDOW_LASTUSED                       = _("Used");
    // file properties window - last time modified
    public const string ITEM_PROPSWINDOW_LASTMODIFIED                   = _("Modified");
    // Items Arrangement Configuration
    public const string PANELPROPERTIES_ARRANGEMENT                     = _("Icon arrangement:");
    // Free arrangement
    public const string PANELPROPERTIES_ARRANGEMENT_FREE                = _("Free");
    // Grid arrangement
    public const string PANELPROPERTIES_ARRANGEMENT_GRID                = _("Grid");
    // Managed arrangement
    public const string PANELPROPERTIES_ARRANGEMENT_MANAGED             = _("Let app manage");
    // Default Panel Management
    public const string PANELPROPERTIES_ICONS                           = _("Icons");
    // Default Panel Management
    public const string PANELPROPERTIES_ARRANGEMENT_DEFAULT             = _("Default icon arrangement:");
    // Default Panel Arrangement Padding for Items
    public const string PANELPROPERTIES_ARRANGEMENT_PADDING             = _("Icon spacing:");
    // Default Panel Arrangement Padding for Items
    public const string PANELPROPERTIES_ARRANGEMENT_PADDING_DEFAULT     = _("Default icon spacing:");

    // sort by submenu
    public const string DESKTOPFOLDER_MENU_SORT_BY       = _("Sort by");
    // sort panel's items by name
    public const string DESKTOPFOLDER_MENU_SORT_BY_NAME  = _("Name");
    // sort panel's items by size
    public const string DESKTOPFOLDER_MENU_SORT_BY_SIZE  = _("Size");
    // sort panel's items by file type
    public const string DESKTOPFOLDER_MENU_SORT_BY_TYPE  = _("Type");
    // sort panel's in reverse
    public const string DESKTOPFOLDER_MENU_SORT_REVERSE  = _("Reverse Order");
    // force panels to be organized automatically one time
    public const string DESKTOPFOLDER_MENU_SORT_ORGANIZE = _("Reorganize Icons");
    // the title of a panel when a new one is created
    public const string NEWLY_CREATED_PANEL              = _("Untitled Panel");
    // the title of a note when a new one is created
    public const string NEWLY_CREATED_NOTE               = _("New Note");
    /// Please keep $FILE_NAME, it will be replaced by it's value
    public const string LINK_TO = _("Link to $FILE_NAME");
    // Menu option to show the desktop
    public const string DESKTOPFOLDER_MENU_SHOW_DESKTOP  = _("Show Desktop");
    // Menu option to hide the desktop
    public const string DESKTOPFOLDER_MENU_HIDE_DESKTOP  = _("Hide Desktop");
    // Menu option to sort the items vertically
    public const string DESKTOPFOLDER_MENU_SORT_VERTICAL = _("Sort Vertically");
    // Menu color selection dialog
    public const string MENU_COLOR_DIALOG_TITLE          = _("Select Your Favorite Color");
}
