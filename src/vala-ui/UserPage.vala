using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/user_page.ui")]
    public class UserPage: Adw.NavigationPage {
        private Git.User user;
        private Window parent_window;
        private bool _allow_multi_user = false;
        private bool app_mode_lab = false;
        private ReposListModel repos_list_model;
        private ArrayList<Git.Repository> local_repos;

        public string username { get; private set; }
        public string email { get; private set; }
        public string followers_str { get; private set; }
        public string following_str { get; private set; }
        public string url { get; private set; }
        public bool allow_multi_user {
            get { return _allow_multi_user; }
            set {
                _allow_multi_user = value;
                can_pop = app_mode_lab || allow_multi_user;
                logout_banner.revealed = user.token != null && app_mode_lab;
            }
        }

        [GtkChild]
        private unowned ListBox dw_repo_list;

        [GtkChild]
        private unowned Adw.PreferencesGroup downloaded;

        [GtkChild]
        private unowned Adw.StatusPage empty_repos;

        [GtkChild]
        private unowned Adw.Banner logout_banner;

        public UserPage(Window parent_window, Git.User user) {
            this.user = user;
            this.parent_window = parent_window;
            title = user.name;
            username = user.username;
            url = user.url;
            email = user.email;
            followers_str = @"$(user.followers) Followers";
            following_str = @"$(user.following) Following";

            try { load_repositories(); }
            catch (Error e) { print(@"ERR: $(e.message)\n"); }

            var settings = new GLib.Settings("com.asiet.lab.GitLink");
            app_mode_lab = settings.get_string("app-mode") == "lab-system";
            settings.bind("allow-multiple-users", this, "allow_multi_user", GLib.SettingsBindFlags.GET);
        }

        private void load_repositories() throws Error {
            var client = Git.Client.get_default();

            local_repos = client.load_local_repositories(user);
            repos_list_model = new ReposListModel(local_repos);
            dw_repo_list.bind_model(repos_list_model, (item) => item as Widget);
            downloaded.visible = local_repos.size > 0;

            dw_repo_list.row_activated.connect((row) => {
                var repos_row = row as ReposRow;
                var dg = new RepoDetailsDialog (repos_row.repo);
                dg.clone_complete.connect(() => {
                    local_repos.add(repos_row.repo);
                    repos_list_model.notify_data_set_changed();
                    if (local_repos.size == 1) downloaded.visible = true;
                });
                dg.wipe_complete.connect(() => {
                    local_repos.remove(repos_row.repo);
                    repos_list_model.notify_data_set_changed();
                    if (local_repos.size == 0) downloaded.visible = false;
                });
                dg.present (this);
            });

            client.load_repositories.begin(user);
        }

        public signal void logged_out();
        
        [GtkCallback]
        public void preferences() {
            new PreferencesDialog().present(parent_window);
        }

        [GtkCallback]
        public void logout() {
            var logout_dg = new LogoutDialog(user);
            logout_dg.present(this);
            logout_dg.response.connect((response) => {
                if (response == "logout") {
                    if (logout_dg.logout) Git.revoke_token(user);
                    if (logout_dg.wipe) {
                        Git.Client.get_default().wipe_user(user);
                        logged_out();
                    }
                }
            });
        }

        [GtkCallback]
        public void clone_repo() {
            var dialog = new RepoCloneDialog(this.user);
            dialog.clone_complete.connect((repo) => {
                local_repos.add(repo);
                repos_list_model.notify_data_set_changed();
                if (local_repos.size == 1) downloaded.visible = true;
            });
            dialog.wipe_complete.connect((repo) => {
                local_repos.remove(repo);
                repos_list_model.notify_data_set_changed();
                if (local_repos.size == 0) downloaded.visible = false;
            });

            dialog.present(this);
        }

        [GtkCallback]
        public void open_web() {
            new UriLauncher(url).launch.begin(Application.get_default().active_window, null);
        }
    }
}