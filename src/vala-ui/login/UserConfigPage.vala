using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/user_config_page.ui")]
    public class UserConfigPage : Adw.NavigationPage {
        public string? user_code { get; private set; default = "OCSD-12DE"; }
        public string username { get; internal set; default = ""; }
        public string display_name { get; internal set; default = ""; }
        public string email { get; internal set; default = ""; }
        public string ssh_name { get; internal set; default = ""; }
        public string ssh_pass { get; internal set; default = ""; }
        public bool ssh_name_ok { get; internal set; default = false; }
        public bool ssh_pass_ok { get; internal set; default = false; }
        public bool ssh_pass_confirm { get; internal set; default = false; }
        public bool user_name_ok { get; internal set; default = true; }
        public bool user_email_ok { get; internal set; default = true; }

        private Git.User user;
        private Gtk.Window window;
        
        public UserConfigPage(Git.User user, Gtk.Window window) {
            this.user = user;
            this.window = window;
            
            user.bind_property("username", this, "username", GLib.BindingFlags.SYNC_CREATE, null, null);
            user.bind_property("name", this, "display_name", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);
            user.bind_property("email", this, "email", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.BIDIRECTIONAL, null, null);
        }

        public signal void confirmed();

        [GtkCallback]
        private void show_error(Gtk.Widget src) {
            var msg = new Adw.MessageDialog(window, "Error", src.tooltip_text);
            msg.add_response("ok", "OK");
            msg.present();
        }
    }
}