using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repo_remove_alert.ui")]
    class RepoRemoveAlert: Adw.AlertDialog {
        private Git.Repository repo;

        public bool cloned { get; set; }
        public bool save_changes { get; set; }
        public bool local_remove_permitted { get; set; default = true; }
        public bool remove_locally { get; set; }
        public bool remove_globally { get; set; }
        public bool save_permitted { get; set; }

        public RepoRemoveAlert(Git.Repository repo) {
            this.repo = repo;
            body = @"You are going to remove $(repo.full_name)";

            cloned = repo.local_url != null;
            if (cloned) remove_locally = true;
            else remove_globally = true;

            notify.connect(() => {
                local_remove_permitted = !remove_globally;
                if (remove_globally && cloned) remove_locally = true;
                set_response_appearance ("wipe", remove_globally? Adw.ResponseAppearance.DESTRUCTIVE: Adw.ResponseAppearance.DEFAULT);
                set_response_enabled ("wipe", remove_locally || remove_globally);
            });

            add_response ("cancel", "Cancel");
            add_response ("wipe", "Wipe Repository");
        }

        public override void response (string response) {
            if (response == "wipe") {
                var process_mgr = Application.get_default().process_manager;

                var process = new Process(@"$(repo.id)-wipe", @"Wiping Repository: $(repo.full_name)");
                process_mgr.add(process);
    
                wipe.begin(() => process.completed());
            }
        }

        private async void wipe() {
            if (cloned) {
                if (save_changes) {
                    var process_mgr = Application.get_default().process_manager;

                    var process = new Process(@"$(repo.id)-updload", @"Uploading Repository: $(repo.full_name)");
                    process_mgr.add(process);

                    if (!yield repo.upload((status, progress) => {
                        print("[UPLOAD] %s\n", status);
                        process.status = status == "Uploading..."? status: "Preparing...";
                        process.progress = progress;
                    })) {
                        var dg = new Adw.AlertDialog("Upload Failed", "Due to unexpected errors the uploading process failed. Please retry after sometime");
                        dg.add_response("ok", "OK");
                        dg.present(this);
                    }

                    process.completed();
                }

                repo.wipe();
            }

            wipe_complete ();
        }

        public signal void wipe_complete();
    }
}