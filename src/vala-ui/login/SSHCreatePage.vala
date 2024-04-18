using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/ssh_config_page.ui")]
    public class SSHCreatePage : Adw.NavigationPage {
        public string password { get; set; }
        public string password_conf { get; set; }

        public SSHCreatePage() {
            
        }

        public signal void push(Adw.NavigationPage page);

        public signal bool pop();
    }
}