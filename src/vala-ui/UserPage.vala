using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/user_page.ui")]
    public class UserPage: Adw.NavigationPage {
        private Git.User user;
        public string username { get; private set; }
        public string email { get; private set; }
        public string followers_str { get; private set; }
        public string following_str { get; private set; }
        public string url { get; private set; }

        [GtkChild]
        private unowned ListBox dw_repo_list;

        //  [GtkChild]
        //  private unowned ListBox remote_repo_list;

        [GtkChild]
        private unowned Adw.PreferencesGroup downloaded;

        //  [GtkChild]
        //  private unowned Adw.PreferencesGroup remote_repos;

        //  [GtkChild]
        //  private unowned Button btn_create_new;

        [GtkChild]
        private unowned Adw.StatusPage empty_repos;

        //  [GtkChild]
        //  private unowned Adw.StatusPage data_fetch_error;

        [GtkChild]
        private unowned Adw.Banner logout_banner;

        public UserPage(Git.User user) {
            this.user = user;
            title = user.name;
            username = user.username;
            url = user.url;
            email = user.email;
            followers_str = @"$(user.followers) Followers";
            following_str = @"$(user.following) Following";

            logout_banner.revealed = user.token != null;
            //  client.get_authenticated_user.begin((src, result) => {
            //      var auth_user = client.get_authenticated_user.end(result);
            //      if (auth_user != null) auth_user.username == username;
            //  });

            try { load_repositories(); }
            catch (Error e) { print(@"ERR: $(e.message)\n"); }
        }

        private void load_repositories() throws Error {
            var client = Git.Client.get_default();

            var local_repos = client.load_local_repositories(user);
            //  var local_repos = new ArrayList<Git.Repository>();
            //  var remote_repositories = new ArrayList<Git.Repository>();
            if (local_repos.size > 0) {
                downloaded.visible = true;
                dw_repo_list.bind_model(new ReposListModel(local_repos), (item) => item as Widget);
            } else empty_repos.visible = true;

            client.load_repositories.begin(user);

            //  client.load_repositories.begin(user, (src, result) => {
            //      var remote_repositories = client.load_repositories.end(result);
            //      if (remote_repositories == null) {
            //          data_fetch_error.visible = true;
            //          return;
            //      }
 
            //      //  foreach (var repo in local_repos) remote_repositories.remove(repo);
            //      if (remote_repositories.size > 0) {
            //          remote_repos.visible = true;
            //          remote_repo_list.bind_model(new ReposListModel(remote_repositories), (item) => item as Widget);
            //      } else empty_repos.visible = true;
            //  });
        }

        [GtkCallback]
        public void preferences() {
            print("preferences\n");
        }

        [GtkCallback]
        public void logout() {
            print("logout\n");
        }

        [GtkCallback]
        public void clone_repo() {
            var dialog = new RepoCloneDialog(this.user);
            dialog.present();
        }

        [GtkCallback]
        public void open_web() {
            new UriLauncher(url).launch.begin(Application.get_default().active_window, null);
        }
    }
}