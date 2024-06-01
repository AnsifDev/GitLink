using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/login_window.ui")]
    public class LoginWindow : Adw.Dialog {
        [GtkChild]
        private unowned Adw.NavigationView nav_view;

        public signal void authenticated(Git.User user);

        public void push(Adw.NavigationPage page) { nav_view.push(page); }

        public bool pop() { return nav_view.pop(); }

        public void show_error(string description, string heading = "Error", bool close_window = true) {
            var msg = new Adw.AlertDialog(heading, description);
            msg.add_response("ok", "OK");
            msg.present(this);

            msg.response.connect(() => {
                if (close_window) close();
            });
        }
        
        public LoginWindow(Window parent) {
            push(new AuthenticationPage(this));
        }
    }
}