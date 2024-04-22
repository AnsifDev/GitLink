using Gtk, Gee;

namespace Gitlink {
    class DevListRow: Adw.ActionRow {
        public DevListRow() {
            add_prefix (new Image.from_icon_name ("display-symbolic"));
        }
    }

    class DevListModel: RecycleViewModel {
        private Gee.ArrayList<string> data;

        public DevListModel(Gee.ArrayList<string> data) {
            this.data = data;
            initialize ();
        }

        public override Gtk.ListBoxRow create_list_box_row () {
            return new DevListRow();
        }
        public override void on_bind (int position, Gtk.ListBoxRow list_box_row) {
            var dev_list_row = (DevListRow) list_box_row;
            dev_list_row.title = data[position];
        }
        public override uint get_n_items () {
            return data.size;
        }

    }

    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/invigilator_page.ui")]
    class InvigilatorPage: Adw.NavigationPage {
        [GtkChild]
        private unowned Gtk.Box ip_box;

        [GtkChild]
        private unowned Gtk.ListBox dev_list_view;

        public bool hotspot_active { get; set; default = false; }
        public string hotspot_img { get; set; default = "/com/asiet/lab/GitLink/assets/hotspot-off.png"; }

        private Connection.Server server = new Connection.Server();
        private ArrayList<string> clients = new ArrayList<string>();
        private DevListModel model;

        public InvigilatorPage() {
            server.connected.connect ((client) => {
                clients.add (client.inet_addr.to_string ());
                model.notify_data_set_changed ();
                dev_list_view.visible = true;
            });

            server.disconnected.connect ((client) => {
                clients.remove (client.inet_addr.to_string ());
                model.notify_data_set_changed ();
                dev_list_view.visible = clients.size != 0;
            });

            var list = server.get_ipv4 ();
            model = new DevListModel (clients);

            dev_list_view.bind_model (model, (widget) => (Widget) widget);

            foreach (var ip in list) {
                if (ip.has_prefix ("lo")) continue;
                var ip_raw = ip.split (" ")[1].strip();

                var bin = new Adw.Bin();
                bin.halign = bin.valign = Align.CENTER;
                bin.add_css_class ("my-small-frame");
                ip_box.append (bin);

                var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
                box.margin_start = box.margin_top = box.margin_end = box.margin_bottom = 12;
                box.halign = Align.START;
                bin.child = box;

                var label = new Label(ip_raw);
                label.halign = Align.START;
                box.append(label);

                var btn = new Button.from_icon_name ("edit-copy-symbolic");
                btn.add_css_class ("flat");
                btn.clicked.connect (() => {
                    var clipboard = get_clipboard();
                    clipboard.set_text(ip_raw);
                });
                box.append (btn);
            }
        }

        [GtkCallback]
        public bool on_state_changed(bool state) {
            if (state) server.start (3000);
            else server.stop ();
            hotspot_img = @"/com/asiet/lab/GitLink/assets/$(state? "hotspot": "hotspot-off").png";
            return false;
        }

        //  [GtkCallback]
        //  private void hotspot_on() {
        //      hotspot_active = true;
        //      //  empty = clients.size > 0;
        //      //  server.start (3000);
        //  }
    }
}