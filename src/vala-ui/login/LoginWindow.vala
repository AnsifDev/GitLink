using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/login_window.ui")]
    public class LoginWindow : Adw.Window {
        [GtkChild]
        private unowned Adw.NavigationView nav_view;

        public signal void authenticated(Git.User user);
        
        public LoginWindow(Window parent) {
            transient_for = parent;
            modal = true;

            var auth_page = new AuthenticationPage();
            auth_page.authorized.connect ((user) => {
                var user_config_page = new UserConfigPage (user, this);
                user_config_page.confirmed.connect (() => authenticated (user));
                nav_view.push(user_config_page);
            });
            nav_view.push(auth_page);
        }
    }
}