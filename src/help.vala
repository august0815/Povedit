/* help.vala
 *
 * Copyright (C) 
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	
 */

/**
 * The  help box 
 */
using Gtk;

public class HelpDialog : Window {
    private TextView text_view;
    
    public HelpDialog () {
        this.title = "HELP";
        this.border_width = 5;
        set_default_size (800, 600);
        create_widgets ();
        
    }

    private void create_widgets () {
        this.window_position = WindowPosition.CENTER;
        
        var toolbar = new Toolbar ();
        toolbar.get_style_context ().add_class (STYLE_CLASS_PRIMARY_TOOLBAR);

        var close_button = new ToolButton.from_stock (Stock.CLOSE);
        close_button.is_important = true;
        toolbar.add (close_button);
        close_button.clicked.connect (on_close_clicked);

        this.text_view = new TextView ();
        this.text_view.editable = false;
        this.text_view.cursor_visible = false;

        var scroll = new ScrolledWindow (null, null);
        scroll.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        scroll.add (this.text_view);

        var vbox = new Box (Orientation.VERTICAL, 0);
        vbox.pack_start (toolbar, false, true, 0);
        vbox.pack_start (scroll, true, true, 0);
        add (vbox);
        /** @TODO Relativen Pfad einpflegen
             */         
         try {
            string text;
           // string filename="/home/mario/Desktop/DATEN/VALA/SLOC1/sloc5/HELP";
           // FileUtils.get_contents (filename, out text);
            //stdout.printf(text);
            text="<i>cool</i><big>cool</big>\n<tt>cool</tt><i>cool</i>·\n<b>cool</b> ";
            this.text_view.buffer.text = text;
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
        show_all ();
       
    }
    private void on_close_clicked () {
        destroy ();
        string text="CLOSE CLOSE" ;
        this.text_view.buffer.text =  text;
        
    }
    //dialog.run();
     
}


