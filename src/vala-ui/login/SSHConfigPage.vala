using Gtk, Gee;

namespace Gitlink {
    class KeyListRow: Adw.ActionRow {
        public bool configured { get; set; default = false; }
        public LocalKey key { get; set; }
        
        public KeyListRow() {
            title_lines = 1;
            add_prefix (new Gtk.Image.from_icon_name ("key-symbolic"));
            var tick = new Gtk.Image.from_icon_name ("check-round-outline-symbolic");
            tick.margin_start = tick.margin_end = 6;
            tick.add_css_class ("success");
            bind_property ("configured", tick, "visible", GLib.BindingFlags.SYNC_CREATE, null, null);
            add_suffix (tick);
        }

        public void bind(LocalKey key) {
            this.key = key;
            title = key.local_path;
            configured = key.configured;
        }
    }

    class KeyListModel: RecycleViewModel {
        Gee.ArrayList<LocalKey> data;

        public KeyListModel(Gee.ArrayList<LocalKey> data) {
            this.data = data;
            initialize ();
        }

        public override Gtk.ListBoxRow create_list_box_row () {
            return new KeyListRow();
        }
        public override void on_bind (int position, Gtk.ListBoxRow list_box_row) {
            var key_list_row = (KeyListRow) list_box_row;
            key_list_row.bind (data[position]);
        }
        public override uint get_n_items () {
            return data.size;
        }

    }

    class LocalKey {
        public string local_path { get; set; }
        public bool configured { get; set; default = false; }
    }
    
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/ssh_config_page.ui")]
    public class SSHConfigPage : Adw.NavigationPage {
        private Git.User user;
        private KeyListModel key_list_model;
        private SSHConfiguration ssh_config;
        
        [GtkChild]
        private unowned Gtk.ListBox key_list_view;

        public SSHConfigPage(Git.User user, SSHConfiguration ssh_config) {
            this.user = user;
            this.ssh_config = ssh_config;

            var path = @"$(Environment.get_home_dir ())/.ssh";
            var dir = File.new_for_path (path);
            var keys = new Gee.ArrayList<LocalKey>();
            
            FileEnumerator enumerator = dir.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
        
            FileInfo info = null;
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () != FileType.DIRECTORY) {
                    var filename = info.get_name ();
                    if (filename.has_suffix (".pub")) {
                        var local_key = new LocalKey ();
                        local_key.local_path = @"$path/$filename";

                        var file_reader = new DataInputStream(File.new_for_path(@"$(local_key.local_path)").read());
                        var key = file_reader.read_line();

                        foreach (var item in user.remote_ssh_keys) {
                            var data_map = (HashMap<string, Value?>) item;
                            var remote_key = data_map["key"].get_string();
                            //  print("%s: %s\n", key, remote_key);

                            
                            if (local_key.configured = key.has_prefix(remote_key)) break;
                        }
                        keys.add (local_key);
                    }
                }
            }

            key_list_model = new KeyListModel(keys);
            key_list_view.bind_model (key_list_model, (widget) => (Gtk.Widget) widget);
            key_list_view.row_activated.connect((row) => {
                var key_list_row = (KeyListRow) row;
                var local_path = key_list_row.key.local_path;

                if (ssh_config.has_key(@"$(user.username).github.com")) 
                    ssh_config[@"$(user.username).github.com"] = new HostConfiguration.for_github(@"$(user.username).github.com");
                ssh_config[@"$(user.username).github.com"]["IdentityFile"] = local_path;

                ssh_config.save();
                pop();
            });
        }

        public signal void push(Adw.NavigationPage page);

        public signal bool pop();
    }
}