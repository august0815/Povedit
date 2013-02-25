
using Gtk;
using Gee;
namespace  PovEdit {
public class PreferencesDialog : Dialog {         
   // private Entry search_entry ;
    private CheckButton auto_indent;
    private SpinButton indentation_width;
    private Widget find_button;
    private HBox idwidth_hbox;
		private CheckButton tabs_over_spaces;
		private CheckButton show_line_numbers;
		private CheckButton highlight_current_line;
		private CheckButton highlight_matching_brackets;
		private CheckButton show_right_margin;
		private HBox rmar_hbox;
		private SpinButton right_margin_column;
		private Label font_label;
		private FontButton font;
		private Label scheme_label;
		private ComboBoxText scheme_box;
		private SList<string> names_list = new SList<string>();
  
    public PreferencesDialog () {
        this.title = "Preferences";
        this.border_width = 5;
        set_default_size (300, 800);
        //string test= gui.config["core"]["font"]+"\n";
        //print (test);
        create_widgets ();
        connect_signals ();
    }

    private void create_widgets () {

        // Create and setup widgets
        this.auto_indent = new CheckButton.with_mnemonic ("_Auto-indent");
        
        this.idwidth_hbox = new HBox(false,0);
       	this.indentation_width = new SpinButton.with_range(0,100,1);
       	idwidth_hbox.pack_start(indentation_width,false,true,0);
				Label idwidth_label = new Label("Indentation width");
				idwidth_hbox.pack_start(idwidth_label,false,true,0);

				this.tabs_over_spaces = new CheckButton.with_label ("Insert tabs instead of spaces");
				this.show_line_numbers = new CheckButton.with_label("Show line numbers");
				this.highlight_current_line = new CheckButton.with_label("Highlight current line");
				this.highlight_matching_brackets = new CheckButton.with_label("Highlight matching brackets");
				this.show_right_margin = new CheckButton.with_label("Show right margin");
				
				this.rmar_hbox = new HBox(false,0);
				this.right_margin_column = new SpinButton.with_range(0,100,1);
				rmar_hbox.pack_start(right_margin_column,false,true,0);
				Label rmar_label = new Label("Right margin column");
				rmar_hbox.pack_start(rmar_label,false,true,0);
				
				this.font_label = new Label("Font:");
				
				this.font = new FontButton.with_font("Monospace 12");
			
				this.scheme_label = new Label("Color scheme:");
				//string text ="TESTTEST";
				this.scheme_box = new ComboBoxText();
				
				
				foreach(string id in SourceStyleSchemeManager.get_default().get_scheme_ids()) {
					names_list.append(SourceStyleSchemeManager.get_default().get_scheme(id).get_name());
					scheme_box.append_text(SourceStyleSchemeManager.get_default().get_scheme(id).get_name());
				} 
        // Layout widgets
        var hbox = new Box (Orientation.HORIZONTAL, 20);
        
        var content = get_content_area () as Box;
        content.pack_start (hbox, false, true, 0);
        content.pack_start (this.auto_indent, false, true, 0);
        content.pack_start (this.idwidth_hbox, false, true, 0);
        content.pack_start (this.tabs_over_spaces, false, true, 0);
        content.pack_start (this.show_line_numbers, false, true, 0);
        content.pack_start (this.highlight_current_line, false, true, 0);
        content.pack_start (this.highlight_matching_brackets, false, true, 0);
        content.pack_start (this.show_right_margin, false, true, 0);
        content.pack_start (this.rmar_hbox, false, true, 0);
        content.pack_start(this.font_label,false,true,0);
        content.pack_start(this.font,false,true,1);
        content.pack_start(this.scheme_label,false,true,0);
        content.pack_start(this.scheme_box,false,true,0);
        content.spacing = 10;

        // Add buttons to button area at the bottom
        add_button (Stock.CANCEL, ResponseType.CANCEL);
        this.find_button = add_button (Stock.APPLY, ResponseType.APPLY);
        this.find_button.sensitive = true;

        show_all ();
        
      	auto_indent.active                 = true;
				indentation_width.value            = 4;
				tabs_over_spaces.active            = true;
				show_line_numbers.active           = true;
				highlight_current_line.active      = true;
				highlight_matching_brackets.active = true;
				show_right_margin.active           = true;
				right_margin_column.value          = 80;
			/*	int i = 0;
				foreach(string name in names_list) {
					if(name == gui.config["core"]["color_scheme"]) {
						scheme_box.active = i;
						break;
					}
					i++;
				}*/
				
				//print (gui.config["core"]["indent_width"]);
    }
    

    private void connect_signals () {
       // this.search_entry.changed.connect (() => {
       //     this.find_button.sensitive = (this.search_entry.text != "");
       // });
        this.response.connect (on_response);
    }

    private void on_response (Dialog source, int response_id) {
        switch (response_id) {
       //case ResponseType.HELP:
            // show_help ();
       //     break;
        case ResponseType.APPLY:
            on_find_clicked ();
            destroy();
            break;
        case ResponseType.CANCEL:
            destroy ();
            break;
        }
    }
        private void on_find_clicked () {
   
					/*	gui.config["core"]["auto_indent"]       = auto_indent.active ? "true" : "false";
						gui.config["core"]["indent_width"]      = indentation_width.value.to_string();
						gui.config["core"]["indent_with_tabs"]  = tabs_over_spaces.active ? "true" : "false";
						gui.config["core"]["show_line_numbers"] = show_line_numbers.active ? "true" : "false";
						gui.config["core"]["highlight_current_line"] = highlight_current_line.active ? "true" : "false";
						gui.config["core"]["highlight_matching_brackets"] = highlight_matching_brackets.active ? "true" : "false";
						gui.config["core"]["show_right_margin"] = show_right_margin.active ? "true" : "false";
						gui.config["core"]["font"] = font.font_name;
						gui.config["core"]["color_scheme"] = names_list.nth_data(scheme_box.active);*/
						//gui.config_manager.save_data();
						//gui.apply_settings();
					
    }
    
 }
}  
