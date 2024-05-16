using Gtk, Gee;

namespace Gitlink {
    //  public class MyRemoteCallbacks: Ggit.RemoteCallbacks {
    //      public int fails_remaining { get; set; default = 10; }
    
    //      public override Ggit.Cred? credentials(string url, string? username_from_url, Ggit.Credtype allowed_types) throws Error {
    //          if (fails_remaining > 0) fails_remaining--;
    //          else throw new Error(Ggit.error_quark(), Ggit.Error.PASSTHROUGH, "Auth Failed");
    
    //          print("%s:\n  - %s\n  - (%d)\n", url, username_from_url, allowed_types);
    
    //          return new Ggit.CredSshKeyFromAgent(username_from_url);
    //      }
    //  }

    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repo_details_dialog.ui")]
    class RepoDetailsDialog: Adw.Dialog {
        private Git.Repository repo;

        public string forks { get; private set; }
        public string private_repo { get; private set; }
        public string description { get; private set; default = ""; }
        public bool cloned { get; private set; }
        public bool no_description { get; private set; }
        public bool cloning { get; private set; }
        public bool uploading { get; private set; }
        public bool downloading { get; private set; }
        public bool wiping { get; private set; }

        public RepoDetailsDialog(Git.Repository repo) {
            this.repo = repo;

            title = repo.full_name;
            forks = @"Forks: $(repo.forks)";
            private_repo = repo.private_repo? "Private": "Private";
            cloned = repo.local_url != null;
            if (repo.description != null) description = repo.description;
            no_description = description == "";
            repo.notify["local-url"].connect(() => { cloned = repo.local_url != null; });

            var app = Application.get_default();
            var process_mgr = app.process_manager;
            var clone_process = process_mgr[@"$(repo.id)-clone"];
            var upload_process = process_mgr[@"$(repo.id)-upload"];
            var download_process = process_mgr[@"$(repo.id)-download"];
            var wipe_process = process_mgr[@"$(repo.id)-wipe"];

            cloning = clone_process != null;
            uploading = upload_process != null;
            downloading = download_process != null;
            wiping = wipe_process != null;
            
            if (cloning) clone_process.completed.connect(() => cloning = false);
            if (uploading) upload_process.completed.connect(() => uploading = false);
            if (downloading) download_process.completed.connect(() => downloading = false);
            if (wiping) wipe_process.completed.connect(() => wiping = false);

            process_mgr.process_added.connect((process) => {
                if (process.id == @"$(repo.id)-clone") { cloning = true; process.completed.connect(() => cloning = false); }
                if (process.id == @"$(repo.id)-upload") { uploading = true; process.completed.connect(() => uploading = false); }
                if (process.id == @"$(repo.id)-download") { downloading = true; process.completed.connect(() => downloading = false); }
                if (process.id == @"$(repo.id)-wipe") { wiping = true; process.completed.connect(() => wiping = false); }
            });
        }

        [GtkCallback]
        public void open_web() {
            new UriLauncher(repo.url).launch.begin(Application.get_default().active_window, null);
        }

        [GtkCallback]
        public void remove_repo() {
            var dg = new RepoRemoveAlert(repo);
            dg.wipe_complete.connect(() => wipe_complete());
            dg.present(this);
        }

        [GtkCallback]
        public void open_locally() {
            var launcher = new FileLauncher(File.new_for_path(repo.local_url));
            launcher.launch.begin(Application.get_default().active_window, null);
        }

        [GtkCallback]
        public void open_with_locally() {
            var launcher = new FileLauncher(File.new_for_path(repo.local_url));
            launcher.always_ask = true;
            launcher.launch.begin(Application.get_default().active_window, null);
        }

        [GtkCallback]
        public void upload() {
            var process_mgr = Application.get_default().process_manager;

            var process = new Process(@"$(repo.id)-upload", @"Uploading Repository: $(repo.full_name)");
            process_mgr.add(process);

            repo.upload.begin((src, res) => { 
                if (!repo.upload.end(res)) {
                    var dg = new Adw.AlertDialog("Upload Failed", "Due to unexpected errors the uploading process failed. Please retry after sometime");
                    dg.add_response("ok", "OK");
                    dg.present(this);
                }

                process.completed();
            });
        }

        [GtkCallback]
        public void download() {
            var process_mgr = Application.get_default().process_manager;

            var process = new Process(@"$(repo.id)-download", @"Downloading Repository: $(repo.full_name)");
            process_mgr.add(process);

            repo.download.begin((src, res) => { 
                if (!repo.download.end(res)) {
                    var dg = new Adw.AlertDialog("Download Failed", "Due to unexpected errors the downloading process failed. Please retry after sometime");
                    dg.add_response("ok", "OK");
                    dg.present(this);
                }

                process.completed();
            });
        }

        [GtkCallback]
        public void clone_repo() {
            var process_mgr = Application.get_default().process_manager;

            var process = new Process(@"$(repo.id)-clone", @"Cloning Repository: $(repo.full_name)");
            process_mgr.add(process);

            repo.clone.begin((src, res) => {
                if (repo.clone.end(res)) clone_complete();
                else {
                    var dg = new Adw.AlertDialog("Clone Failed", "Due to unexpected errors the cloning process failed. Please retry after sometime");
                    dg.add_response("ok", "OK");
                    dg.present(this);
                }

                process.completed();
                //  process_mgr.
            });
        }

        public signal void clone_complete();

        public signal void wipe_complete();
    }
}