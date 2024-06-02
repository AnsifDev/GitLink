using Gitlink.Connection, Gee;

namespace Gitlink {
    public class ClientProperties: Object {
        public bool malpractice_detected { get; set; }
        public bool removed { get; set; }
        public string? name { get; set; }
    }

    public class ConnectionManager: Object {
        private bool _hotspot_active = false;
        private HashMap<Client, ClientProperties> clients = new HashMap<Client, ClientProperties>();
        private Bell bell;
        private VolumeMonitor monitor = VolumeMonitor.get ();
        private Application app;
        private GLib.Settings settings = new GLib.Settings ("com.asiet.lab.GitLink");

        public bool alarm_ringing { get; set; }
        public Client client { get; private set; }
        public bool client_active { get; private set; default = false;}
        public Server server { get; private set; default = new Server (); }
        public bool hotspot_active { 
            get { return _hotspot_active; } 
            set { 
                if (_hotspot_active == value) return;
                _hotspot_active = value;
                if (value) { server.start (3000); app.hold(); }
                else { server.stop(); app.release (); }
            } 
        }

        public ConnectionManager(Application app) {
            this.app = app;
            monitor.mount_added.connect((mount) => {
                if (client_active) client.send_message ("MOUNT", mount.get_name());
            });

            bell = new Bell(File.new_for_uri ("resource:///com/asiet/lab/GitLink/assets/alarm1.mp3"));
            bind_property ("alarm_ringing", bell, "ringing", GLib.BindingFlags.BIDIRECTIONAL|GLib.BindingFlags.SYNC_CREATE);

            server.connected.connect ((client) => clients[client] = new ClientProperties() );
            server.disconnected.connect ((client) => {
                if (clients[client].malpractice_detected) clients[client].removed = true;
                else clients.unset (client);
            });
            server.on_message_received.connect ((client, action, payload) => {
                if (action == "NAME") clients[client].name = payload;
                if (action == "MOUNT") {
                    var props = get_client_properties (client);
                    props.malpractice_detected = true;
                    var dev = props.name;
                    var notification = new Notification (@"Malpractice Detected");
                    notification.set_body (@"There is an attempt to mount a files system on the device $dev");
                    notification.set_priority (GLib.NotificationPriority.URGENT);
                    alarm_ringing = true;
                    app.send_notification (@"$dev-malpractice", notification);
                    print("Running\n");
                }
            });

            notify["alarm-ringing"].connect(() => {
                if (!alarm_ringing) {
                    foreach (var client in clients.keys.to_array()) {
                        var props = clients[client];
                        props.malpractice_detected = false;
                        app.withdraw_notification(@"$(props.name)-malpractice");
                        if (props.removed) clients.unset(client);
                    }
                }
            });
        }

        public ClientProperties get_client_properties(Client client) { return clients[client]; }

        public Client[] get_connected_clients() { return clients.keys.to_array (); }

        public async bool connect_to_server() {
            if (client != null) return true;

            client = yield Client.connect_to_server(settings.get_string("host-ip"), 3000);
            if (client == null) return false;

            Timeout.add_once(1000, () => client.send_message("NAME", settings.get_string("dev-name")));

            client.disconnected.connect(() => {                                
                client = null;
                Idle.add_once(app.release);
                client_active = false;
                print("Disconnected\n");
            });

            client_active = true;
            app.hold();
            return true;
        }

        public void disconnect_from_server() {
            if (client == null) return;
            client.end_connection ();
            client = null;
            app.release ();
        }
    }
}