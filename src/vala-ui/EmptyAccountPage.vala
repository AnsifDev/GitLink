using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/empty_account_page.ui")]
    class EmptyAccountPage: Adw.NavigationPage {
        private Window parent_window;

        public EmptyAccountPage(Window parent_window) {
            this.parent_window = parent_window;
        }

        [GtkCallback]
        public void login() {
            var login = new LoginWindow(parent_window);
            login.authenticated.connect((user) => { 
                var client = Git.Client.get_default();
                var local_users = client.load_local_users();
                var home_page = new HomePage(local_users);
                home_page.push_page.connect (parent_window.push);
                home_page.close_page.connect (parent_window.pop);
                parent_window.push(home_page); 
                var user_page = new UserPage(user);
                parent_window.push(user_page); 
            });
            login.present();
        }
    }
}