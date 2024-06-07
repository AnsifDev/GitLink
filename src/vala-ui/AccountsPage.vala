using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/accounts_page.ui")]
    class AccountsPage: Adw.NavigationPage {
        [GtkChild]
        private unowned ListBox list_box;

        private AccountsListModel model;
        private Window parent_window;
        private ArrayList<Git.User> local_users;
        private GLib.Settings settings;

        public bool connected { get; set; }
        public bool app_mode_lab { get; set; }
        public bool empty_accounts { get; set; }

        public AccountsPage(Window parent_window) {
            this.parent_window = parent_window;

            settings = new GLib.Settings("com.asiet.lab.GitLink");
            app_mode_lab = settings.get_string("app-mode") == "lab-system";

            var app = Application.get_default();
            if (app_mode_lab) app.connection_manager.connect_to_server.begin();
            app.connection_manager.bind_property("client_active", this, "connected", GLib.BindingFlags.SYNC_CREATE);

            var client = Git.Client.get_default();
            local_users = client.load_local_users();

            model = new AccountsListModel(local_users);
            list_box.bind_model (model, (obj) => obj as Widget);

            list_box.row_activated.connect((obj, row) => {
                //  view_account(model.get_data_for_row(row) as HashMap<string, Value?>);
                var user = model.get_data_for_row(row);
                var user_page = new UserPage(parent_window, user);
                user_page.logged_out.connect(() => on_logout(user));
                parent_window.nav_view.push(user_page);
            });
        }

        private void on_logout(Git.User user) { 
            local_users.remove(user);
            parent_window.nav_view.pop(); 
        }

        public override void shown() {
            model.notify_data_set_changed();
            empty_accounts = local_users.size == 0;
            var allow_multi_user = settings.get_boolean("allow-multiple-users");
            if (!empty_accounts) {
                //  list_box.select_row (model.get_item (0) as ListBoxRow);
                var row = model.get_item (0) as ListBoxRow;
                row.grab_focus();
                var user = local_users[0];
                var user_page = new UserPage(parent_window, local_users[0]);
                user_page.logged_out.connect(() => on_logout(user));
                if (!app_mode_lab && !allow_multi_user) parent_window.nav_view.push(user_page);
            }
            
        }

        [GtkCallback]
        public void connect_to_server() { 
            var app = Application.get_default();
            app.connection_manager.connect_to_server.begin((src, res) => {
                var sucess = app.connection_manager.connect_to_server.end(res);
                if (sucess) return;

                var settings = new GLib.Settings("com.asiet.lab.GitLink");
                var msg = new Adw.AlertDialog("Server Connection Failed", @"Connection to the server $(settings.get_string("host-ip")) is failing. This can be due to the server may not running the GitLink App or may not turned the hotspot on. Please turn hotspot on to initialize the server system.");
                msg.add_response("ok", "OK");
                msg.present(parent_window);
            }); 
        }

        [GtkCallback]
        public void login() {
            var login = new LoginWindow(parent_window);
            login.authenticated.connect((user) => { 
                local_users.add(user);
                Git.Client.get_default().set_as_local_user(user);
                var user_page = new UserPage(parent_window, user);
                user_page.logged_out.connect(() => on_logout(user));
                parent_window.nav_view.push(user_page); 
            });
            login.present(this);
        }
        
        [GtkCallback]
        public void preferences() {
            new PreferencesDialog().present(parent_window);
        }
    }
}