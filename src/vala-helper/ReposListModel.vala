using Gee, Gtk;

namespace Gitlink {
    //  [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/repos_row.ui")]
    //  class ReposRow: Adw.ExpanderRow {
    //      public string description { get; set; }
    //      public string url { get; set; }
    //      public string git_ssh_url { get; set; }
    //      public bool cloned { get; set; }

    //      [GtkCallback]
    //      public void open_web() {
    //          new UriLauncher(url).launch.begin(Application.get_default().active_window, null);
    //      }
    //  }

    class ReposRow: Adw.ActionRow {
        private Git.Repository _repo;
        //  private Button
        
        public Git.Repository repo { 
            get { return _repo; } 
            set {
                _repo = value;
                title = value.name;
                subtitle = value.private_repo? "Private Repo": "Public Repo";
            } 
        }

        construct {
            activatable = true;
            add_prefix(new Image.from_icon_name("network-server-symbolic"));
        }
    }

    public class ReposListModel: RecycleViewModel {
        public ArrayList<Git.Repository> data { get; set; }
        
        public ReposListModel(ArrayList<Git.Repository> src) { 
            data = src;
            //  initialize(); 
        }

        public Value? get_data_for_row(ListBoxRow row) { return data[index_of_row(row)]; }

        public int index_of_item(Git.Repository value) { return data.index_of(value); }

        public override ListBoxRow create_list_box_row() { return new ReposRow(); }

        public override void on_bind(int position, ListBoxRow list_box_row) {
            var repos_row = list_box_row as ReposRow;
            repos_row.repo = data[(int) position];
        }

        public override int get_size () { return data.size; }
    }
}