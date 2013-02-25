using Gtk;
using Gee;
namespace PovEdit {
	errordomain UTF8Error {
		INVALID
	}
	GUI gui;
	public class GUI : Window {
		public Gtk.Window main_window;
		public Gtk.MenuBar menu_bar;
		public Gtk.Notebook files_notebook;
		public LinkedList<File> files;
		public ConfigManager config_manager;
		public HashMap<string,HashMap<string,string>> config;
		//private Gtk.AccelGroup accelerators;
		private SList<Gtk.RadioMenuItem> language_radios = new SList<Gtk.RadioMenuItem>();
		private LinkedList<Gtk.SourceLanguage> languages = new LinkedList<Gtk.SourceLanguage>();
		private bool language_menu_inactive = false;
		public Gtk.RadioMenuItem none_button;
		private Gtk.MenuItem[] files_menu = new Gtk.MenuItem[8];
		private Gtk.Label info_label;
		
		public GUI() {
			// Setting up the GUI
			//accelerators = new Gtk.AccelGroup();
			main_window = new Gtk.Window(Gtk.WindowType.TOPLEVEL);
			main_window.title = "PovEdit";
			main_window.set_size_request(1000,940);
			main_window.destroy.connect(Gtk.main_quit);
			//main_window.add_accel_group(accelerators);
			
			var main_vbox = new VBox(false,0);
			main_window.add(main_vbox);

			 var toolbar = new Toolbar ();
        toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);

        var new_button = new ToolButton.from_stock (Stock.NEW);
        new_button.is_important = true;
        toolbar.add (new_button);
        new_button.clicked.connect (on_new_clicked);
        
        var open_button = new ToolButton.from_stock (Stock.OPEN);
        open_button.is_important = true;
        toolbar.add (open_button);
        open_button.clicked.connect (on_open_clicked);
				
				var save_button = new ToolButton.from_stock (Stock.SAVE);
        save_button.is_important = true;
        toolbar.add (save_button);
        save_button.clicked.connect (on_save_clicked);
        
        var save_as_button = new ToolButton.from_stock (Stock.SAVE_AS);
        save_as_button.is_important = true;
        toolbar.add (save_as_button);
        save_as_button.clicked.connect (on_save_as_clicked);
        
        var close_button = new ToolButton.from_stock (Stock.CLOSE);
        close_button.is_important = true;
        toolbar.add (close_button);
        close_button.clicked.connect (on_close_clicked);
        
        var preferences_button = new ToolButton.from_stock (Stock.PREFERENCES);
        preferences_button.is_important = true;
        toolbar.add (preferences_button);
        preferences_button.clicked.connect (on_preferences_clicked);
        
        var execute_button = new ToolButton.from_stock (Stock.EXECUTE);
        execute_button.is_important = true;
        toolbar.add (execute_button);
        execute_button.clicked.connect (on_execute_clicked);
        
        var help_button = new ToolButton.from_stock (Stock.HELP);
        help_button.is_important = true;
        toolbar.add (help_button);        
        help_button.clicked.connect (on_help_clicked);
        
        var about_button = new ToolButton.from_stock (Stock.ABOUT);
        about_button.is_important = true;
        toolbar.add (about_button);
        about_button.clicked.connect (on_about_clicked);
        
        var quit_button = new ToolButton.from_stock (Stock.QUIT);
        quit_button.is_important = true;
        toolbar.add (quit_button);
        quit_button.clicked.connect (on_quit_clicked);
        
			files_notebook = new Gtk.Notebook();
			main_vbox.pack_start(toolbar, false, true, 0);
			main_vbox.pack_start(files_notebook,true,true,0);
			
			main_window.show_all();
			
			files = new LinkedList<File>();
			config_manager = new ConfigManager();
			config = config_manager.config;
			open_file();
		}
	
		private void on_new_clicked () {
				open_file();
				
        }
    private void on_open_clicked () {
      var dialog = new FileChooserDialog ("Open File", this,
                                      FileChooserAction.OPEN,
                                      Stock.CANCEL, ResponseType.CANCEL,
                                      Stock.OPEN, ResponseType.ACCEPT);
      dialog.set_current_folder((current_file() != null &&
      													 current_file().filepath != "" ? current_file().filepath :
      													 Environment.get_home_dir()));
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
   
    private void on_save_clicked () {
    	foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print("\""+file.filepath+"\"\n");
					if(file.filepath.strip().length == 0) {
						var dialog = new FileChooserDialog(("Choose a file name"),main_window,
																								FileChooserAction.SAVE,
																								Stock.SAVE,1,Stock.CANCEL,2,null);
						dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
						dialog.file_activated.connect(() => {
						var confirm_dialog = new MessageDialog(main_window,DialogFlags.MODAL,
																															MessageType.WARNING,
																															ButtonsType.YES_NO,
																															("That file alreadly exists. Overwrite?"));
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
    private void on_save_as_clicked () {
    foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print("\""+file.filepath+"\"\n");
					var dialog = new FileChooserDialog(("Choose a file name"),main_window,FileChooserAction.SAVE,
																							Stock.SAVE,1,Stock.CANCEL,2,null);
					dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
					dialog.file_activated.connect(() => {
						var confirm_dialog = new MessageDialog(main_window,DialogFlags.MODAL,
																									 MessageType.WARNING,ButtonsType.YES_NO,
																									 ("That file alreadly exists. Overwrite?"));
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
    
    private void on_close_clicked () {
    foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					if(file.modified) {
						var dialog = new MessageDialog(main_window,DialogFlags.MODAL,
																							MessageType.WARNING,Gtk.ButtonsType.YES_NO,
																							("The file has unsaved changes, close anyway?"));
						dialog.response.connect((response) => {
							dialog.destroy();
							if(response == ResponseType.YES) {
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
				private void on_help_clicked () {
				var dialog = new HelpDialog ();
   			dialog.show ();
        }
        
        private void on_preferences_clicked () {
        //print (config["core"]["font"]+"\n");
        var dialog = new PreferencesDialog ();
       
				dialog.show ();
        }
         
 
        
        private void on_execute_clicked () {

				foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == files_notebook.page) {
					print(file.filepath+"\n");
					if(file.filepath.strip().length == 0) {
						var dialog = new FileChooserDialog(("Choose a file name"),main_window,
																								FileChooserAction.SAVE,
																								Stock.SAVE,1,Stock.CANCEL,2,null);
						dialog.set_current_folder((file.filepath == "" ? Environment.get_home_dir() : file.filepath));
						dialog.file_activated.connect(() => {
						var confirm_dialog = new MessageDialog(main_window,DialogFlags.MODAL,
																															MessageType.WARNING,
																															ButtonsType.YES_NO,
																															("That file alreadly exists. Overwrite?"));
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
				string opt=" +H320 +V320";
				string filename=file.filename ;
				string path=file.filepath ;
				print (filename+"\n");
				print (path+"\n");
				
						string runme=povray+path+filename+opt;
						print(runme+"\n");
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
				
				        void on_async_exit (Pid pid, int status)
				{
        Process.close_pid(pid);
				}
        private void on_about_clicked () {
        var dialog = new AboutDialog();
				dialog.authors = {"<mariomarcec42@googlemail.com>","NieXS <neo dot niexs at gmail dot com>",null};
				dialog.copyright = "Copyright (c) 2011 Marcec  Mario.   All rights reserved.\nCopyright (c) 2010 Eduardo Niehues. All rights reserved.";
				dialog.license = """
Copyright (c) 2011 Marcec  Mario.   All rights reserved.
Copyright (c) 2010, Eduardo Niehues. inital commit for edit
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
				dialog.logo = new Gdk.Pixbuf.from_file (Path.build_filename ("./src", "povedit.png"));
				dialog.program_name   = "Vala POVRAY EDIT";
				dialog.version = "0.0.1";
				dialog.response.connect(() => {dialog.destroy();});
				dialog.run();
			
			}
				
        
    private void on_quit_clicked () {
    		Gtk.main_quit();
        }
		
		private bool open_file(string? name = null,string? path = null) {
			foreach(File file in files) {
				if(file.filename == name && file.filepath == path) { // Case-sensitive!
					return false; // File is already open
				}
			}
			if(name == null) {
				name = "untitled";
			}
			if(path == null) {
				path = "";
			}
			
			File file = new File(name,path);
			files.add(file);
			files_notebook.append_page(file.scroll,file.label);
			files_notebook.show_all();
			files_notebook.page = files_notebook.page_num(file.scroll);
			apply_settings();
			
			return true;
		}
		
		private void open_file_from_path(string[] _raw_path) {
			string file = _raw_path[_raw_path.length-1];
			string[] raw_path = _raw_path[0:_raw_path.length-1];
			string path = string.joinv("/",raw_path)+"/";
			print(path+"\n");
			print(file+"\n");
			open_file(file,path);
		}
		
		public void close_file(File file) {
			files_notebook.remove_page(files_notebook.page_num(file.scroll));
			files.remove(file);
			update_title();
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
				var dialog = new MessageDialog(main_window,DialogFlags.MODAL,
																			 MessageType.ERROR,ButtonsType.OK,
																			 ("Error saving file: access is denied."));
				dialog.response.connect(()=>{dialog.destroy();});
				dialog.run();
			} 
		}
		
			public File? current_file() {
			return file_at_page(files_notebook.page);
		}
		
		private File? file_at_page(int page) {
			foreach(File file in files) {
				if(files_notebook.page_num(file.scroll) == page) {
					return file;
				}
			}
			return null;
		}
		
		public void update_title(owned File? file = null,int? char_count = null) {
			if(file == null) {
				file = current_file();
			}
			if(file == null) {
				main_window.title = "VaEdit";
				none_button.active = true;
				info_label.label = "";
			} else {
				main_window.title = (file.modified ? "* " : "")+file.filename+" - "+file.filepath+" - VaEdit";
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
				//info_label.label = get_cursor_pos(current_file(),char_count);
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
		
		public void apply_settings() {
			foreach(File file in files) {
				//print("Applying\n");
				file.view.auto_indent = config["core"]["auto_indent"] == "true";
				file.view.highlight_current_line = config["core"]["highlight_current_line"] == "true";
				file.view.indent_on_tab = true;
				file.view.insert_spaces_instead_of_tabs = config["core"]["indent_with_tabs"] != "true";
				//file.view.indent_width = config["core"]["indent_width"].to_int();
				file.view.tab_width = config["core"]["indent_width"].to_int();
				file.view.show_line_numbers = config["core"]["show_line_numbers"] == "true";
				file.view.show_right_margin = config["core"]["show_right_margin"] == "true";
				file.view.right_margin_position = config["core"]["right_margin_position"].to_int();
				file.view.modify_font(Pango.FontDescription.from_string(config["core"]["font"]));
				
				Gtk.SourceStyleScheme scheme;
				
				Gtk.SourceStyleSchemeManager.get_default().prepend_search_path("/usr/share/gtksourceview-2.0/styles");
				foreach(string id in Gtk.SourceStyleSchemeManager.get_default().scheme_ids) {
					print(id+"\n");
					print(Gtk.SourceStyleSchemeManager.get_default().get_scheme(id).name+"\n");
					if(Gtk.SourceStyleSchemeManager.get_default().get_scheme(id).name == config["core"]["color_scheme"]) {
						scheme = Gtk.SourceStyleSchemeManager.get_default().get_scheme(id);
						file.buffer.style_scheme = scheme;
						break;
					}
				}
			}
		}
	}
	
	public class File {
		public string filename;
		public string filepath;
		public Label label;
		public SourceView view;
		public SourceBuffer buffer;
		public ScrolledWindow scroll;
		public bool modified = false;
		public string unchanged_text = "";
		
		public File(string filename,string filepath) throws Error {
			this.filename = filename;
			this.filepath = filepath;
			
			label  = new Label(filename);
			buffer = new SourceBuffer(new Gtk.TextTagTable());
			view   = new SourceView.with_buffer(buffer);
			scroll = new ScrolledWindow(null,null);
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
			//gui.view.move_cursor.connect((step,count) => {update_title();});
			
		}
	}
	
	void main(string[] args) {
		Gtk.init(ref args);
		GUI gui = new GUI();
		
		Gtk.main();
	}
}
