using Gee;
namespace PovEdit{
	errordomain UTF8Error {
		INVALID
	}
	GUI gui;
	public class GUI {
		public Gtk.Window main_window;
		public Gtk.MenuBar menu_bar;
		public Gtk.Notebook files_notebook;
		public LinkedList<File> files;
		public ConfigManager config_manager;
		public HashMap<string,HashMap<string,string>> config;
		private Gtk.AccelGroup accelerators;
		private SList<Gtk.RadioMenuItem> language_radios = new SList<Gtk.RadioMenuItem>();
		private LinkedList<Gtk.SourceLanguage> languages = new LinkedList<Gtk.SourceLanguage>();
		private bool language_menu_inactive = false;
		public Gtk.RadioMenuItem none_button;
		private Gtk.MenuItem[] files_menu = new Gtk.MenuItem[8];
		private Gtk.Label info_label;
		
		public GUI(string[] args) {
			// Setting up the GUI
			accelerators = new Gtk.AccelGroup();
			main_window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			main_window.title = "PovEdit";
			main_window.set_size_request(640,320);
			main_window.delete_event.connect(quit_app);
			main_window.destroy.connect(Gtk.main_quit);
			main_window.add_accel_group(accelerators);
			
			Gtk.VBox main_vbox = new Gtk.VBox(false,0);
			main_window.add(main_vbox);
			
			menu_bar = new Gtk.MenuBar();
			main_vbox.pack_start(menu_bar,false,true,0);
			
			// Menus etc
			
			// File menu
			Gtk.MenuItem file_menu_item = new Gtk.MenuItem.with_mnemonic(_("_File"));
			menu_bar.append(file_menu_item);
			Gtk.Menu file_menu = new Gtk.Menu();
			file_menu_item.submenu = file_menu;
			
			// New file
			Gtk.ImageMenuItem file_new = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.NEW,accelerators);
			file_menu.append(file_new);
			file_new.activate.connect(()=>{open_file();});
			
			// Open file
			Gtk.ImageMenuItem file_open = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.OPEN,accelerators);
			file_menu.append(file_open);
			file_open.activate.connect(menu_file_open);
			
			file_menu.append(new Gtk.MenuItem());
			// Save file
			Gtk.ImageMenuItem file_save = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.SAVE,accelerators);
			file_menu.append(file_save);
			file_save.activate.connect(menu_file_save);
			
			// Save as...
			Gtk.ImageMenuItem file_save_as = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.SAVE_AS,accelerators);
			file_menu.append(file_save_as);
			file_save_as.activate.connect(menu_file_save_as);
			
			file_menu.append(new Gtk.MenuItem());
			// Close file
			Gtk.ImageMenuItem file_close = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.CLOSE,accelerators);
			file_menu.append(file_close);
			file_close.activate.connect(menu_file_close);
			
			// Quit editor
			Gtk.ImageMenuItem file_exit = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.QUIT,accelerators);
			file_menu.append(file_exit);
			file_exit.activate.connect(() => {
				if(!quit_app()) {
					Gtk.main_quit();
				}
			});
			
			// Edit
			Gtk.MenuItem edit_menu_item = new Gtk.MenuItem.with_mnemonic("_Edit");
			menu_bar.append(edit_menu_item);
			Gtk.Menu edit_menu = new Gtk.Menu();
			edit_menu_item.submenu = edit_menu;
			
			// Undo
			Gtk.ImageMenuItem edit_undo = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.UNDO,accelerators);
			edit_menu.append(edit_undo);
			edit_undo.activate.connect(() => {
				if(current_file() != null) {
					current_file().buffer.undo();
				}
			});
			edit_undo.add_accelerator("activate",accelerators,Gdk.keyval_from_name("Z"),Gdk.ModifierType.CONTROL_MASK,Gtk.AccelFlags.VISIBLE);
			
			// Redo
			Gtk.ImageMenuItem edit_redo = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.REDO,accelerators);
			edit_menu.append(edit_redo);
			edit_redo.activate.connect(() => {
				if(current_file() != null) {
					current_file().buffer.redo();
				}
			});
			//Execute
			Gtk.ImageMenuItem edit_exec = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.EXECUTE,accelerators);
			edit_menu.append(edit_exec);
			edit_exec.activate.connect(() => {
				on_execute_clicked();
			});
			edit_exec.add_accelerator("activate",accelerators,Gdk.keyval_from_name("Z"),Gdk.ModifierType.CONTROL_MASK,Gtk.AccelFlags.VISIBLE);
			
			
			edit_menu.append(new Gtk.MenuItem());
			
			// Find
			Gtk.ImageMenuItem edit_find = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.FIND,accelerators);
			edit_menu.append(edit_find);
			edit_find.activate.connect(() => {
				menu_edit_find();
			});
			
			edit_menu.append(new Gtk.MenuItem());
			
			// Preferences
			Gtk.ImageMenuItem edit_preferences = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.PREFERENCES,accelerators);
			edit_menu.append(edit_preferences);
			edit_preferences.activate.connect(() => {
				var dialog = new PreferencesDialog ();
      	dialog.show ();
			});
			edit_preferences.add_accelerator("activate",accelerators,Gdk.keyval_from_name("P"),Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.MOD1_MASK,Gtk.AccelFlags.VISIBLE);
			
			// View menu
			Gtk.MenuItem view_menu_item = new Gtk.MenuItem.with_mnemonic(_("_View"));
			menu_bar.append(view_menu_item);
			Gtk.Menu view_menu = new Gtk.Menu();
			view_menu_item.submenu = view_menu;
			
			// Languages submenu
			Gtk.MenuItem view_languages_item = new Gtk.MenuItem.with_mnemonic(_("_Languages"));
			Gtk.Menu view_languages = new Gtk.Menu();
			view_languages_item.submenu = view_languages;
			view_menu.append(view_languages_item);
			
			// Dynamically-generated radio buttons for languages
			foreach(string id in Gtk.SourceLanguageManager.get_default().get_language_ids()) {
				languages.add(Gtk.SourceLanguageManager.get_default().get_language(id));
			}
			/** @BUG error! vala ok ; but "undefined reference to `GTK_IS_SOURCE_LANGUAGE'"
        */
			/*	languages.sort((langa,langb) => {
				if((langa as Gtk.SourceLanguage).name.down() > (langb as Gtk.SourceLanguage).name.down()) {
					return 1;
				} else if((langa as Gtk.SourceLanguage).name.down() == (langb as Gtk.SourceLanguage).name.down()) {
					return 0;
				} else {
					return -1;
				}
			});*/
			// "none" button
			none_button = new Gtk.RadioMenuItem.with_mnemonic(language_radios,_("_None"));
			//language_radios = none_button.get_group();
			view_languages.append(none_button);
			none_button.toggled.connect(() => {
				if(none_button.active && current_file() != null && !language_menu_inactive) {
					current_file().buffer.language = null;
				}
			});
			foreach(Gtk.SourceLanguage language in languages) {
				Gtk.RadioMenuItem lang = new Gtk.RadioMenuItem.with_label_from_widget(none_button,language.name);
				language_radios.append(lang);
				lang.active = false;
				lang.toggled.connect(() => {
					if(lang.active) {
						foreach(Gtk.SourceLanguage _language in languages) {
							if(lang.label == _language.name && current_file() != null && !language_menu_inactive) {
								current_file().buffer.language = _language;
								break;
							}
						}
					}
				});
				view_languages.append(lang);
			}
			view_menu.append(new Gtk.MenuItem());
			
			// Previous file
			Gtk.MenuItem view_prev_file = new Gtk.MenuItem.with_mnemonic(_("_Previous file"));
			view_prev_file.activate.connect(files_notebook.prev_page);
			view_prev_file.add_accelerator("activate",accelerators,Gdk.keyval_from_name("pagedown"),Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.MOD1_MASK,Gtk.AccelFlags.VISIBLE);
			view_menu.append(view_prev_file);
			
			// Next file
			Gtk.MenuItem view_next_file = new Gtk.MenuItem.with_mnemonic(_("_Next file"));
			view_next_file.activate.connect(files_notebook.next_page);
			view_prev_file.add_accelerator("activate",accelerators,Gdk.keyval_from_name("pageup"),Gdk.ModifierType.CONTROL_MASK|Gdk.ModifierType.MOD1_MASK,Gtk.AccelFlags.VISIBLE);
			view_menu.append(view_next_file);
			
			// Help menu
			Gtk.MenuItem help_menu_item = new Gtk.MenuItem.with_mnemonic(_("_Help"));
			menu_bar.append(help_menu_item);
			Gtk.Menu help_menu = new Gtk.Menu();
			help_menu_item.submenu = help_menu;
			
			// Help contents
			Gtk.ImageMenuItem help_contents = new Gtk.ImageMenuItem.with_mnemonic(_("_Contents"));
			help_menu.append(help_contents);
			help_contents.image = new Gtk.Image.from_stock(Gtk.Stock.HELP,Gtk.IconSize.MENU);
			help_contents.add_accelerator("activate",accelerators,Gdk.keyval_from_name("F1"),0,Gtk.AccelFlags.VISIBLE);
			help_contents.activate.connect(() => {print("Not implemented yet\n");});
			
			help_menu.append(new Gtk.MenuItem());
			
			// About!
			Gtk.ImageMenuItem help_about = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.ABOUT,accelerators);
			help_menu.append(help_about);
			help_about.activate.connect(() => {
				Gtk.AboutDialog dialog = new Gtk.AboutDialog();
				dialog.authors = {"NieXS <neo dot niexs at gmail dot com>","august0815<mariomarcec42 at googlemail dot com>",null};
				dialog.copyright = "Copyright (c) 2010 Eduardo Niehues. All rights reserved.\nCopyright (c) 2012 Marcec Mario. All rights reserved.";
				dialog.license = """
Copyright (c) 2010, Eduardo Niehues.
Copyright (c) 2012, Marcec Mario.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Eduardo Niehues nor the
      names of his contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL EDUARDO NIEHUES BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.""";
				dialog.logo_icon_name = APPNAME;
				dialog.program_name   = APPNAME;
				dialog.version = VERSION;
				dialog.response.connect(() => {dialog.destroy();});
				dialog.run();
			});
			
			// Toolbar!
			Gtk.Toolbar toolbar = new Gtk.Toolbar();
			main_vbox.pack_start(toolbar,false,true,0);
			
			// New file
			Gtk.ToolButton new_button = new Gtk.ToolButton.from_stock(Gtk.Stock.NEW);
			toolbar.insert(new_button,0);
			new_button.clicked.connect(()=>{open_file();});
			// Open file
			Gtk.ToolButton open_button = new Gtk.ToolButton.from_stock(Gtk.Stock.OPEN);
			toolbar.insert(open_button,1);
			open_button.clicked += menu_file_open;
			// Separator
			toolbar.insert(new Gtk.SeparatorToolItem(),2);
			// Save file
			Gtk.ToolButton save_button = new Gtk.ToolButton.from_stock(Gtk.Stock.SAVE);
			toolbar.insert(save_button,3);
			save_button.clicked += menu_file_save;
			// Moar separator
			toolbar.insert(new Gtk.SeparatorToolItem(),4);
			// Undo
			Gtk.ToolButton undo_button = new Gtk.ToolButton.from_stock(Gtk.Stock.UNDO);
			toolbar.insert(undo_button,5);
			undo_button.clicked.connect(() => {
				if(current_file() != null) {
					current_file().buffer.undo();
				}
			});
			// Redo
			Gtk.ToolButton redo_button = new Gtk.ToolButton.from_stock(Gtk.Stock.REDO);
			toolbar.insert(redo_button,6);
			redo_button.clicked.connect(() => {
				if(current_file() != null) {
					current_file().buffer.undo();
				}
			});
			// Separator
			toolbar.insert(new Gtk.SeparatorToolItem(),7);
			// Execute
			Gtk.ToolButton exec_button  = new Gtk.ToolButton.from_stock(Gtk.Stock.EXECUTE);
			toolbar.insert(exec_button ,8);
			exec_button .clicked.connect(() => {
				on_execute_clicked();
			});
			// Notebook holding the files
			files_notebook = new Gtk.Notebook();
			files_notebook.switch_page.connect((page,num) => {update_title(file_at_page((int)num));});
			files_notebook.page_reordered.connect(() => update_title());
			main_vbox.pack_start(files_notebook,true,true,0);
			
			// Shortcuts for tabs!
			view_menu.append(new Gtk.MenuItem());
			for(int n = 0;n < 9; n++) {
				print("Adding\n");
				files_menu[n] = new Gtk.MenuItem.with_label(_("File %d").printf(n+1));
				files_menu[n].add_accelerator("activate",accelerators,Gdk.keyval_from_name((n+1).to_string()),Gdk.ModifierType.MOD1_MASK,Gtk.AccelFlags.VISIBLE);
				int i = n;
				files_menu[n].activate.connect(() => {
					if(file_at_page(i) != null) {
						print(file_at_page(i).filename+"\n");
						files_notebook.page = i; // Redundancy redundancy redundancy
					} else {
						print("Null file\n");
					}
				});
				view_menu.append(files_menu[n]);
			}
			// Status bar
			info_label = new Gtk.Label("");
			info_label.justify = Gtk.Justification.LEFT;
			main_vbox.pack_start(info_label,false,true,0);
			
			main_window.show_all();
			
			files = new LinkedList<File>();
			config_manager = new ConfigManager();
			config = config_manager.config;
			
			if(args.length != 1) {
				int i = 0;
				foreach(string arg in args) {
					print(arg+"\n");
					if(FileUtils.test(arg,FileTest.EXISTS|FileTest.IS_REGULAR) && i != 0) {
						open_file_from_path(arg.split("/"));
						i++;
					}
				}
			} else {
				// Default file
				open_file();
			}
		}
		
		private bool open_file(string? name = null,string? path = null) {
			foreach(File file in files) {
				if(file.filename == name && file.filepath == path) { // Case-sensitive!
					return false; // File is already open
				}
			}
			if(name == null) {
				name = _("untitled");
			}
			if(path == null) {
				path = "";
			}
			
			if(files.size == 1 && files[0].filename == _("untitled") && files[0].filepath == "" && files[0].modified == false) {
				close_file(files[0]);
			}
			try {
				File file = new File(name,path);
				files.add(file);
				files_notebook.append_page(file.scroll,new FileLabel(file).hbox);
				files_notebook.show_all();
				files_notebook.page = files_notebook.page_num(file.scroll);
				files_notebook.set_tab_reorderable(file.scroll,true);
				file.view.grab_focus();
				Gtk.TextIter start_iter;
				file.buffer.get_start_iter(out start_iter);
				file.buffer.place_cursor(start_iter);
				apply_settings();
			
				return true;
			} catch(Error e) {
				Gtk.MessageDialog dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.ERROR,Gtk.ButtonsType.OK,_("There was an error opening the file."));
				dialog.response.connect(()=>{dialog.destroy();});
				dialog.run();
				return false;
			}
		}
		
		public File? current_file() {
			return file_at_page(files_notebook.page);
		}
		
		public void update_title(owned File? file = null,int? char_count = null) {
			if(file == null) {
				file = current_file();
			}
			if(file == null) {
				main_window.title = "PovEdit";
				none_button.active = true;
				info_label.label = "";
			} else {
				main_window.title = (file.modified ? "* " : "")+file.filename+" - "+file.filepath+" - PovEdit";
				language_menu_inactive = true;
				if(file.buffer.language == null) {
					none_button.active = true;
				} else {
					print(file.buffer.language.name+"\n");
					foreach(Gtk.RadioMenuItem button in language_radios) {
						if(button.label == file.buffer.language.name) {
							button.active = true;
							break;
						}
					}
				}
				language_menu_inactive = false;
				info_label.label = get_cursor_pos(current_file(),char_count);
			}
			int page = 0;
			foreach(Gtk.MenuItem item in files_menu) {
				item.visible = true;
				if(file_at_page(page) != null) {
					item.label = file_at_page(page).filename;
				}
				page++;
			}
			for(int i = files_notebook.get_n_pages(); i < 9; i++) {
				files_menu[i].visible = false;
			}
		}
		
		private string get_cursor_pos(File file,int? char_count = null) {
			int row;
			int col;
			int chars;
			int tab_width;
			Gtk.TextIter iter;
			Gtk.TextIter start;
			
			tab_width = (int)file.view.get_tab_width();
			
			file.buffer.get_iter_at_mark(out iter,file.buffer.get_insert());
			file.buffer.get_iter_at_mark(out start,file.buffer.get_insert());
			chars = char_count ?? iter.get_offset();
			row   = iter.get_line() + 1;
			
			col = 0;
			start.set_line_offset(0);
			
			while(!start.equal(iter)) {
				if(start.get_char() == '\t') {
					col += (tab_width - (col % tab_width));
				} else {
					col++;
				}
				start.forward_char();
			}
			
			return _("%s - Line %d, Column %d").printf(file.filename,row,col);
		}
		
		private File? file_at_page(int page) {
			foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == page) {
					return file;
				}
			}
			return null;
		}
		
		public void close_file(File file) {
			files_notebook.remove_page(files_notebook.page_num(file.scroll));
			files.remove(file);
			update_title();
		}
		
		private void open_file_from_path(string[] _raw_path) {
			string file = _raw_path[_raw_path.length-1];
			string[] raw_path = _raw_path[0:_raw_path.length-1];
			string path = string.joinv("/",raw_path)+"/";
			print(path+"\n");
			print(file+"\n");
			open_file(file,path);
		}
		
		private void save_file(File file,string[]? _raw_path = null) {
			if(_raw_path != null) {
				string filename = _raw_path[_raw_path.length-1];
				string[] raw_path = _raw_path[0:_raw_path.length-1];
				string path = string.joinv("/",raw_path)+"/";
				file.filename = filename;
				file.filepath = path;
			}
			try {
				FileUtils.set_contents(file.filepath+file.filename,file.view.buffer.text);
				file.modified = false;
				file.label.set_text(file.filename);
				file.unchanged_text = file.buffer.text;
				update_title();
			} catch(Error e) {
				Gtk.Dialog dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.ERROR,Gtk.ButtonsType.OK,_("Error saving file: access is denied."));
				dialog.response.connect(()=>{dialog.destroy();});
				dialog.run();
			}
		}
		
		private bool quit_app() {
			foreach(File file in files) {
				if(file.modified) {
					Gtk.MessageDialog dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO,_("Some files have unsaved changes, quit anyway?"));
					bool quit = false;
					dialog.response.connect((id) => {
						dialog.destroy();
						if(id == Gtk.ResponseType.YES) {
							quit = false;
						} else {
							quit = true;
						}
					});
					dialog.run();
					return quit;
				}
			}
			return false;
		}
		
		public void apply_settings() {
			foreach(File file in files) {
				print("Applying\n");
				file.view.auto_indent = config["core"]["auto_indent"] == "true";
				file.view.highlight_current_line = config["core"]["highlight_current_line"] == "true";
				file.view.indent_on_tab = true;
				file.view.insert_spaces_instead_of_tabs = config["core"]["indent_with_tabs"] != "true";
				//file.view.indent_width = config["core"]["indent_width"].to_int();
				file.view.tab_width = config["core"]["indent_width"].to_int();
				file.view.show_line_numbers = config["core"]["show_line_numbers"] == "true";
				file.view.show_right_margin = config["core"]["show_right_margin"] == "true";
				file.view.right_margin_position = config["core"]["right_margin_position"].to_int();
				file.buffer.highlight_matching_brackets = config["core"]["highlight_matching_brackets"] == "true";
				file.view.modify_font(Pango.FontDescription.from_string(config["core"]["font"]));
				
				Gtk.SourceStyleScheme scheme;
				
				Gtk.SourceStyleSchemeManager.get_default().prepend_search_path("/usr/share/gtksourceview-3.0/styles");
				foreach(string id in Gtk.SourceStyleSchemeManager.get_default().get_scheme_ids()) {
					if(Gtk.SourceStyleSchemeManager.get_default().get_scheme(id).name == config["core"]["color_scheme"]) {
						scheme = Gtk.SourceStyleSchemeManager.get_default().get_scheme(id);
						file.buffer.style_scheme = scheme;
						break;
					}
				}
			}
		}
		
		private void menu_file_open() {
			Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(_("Select file"),main_window,Gtk.FileChooserAction.OPEN,Gtk.Stock.OPEN,1,Gtk.Stock.CANCEL,2,null);
			dialog.set_current_folder((current_file() != null && current_file().filepath != "" ? current_file().filepath : Environment.get_home_dir()));
			dialog.file_activated.connect(() => {
				open_file_from_path(dialog.get_filename().split("/"));
				dialog.destroy();
			});
			dialog.response.connect((id) => {
				if(id==2 || dialog.get_filename() == null){dialog.destroy(); return;}
				open_file_from_path(dialog.get_filename().split("/"));
				dialog.destroy();
			});
			dialog.run();			
		}
		
		private void menu_file_save() {
			foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print("\""+file.filepath+"\"\n");
					if(file.filepath.strip().length == 0) {
						Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(_("Choose a file name"),main_window,Gtk.FileChooserAction.SAVE,Gtk.Stock.SAVE,1,Gtk.Stock.CANCEL,2,null);
						dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
						dialog.file_activated.connect(() => {
							Gtk.MessageDialog confirm_dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO,_("That file alreadly exists. Overwrite?"));
							confirm_dialog.response.connect((id) => {
								confirm_dialog.destroy();
								if(id == Gtk.ResponseType.YES && dialog.get_filename() != null) {
									save_file(file,dialog.get_filename().split("/"));
								}
								dialog.destroy();
							});
							confirm_dialog.run();
						});
						dialog.response.connect((id) => {
							if(id==2){dialog.destroy(); return;}
							save_file(file,dialog.get_filename().split("/"));
							dialog.destroy();
						});
						dialog.run();
					} else {
						save_file(file);
					}
					break;
				}
			}			
		}
		
		private void menu_file_save_as() {
			foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print("\""+file.filepath+"\"\n");
					Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(_("Choose a file name"),main_window,Gtk.FileChooserAction.SAVE,Gtk.Stock.SAVE,1,Gtk.Stock.CANCEL,2,null);
					dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
					dialog.file_activated.connect(() => {
						Gtk.MessageDialog confirm_dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO,_("That file alreadly exists. Overwrite?"));
						confirm_dialog.response.connect((id) => {
							confirm_dialog.destroy();
							if(id == Gtk.ResponseType.YES) {
								save_file(file,dialog.get_filename().split("/"));
							}
							dialog.destroy();
						});
						confirm_dialog.run();
					});
					dialog.response.connect((id) => {
						if(id==2){dialog.destroy(); return;}
						save_file(file,dialog.get_filename().split("/"));
						dialog.destroy();
					});
					dialog.run();
					break;
				}
			}			
		}
		
		private void menu_file_close() {
			foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					if(file.modified) {
						Gtk.MessageDialog dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO,_("The file has unsaved changes, close anyway?"));
						dialog.response.connect((response) => {
							dialog.destroy();
							if(response == Gtk.ResponseType.YES) {
								close_file(file);
							} else {
								return; // Do nothing
							}
						});
						dialog.run();
					} else {
						close_file(file);
					}
					break;
				}
			}		
		}
		
		// Find etc.
	
		private void menu_edit_find() {
			/** @TODO turn to GTK3
        */
			/*
			if(current_file() == null) return;
			Gtk.Dialog find_dialog = new Gtk.Dialog.with_buttons(_("Find"),main_window,Gtk.DialogFlags.DESTROY_WITH_PARENT,Gtk.Stock.FIND,-1,Gtk.Stock.CLOSE,-2,null);
			Gtk.HBox query_box = new Gtk.HBox(false,0);
			Gtk.Label query_label = new Gtk.Label(_("Query:"));
			Gtk.Entry query = new Gtk.Entry();
			query_box.pack_start(query_label,false,false,0);
			query_box.pack_start(query,false,false,0);
		
			Gtk.CheckButton case_insensitive = new Gtk.CheckButton.with_label(_("Case-insensitive"));
			Gtk.CheckButton search_backwards = new Gtk.CheckButton.with_label(_("Search backwards"));
		
			find_dialog.vbox.pack_start(query_box,false,false,0);
			find_dialog.vbox.pack_start(case_insensitive,false,false,0);
			find_dialog.vbox.pack_start(search_backwards,false,false,0);
		
			find_dialog.response.connect((id) => {
				if(id == -1) {
					Gtk.TextIter cursor_pos_iter;
					bool found = false;
					
					current_file().buffer.get_iter_at_offset(out cursor_pos_iter,current_file().buffer.cursor_position);
					
					Gtk.TextIter match_start;
					Gtk.TextIter match_end;
					
					if(search_backwards.active) {
						found = Gtk.source_iter_backward_search(cursor_pos_iter,query.text,(case_insensitive.active ? Gtk.SourceSearchFlags.CASE_INSENSITIVE : 0),out match_start,out match_end,null);
					} else {
						found = Gtk.source_iter_forward_search(cursor_pos_iter,query.text,(case_insensitive.active ? Gtk.SourceSearchFlags.CASE_INSENSITIVE : 0),out match_start,out match_end,null);
					}
					if(found) {
						current_file().view.scroll_to_iter(match_start,0,false,0,0);
						if(search_backwards.active) {
							current_file().buffer.place_cursor(match_start);
						} else {
							current_file().buffer.place_cursor(match_end);
						}
						current_file().view.grab_focus();
						//current_file().buffer.select_range(match_start,match_end);
					} else {
						Gtk.MessageDialog dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.INFO,Gtk.ButtonsType.OK,_("No matches were found."));
						dialog.response.connect(()=>{dialog.destroy();});
						dialog.run();
					}
				} else {
					find_dialog.destroy();
				}
			});
			find_dialog.show_all(); */
		}
				private void on_execute_clicked () {
				/** @TODO load preferences for povray
        */
        /* Now : you must load file (or write it), befor starting povray 
        *				test if file is unsaved (save it), 
        */
				foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print(file.filepath+"\n");
					if(file.filepath.strip().length == 0) {
					Gtk.FileChooserDialog dialog = new Gtk.FileChooserDialog(_("Choose a file name"),main_window,
																																	Gtk.FileChooserAction.SAVE,Gtk.Stock.SAVE,
																																	1,Gtk.Stock.CANCEL,2,null);
						dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
						dialog.file_activated.connect(() => {
						Gtk.MessageDialog  confirm_dialog = new Gtk.MessageDialog(main_window,Gtk.DialogFlags.MODAL,
																																			Gtk.MessageType.WARNING,
																																			Gtk.ButtonsType.YES_NO,
																																			_("That file alreadly exists. Overwrite?"));
																															
							confirm_dialog.response.connect((id) => {
							confirm_dialog.destroy();
								if(id == Gtk.ResponseType.YES && dialog.get_filename() != null) {
									save_file(file,dialog.get_filename().split("/"));
								}
								dialog.destroy();
							});
							confirm_dialog.run();
						});
						dialog.response.connect((id) => {
							if(id==2){dialog.destroy(); return;}
							string[] raw_path = dialog.get_filename().split("/");
							string path = string.joinv("/",raw_path)+"/";
							print (path);
						});
						dialog.run();
					} else { 
				string povray="povray ";
				string opt=" +H600 +V400";
				string filename=file.filename ;
				string path=file.filepath ;
				print (filename+"\n");
				print (path+"\n");
						string runme=povray+path+filename+opt;
						try {
	        Process.spawn_command_line_async (runme);
	       }
	       catch (Error e) {
         stderr.printf ("Could not load UI: %s\n", e.message);
         }	            
					}
					break;
				}
			}	
        
	} 
	}

	
	public class File {
		public string filename;
		public string filepath;
		public Gtk.Label label;
		public Gtk.SourceView view;
		public Gtk.SourceBuffer buffer;
		public Gtk.ScrolledWindow scroll;
		public bool modified = false;
		public string unchanged_text = "";
		
		public File(string filename,string filepath) throws Error {
			this.filename = filename;
			this.filepath = filepath;
			
			label  = new Gtk.Label(filename);
			buffer = new Gtk.SourceBuffer(new Gtk.TextTagTable());
			view   = new Gtk.SourceView.with_buffer(buffer);
			scroll = new Gtk.ScrolledWindow(null,null);
			scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
			scroll.add(view);
			
			if(filepath.length > 0) {
				string file;
				bool result_uncertain;
				FileUtils.get_contents(filepath+filename,out file);
				string mimetype = g_content_type_guess(filepath+filename,(uchar[])file.to_utf8(),out result_uncertain);
				buffer.language = Gtk.SourceLanguageManager.get_default().guess_language(filepath+filename,(result_uncertain ? null : mimetype));
				buffer.begin_not_undoable_action();
				if(!file.validate()) {
					throw new UTF8Error.INVALID("Invalid encoding");
				}
				buffer.text = file;
				buffer.end_not_undoable_action();
			}
			buffer.changed.connect(() => {
				if(buffer.text == unchanged_text) {
					label.label = this.filename;
					modified    = false;
				}
				if(!modified) {
					unchanged_text = buffer.text;
					modified = true;
					label.set_markup("<b>* "+this.filename+"</b>");
				}
				gui.update_title();
			});
			view.move_cursor.connect((step,count) => {gui.update_title();});
			
		}
	}
	
	private class FileLabel {
		public Gtk.HBox hbox;
		private Gtk.Label label;
		private Gtk.Button button;
		private File file;
		
		public FileLabel(File file) {
			this.file = file;
			label = file.label;
			label.set_alignment((float)0.0,(float)0.5);
			label.set_padding(0,0);
			
			hbox = new Gtk.HBox(false,0);
			
			// ITF: we copy gedit
			button = new Gtk.Button();
			button.image = new Gtk.Image.from_stock(Gtk.Stock.CLOSE,Gtk.IconSize.MENU);
			button.relief = Gtk.ReliefStyle.NONE;
			button.image_position = Gtk.PositionType.TOP|Gtk.PositionType.LEFT;
			button.focus_on_click = false;
			Gtk.RcStyle style = new Gtk.RcStyle();
			style.xthickness = style.ythickness = 0;
			int w;
			int h;
			Gtk.icon_size_lookup_for_settings(button.get_settings(),Gtk.IconSize.MENU,out w,out h);
			w += 2;
			h += 2;
			button.set_size_request(w,h);
			
			button.modify_style(style);
			button.clicked.connect(() => {
				if(file.modified) {
					Gtk.MessageDialog dialog = new Gtk.MessageDialog(gui.main_window,Gtk.DialogFlags.MODAL,Gtk.MessageType.WARNING,Gtk.ButtonsType.YES_NO,_("The file has unsaved changes, close anyway?"));
					dialog.response.connect((response) => {
						dialog.destroy();
						if(response == Gtk.ResponseType.YES) {
							gui.close_file(file);
						} else {
							return; // Do nothing
						}
					});
					dialog.run();
				} else {
					gui.close_file(file);
				}
			});
			hbox.pack_start(label,false,false,0);
			hbox.pack_start(button,false,false,0);
			hbox.show_all();
		}
	}
	
	void main(string[] args) {
		Intl.bindtextdomain(APPNAME,LOCALEDIR);
		Intl.bind_textdomain_codeset(APPNAME,"UTF-8");
		Intl.textdomain(APPNAME);
		Gtk.init(ref args);
		gui = new GUI(args);
		
		Gtk.main();
	}
}
