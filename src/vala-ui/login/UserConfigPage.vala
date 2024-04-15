using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/user_config_page.ui")]
    public class UserConfigPage : Adw.NavigationPage {
        public string? user_code { get; private set; default = "OCSD-12DE"; }
        public string username { get; internal set; default = ""; }
        public string display_name { get; internal set; default = ""; }
        public string email { get; internal set; default = ""; }
        public string ssh_key { get; internal set; default = "Not Selected"; }
        //  public string ssh_name { get; internal set; default = ""; }
        //  public string ssh_pass { get; internal set; default = ""; }
        //  public bool ssh_name_ok { get; internal set; default = false; }
        //  public bool ssh_pass_ok { get; internal set; default = false; }
        //  public bool ssh_pass_confirm { get; internal set; default = false; }
        public bool user_name_ok { get; internal set; default = true; }
        public bool user_email_ok { get; internal set; default = true; }
        public bool ssh_key_ok { get; internal set; default = false; }
        public bool ssh_key_warning { get; internal set; default = false; }
        public bool ssh_key_loading { get; internal set; default = false; }

        private Git.User user;
        private Gtk.Window window;
        
        public UserConfigPage(Git.User user, Gtk.Window window) {
            this.user = user;
            this.window = window;
            
            user.bind_property("username", this, "username", GLib.BindingFlags.SYNC_CREATE, null, null);
            user.bind_property("name", this, "display_name", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);
            user.bind_property("email", this, "email", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);

            var ssh = SSHConfiguration.load();
            if (ssh.has_key(@"$username.github.com")) {
                ssh_key = ssh[@"$username.github.com"]["IdentityFile"];
                ssh_key_ok = true;
            }

            //  Git.request.begin("user/keys", user, (src, res) => {
            //      var response_str = Git.request.end(res);
            //      user.remote_ssh_keys = new JsonEngine().parse_string_to_array(response_str);

            //      if (ssh_key_ok) {
            //          if (ssh_key[0] == '~') ssh_key = ssh_key.replace("~", Environment.get_home_dir());
            //          var file_reader = new DataInputStream(File.new_for_path(@"$ssh_key.pub").read());
            //          var key = file_reader.read_line();
            //          ssh_key_warning = true;

            //          foreach (var item in user.remote_ssh_keys) {
            //              var data_map = (HashMap<string, Value?>) item;
            //              var remote_key = data_map["key"].get_string();
            //              //  print("%s: %s\n", key, remote_key);

                        
            //              if (!(ssh_key_warning = !key.has_prefix(remote_key))) break;
            //          }
            //      }
                
            //      ssh_key_loading = false;
            //  });
        }

        public signal void confirmed();

        public signal void push(Adw.NavigationPage page);

        [GtkCallback]
        private void show_error(Gtk.Widget src) {
            var msg = new Adw.MessageDialog(window, "Error", src.tooltip_text);
            msg.add_response("ok", "OK");
            msg.present();
        }
        
        [GtkCallback]
        private void config_ssh(Gtk.Widget src) {
            var ssh_config_page = new SSHConfigPage(user);
            push(ssh_config_page);
        }
    }
}