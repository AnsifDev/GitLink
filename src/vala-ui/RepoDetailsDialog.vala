using Gtk, Gee;

namespace Gitlink {

    public class ProcessViewRow: Adw.ActionRow {
        public bool percent_visible { get; private set; default = false; }
        public bool finished { get; private set; default = false; }
        public string percent_value { set; get; default = ""; }

        public ProcessViewRow() {
            var label = new Label("");
            bind_property("percent_value", label, "label", GLib.BindingFlags.SYNC_CREATE, null, null);
            bind_property("percent_visible", label, "visible", GLib.BindingFlags.SYNC_CREATE, null, null);
            label.margin_start = label.margin_end = 8;
            label.valign = Align.CENTER;
            add_suffix(label);

            var spinner = new Spinner();
            spinner.spinning = true;
            spinner.margin_start = spinner.margin_end = 8;
            spinner.valign = Align.CENTER;
            bind_property("finished", spinner, "visible", GLib.BindingFlags.SYNC_CREATE|GLib.BindingFlags.INVERT_BOOLEAN, null, null);
            add_prefix(spinner);

            var img = new Image.from_icon_name("check-round-outline2-symbolic");
            img.margin_start = img.margin_end = 8;
            img.valign = Align.CENTER;
            bind_property("finished", img, "visible", GLib.BindingFlags.SYNC_CREATE, null, null);
            add_prefix(img);
        }

        public void bind_process(Process process) {
            //  percent_visible = percent_value != "0%";
            finished = false;
            process.bind_property("progress", this, "percent_value", GLib.BindingFlags.SYNC_CREATE, (src, v_in, ref v_out) => {
                v_out = @"$((int) (v_in.get_float()*100))%";
                percent_visible = v_in.get_float() != 0;
                return true;
            }, null);
            process.bind_property("status", this, "subtitle", GLib.BindingFlags.SYNC_CREATE, null, null);
            process.completed.connect(() => finished = true); 
        }
    }

    public class ProcessModel: RecycleViewModel {
        private ProcessManager process_mgr = null;
        private Git.Repository? repo;
        private ArrayList<Process> data = new ArrayList<Process>();
        
        public ProcessModel(Application app, Git.Repository? associated_repo = null) {
            process_mgr = app.process_manager;
            process_mgr.process_added.connect(process_added_cb);
            repo = associated_repo;

            foreach (var process in process_mgr) process_added_cb(process);
        }

        private void process_added_cb(Process process) {
            print("%s\n", process.name);
            if (repo != null & !process.id.has_prefix(repo.id.to_string())) return;
            data.insert(0, process);
            notify_data_set_changed(0, 0, 1);
            process.completed.connect(process_removed_cb);
        }

        private void process_removed_cb(Process process) {
            Timeout.add(5000, () => {
                Idle.add(() => {
                    var index = data.index_of(process);
                    data.remove(process);
                    notify_data_set_changed(index, 0, -1);
                    return false;
                });
                return false;
            });
        }

        public override Gtk.ListBoxRow create_list_box_row() {
            return new ProcessViewRow();
        }

        public override void on_bind(int position, Gtk.ListBoxRow list_box_row) {
            var row = (ProcessViewRow) list_box_row;
            var process = data[(int) position];
            row.title = process.name;
            row.bind_process(process);
        }

        public override int get_size() {
            return data.size;
        }

    }

    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repo_details_dialog.ui")]
    class RepoDetailsDialog: Adw.Dialog {
        private Git.Repository repo;
        
        [GtkChild]
        private ListBox process_listbox;

        public string forks { get; private set; }
        public string private_repo { get; private set; }
        public string description { get; private set; default = ""; }
        public bool cloned { get; private set; }
        public bool no_description { get; private set; }
        public bool cloning { get; private set; }
        public bool uploading { get; private set; }
        public bool downloading { get; private set; }
        public bool wiping { get; private set; }
        //  public float cloning_progress { get; set; default = 0; }
        //  public float uploading_progress { get; set; default = 0; }
        //  public float downloading_progress { get; set; default = 0; }
        //  public float wiping_progress { get; set; default = 0; }
        //  public string cloning_status { get; set; default = ""; }
        //  public string uploading_status { get; set; default = ""; }
        //  public string downloading_status { get; set; default = ""; }
        //  public string wiping_status { get; set; default = ""; }

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

            string[] processes = { @"$(repo.id)-clone", @"$(repo.id)-upload", @"$(repo.id)-download", @"$(repo.id)-wipe" };
            foreach (var process_id in processes) {
                var process = process_mgr[process_id];
                if (process != null) process_added_cb(process);
            }
            
            process_mgr.process_added.connect(process_added_cb);

            process_listbox.bind_model(new ProcessModel(Application.get_default(), repo), (obj) => (Widget) obj);
        }

        //  private void process_added_cb(Process src) {
        //      if (src.id == @"$(repo.id)-clone") { 
        //          cloning = true; 
        //          src.bind_property("progress", this, "cloning_progress", GLib.BindingFlags.SYNC_CREATE, null, null);
        //          src.bind_property("status", this, "cloning_status", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //      }
        //      if (src.id == @"$(repo.id)-upload") { 
        //          uploading = true; 
        //          src.bind_property("progress", this, "uploading_progress", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //          src.bind_property("status", this, "uploading_status", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //      }
        //      if (src.id == @"$(repo.id)-download") { 
        //          downloading = true; 
        //          src.bind_property("progress", this, "downloading_progress", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //          src.bind_property("status", this, "downloading_status", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //      }
        //      if (src.id == @"$(repo.id)-wipe") { 
        //          wiping = true; 
        //          src.bind_property("progress", this, "wiping_progress", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //          src.bind_property("status", this, "wiping_status", GLib.BindingFlags.SYNC_CREATE, null, null); 
        //      }
        //      src.completed.connect(process_completed_cb);
        //  }

        private void process_added_cb (Process src) {
            if (src.id == @"$(repo.id)-clone") cloning = true;
            if (src.id == @"$(repo.id)-upload") uploading = true;
            if (src.id == @"$(repo.id)-download") downloading = true;
            if (src.id == @"$(repo.id)-wipe") wiping = true;
            src.completed.connect(process_completed_cb);
        }

        private void process_completed_cb (Process src) {
            if (src.id == @"$(repo.id)-clone") cloning = false;
            if (src.id == @"$(repo.id)-upload") uploading = false;
            if (src.id == @"$(repo.id)-download") downloading = false;
            if (src.id == @"$(repo.id)-wipe") wiping = false;
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
        //  public void upload() {
        //      var process_mgr = Application.get_default().process_manager;

        //      var process = new Process(@"$(repo.id)-upload", @"Uploading Repository: $(repo.full_name)");
        //      process_mgr.add(process);

        //      repo.upload.begin((src, res) => { 
        //          if (!repo.upload.end(res)) {
        //              var dg = new Adw.AlertDialog("Upload Failed", "Due to unexpected errors the uploading process failed. Please retry after sometime");
        //              dg.add_response("ok", "OK");
        //              dg.present(this);
        //          }

        //          process.completed();
        //      });
        //  }
        
        public void upload() {
            var process_mgr = Application.get_default().process_manager;

            var process = new Process(@"$(repo.id)-upload", @"Uploading Repository: $(repo.full_name)");
            process_mgr.add(process);

            repo.upload.begin((status, progress) => {
                print("[UPLOAD] %s\n", status);
                //  process.status = status == "Uploading..."? status: "Preparing...";
                process.status = status.escape();
                process.progress = progress;
            }, (src, res) => {
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

            repo.download.begin((status, progress) => {
                print("[DOWNLOAD] %s\n", status);
                //  process.status = status == "Uploading..."? status: "Preparing...";
                process.status = status.escape();
                process.progress = progress;
            }, (src, res) => {
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

            repo.clone.begin((status, progress) => {
                print("[CLONE] %s\n", status);
                process.status = status.escape();
                //  process.status = status == "Downloading..."? status: "Preparing...";
                process.progress = progress;
            }, (src, res) => {
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