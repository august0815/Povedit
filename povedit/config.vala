using Gee;
namespace PovEdit {
	public class ConfigManager : Object {
		public HashMap<string,HashMap<string,string>> config = new HashMap<string,HashMap<string,string>>();
		
		// INI-ish thing
		public static HashMap<string,HashMap<string,string>> parse_file(string fname,HashMap<string,HashMap<string,string>>? existing_hash = null) {
			string raw_file;
			try {
				FileUtils.get_contents(fname,out raw_file,null);
			} catch(Error e) {
				raw_file = "";
			}
			string[] split_file = raw_file.split("\n");
			string section = "core"; // A default so things don't choke
			HashMap<string,HashMap<string,string>> result;
			if(existing_hash != null) {
				result = existing_hash;
			} else {
				result = new HashMap<string,HashMap<string,string>>();
				result["core"] = new HashMap<string,string>();
			}
			
			foreach(string raw_pair in split_file) {
				if(Regex.match_simple("^\\[[a-zA-Z]+\\]$",raw_pair)) {
					section = raw_pair[1:raw_pair.len()-1];
					if(!(section in result))
						result[section] = new HashMap<string,string>();
				} else if(!raw_pair.has_prefix(";") && Regex.match_simple("^.+=.+$",raw_pair)) { // Simple comments, INI-style
					string key;
					string val;
					key = raw_pair.split("=")[0];
					val = raw_pair.substring(key.len()+1).strip();
					key = key.strip();
					result[section][key] = val;
				}
			}
			return result;
		}
		
		public ConfigManager() {
			config["core"] = new HashMap<string,string>();
			config["core"]["auto_indent"] = "true";
			config["core"]["highlight_current_line"] = "true";
			config["core"]["indent_width"] = "4";
			config["core"]["indent_with_tabs"] = "true";
			config["core"]["show_line_numbers"] = "true";
			config["core"]["show_right_margin"] = "false";
			config["core"]["right_margin_position"] = "80";
			config["core"]["font"] = "Monospace 12";
			config["core"]["color_scheme"] = "Oblivion";
			if(FileUtils.test(Environment.get_home_dir()+"/.poveditrc",FileTest.EXISTS)) {
				parse_file(Environment.get_home_dir()+"/.poveditrc",config);
			}
			foreach(string section in config.keys) {
				print("["+section+"]\n");
				foreach(string key in config[section].keys) {
					print("\t"+key+" = "+config[section][key]+"\n");
				}
			}
		}
		
		public void save_data() {
			string output = "";
			foreach(string section in config.keys) {
				output += "["+section+"]\n";
				foreach(string key in config[section].keys) {
					output += key+" = "+config[section][key]+"\n";
				}
			}
			try {
				FileUtils.set_contents(Environment.get_home_dir()+"/.poveditrc",output);
			} catch(Error e) {
				
			}
		}
	}
}
