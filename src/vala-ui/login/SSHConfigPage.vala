namespace Gitlink {
    class KeyListModel: RecycleViewModel {
        Gee.ArrayList<string> data;

        public KeyListModel(Gee.ArrayList<string> data) {
            this.data = data;
            initialize ();
        }

        public override Gtk.ListBoxRow create_list_box_row () {
            var row = new Adw.ActionRow ();
            row.add_prefix (new Gtk.Image.from_icon_name ("key-symbolic"));
            return row;;
        }
        public override void on_bind (int position, Gtk.ListBoxRow list_box_row) {
            ((Adw.ActionRow) list_box_row).title = data[position];
        }
        public override uint get_n_items () {
            return data.size;
        }

    }
    
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/ssh_config_page.ui")]
    public class SSHConfigPage : Adw.NavigationPage {
        private Git.User user;
        
        [GtkChild]
        private unowned Gtk.ListBox key_list_view;

        public SSHConfigPage(Git.User user) {
            this.user = user;

            var path = @"$(Environment.get_home_dir ())/.ssh";
            var dir = File.new_for_path (path);
            var keys = new Gee.ArrayList<string>();
            
            FileEnumerator enumerator = dir.enumerate_children (
                "standard::*",
                FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
        
            FileInfo info = null;
            while ((info = enumerator.next_file ()) != null) {
                if (info.get_file_type () != FileType.DIRECTORY) {
                    var filename = info.get_name ();
                    if (filename.has_suffix (".pub")) keys.add (@"$path/$filename");
                }
            }

            key_list_view.bind_model (new KeyListModel(keys), (widget) => (Gtk.Widget) widget);
        }
    }
}