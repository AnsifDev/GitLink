/* application.vala
 *
 * Copyright 2023 Ansif
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
using Gee, Gitlink.Connection;

namespace Gitlink {
    public class Application : Adw.Application {
        private bool _hotspot_active = false;
        private HashMap<Client, string?> clients = new HashMap<Client, string?>();
        public bool alarm_ringing { get; set; }
        private Bell bell;

        public Server server { get; private set; default = new Server (); }
        public bool hotspot_active { 
            get { return _hotspot_active; } 
            set { 
                _hotspot_active = value;
                if (value) { server.start (3000); hold(); }
                else { server.stop(); release (); }
            } 
        }

        public Client client { get; private set; }
        private bool _client_active = false;
        public bool client_active { 
            get { return _client_active; } 
            set {
                if (value) {
                    if (client != null) return;
                    Client.connect_to_server.begin(settings.get_string("host-ip"), 3000, (src, res) => {
                        try {
                            client = Client.connect_to_server.end(res);
                            if (client == null) return;
                            Timeout.add_once(1000, () => client.send_message("NAME", settings.get_string("dev-name")));
                            
                            client.disconnected.connect(() => {                                
                                client = null;
                                Idle.add_once(release);
                                client_active = false;
                                print("Disconnected\n");
                            });
                            
                            _client_active = true;
                            print("OnHold");
                            Idle.add_once(hold);
                        } catch (Error e) {}
                    });
                } else {
                    if (client == null) return;
                    client.end_connection ();
                    client = null;
                    release ();
                }
            }
        }
        private GLib.Settings settings = new GLib.Settings ("com.asiet.lab.GitLink");

        public Application () {
            Object (application_id: "com.asiet.lab.GitLink", flags: ApplicationFlags.DEFAULT_FLAGS);
        }

        public string get_client_name(Client client) { return clients[client]; }

        public Client[] get_connected_clients() { return clients.keys.to_array (); }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences_action },
                { "quit", this.quit }
            };
            this.add_action_entries (action_entries, this);
            this.set_accels_for_action ("app.quit", {"<primary>q"});

            bell = new Bell(File.new_for_uri ("resource:///com/asiet/lab/GitLink/assets/alarm1.mp3"));
            bind_property ("alarm_ringing", bell, "ringing", GLib.BindingFlags.BIDIRECTIONAL|GLib.BindingFlags.SYNC_CREATE);

            server.connected.connect ((client) => clients[client] = null );
            server.disconnected.connect ((client) => clients.unset (client) );
            server.on_message_received.connect ((client, action, payload) => {
                if (action == "NAME") clients[client] = payload;
                if (action == "MOUNT") {
                    var app = Application.get_default ();
                    var dev = app.get_client_name (client);
                    var notification = new Notification (@"Malpractice Detected");
                    notification.set_body (@"There is an attempt to mount a files system on the device $dev");
                    notification.set_priority (GLib.NotificationPriority.URGENT);
                    alarm_ringing = true;
                    app.send_notification (@"$dev-$payload", notification);
                    print("Running\n");
                }
            });
        }

        public new static Application get_default() {
            return GLib.Application.get_default () as Application;
        }

        public override void activate () {
            base.activate ();
            var win = this.active_window;
            if (win == null) win = new Gitlink.Window (this);
            //  if (win == null) win = new Gitlink.ConfigWindow (this);
            win.present ();
        }

        private void on_about_action () {
            string[] developers = { "Ansif" };
            var about = new Adw.AboutWindow () {
                transient_for = this.active_window,
                application_name = "GitLink",
                application_icon = "com.asiet.lab.GitLink",
                developer_name = "Ansif",
                version = "0.1.0",
                developers = developers,
                copyright = "© 2023 Ansif",
            };

            about.present ();
        }

        private void on_preferences_action () {
            message ("app.preferences action activated");
        }
    }
}
