/* window.vala
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

using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/window.ui")]
    public class Window : Adw.ApplicationWindow {
        private GLib.Settings settings = new GLib.Settings ("com.asiet.lab.GitLink");

        [GtkChild]
        public unowned Adw.NavigationView nav_view;

        public Window (Gtk.Application app) {
            Object (application: app);

            //  nav_view.
            if (settings.get_string ("app-mode") == "lab-host") nav_view.push(new InvigilatorPage (this));
            else if (settings.get_string ("app-mode") != "unknown") nav_view.push(new AccountsPage(this));

            if (!settings.get_boolean("known-host-configured")) Git.register_host.begin("github.com", register_host_cb);
        }

        public void register_host_cb (Object? src, AsyncResult res) {
            var success = false;
            try { success = Git.register_host.end(res); }
            catch (Error e) { print("ERR: %s\n", e.message); }

            if (success) settings.set_boolean("known-host-configured", true);
            else {
                var dg = new Adw.AlertDialog("Host Registeration Failed", "Unable to register github.com to known hosts list of ssh. Your git communications are temperarily done due to this issue\n");
                dg.add_responses("ignore", "Ignore For Now", "retry", "Retry Registeration");
                dg.response.connect((res) => { if (res == "retry") Git.register_host.begin("github.com", register_host_cb); } );
            }
        }

        [GtkCallback]
        private void setup_personal() { nav_view.push(new SetupPage(this, SetupType.PERSONAL)); }
            
        [GtkCallback]
        private void setup_lab_client() { nav_view.push(new SetupPage(this, SetupType.LAB_CLIENT)); }

        [GtkCallback]
        private void setup_lab_host() { 
            settings.set_string("app-mode", "lab-host");
            nav_view.push(new InvigilatorPage(this)); 
        }

        //  public void none() {
        //      var parent = Xdp.parent_new_gtk(this);
        //      var portal = new Xdp.Portal();
        //      var g_cmd_args = new GenericArray<weak string>();
        //      const string[] cmd_args = {"hashfolder"};
        //      foreach (unowned string word in cmd_args) g_cmd_args.add(word);
        //      print(@"processing:$(g_cmd_args.get(0))\n");
        //      portal.request_background.begin(parent, "Testing Function",  g_cmd_args, Xdp.BackgroundFlags.NONE, null, (src, result) => {
        //          try {
        //              var response = portal.request_background.end(result);
        //              print(@"$response:$(g_cmd_args.get(0))\n");
        //          } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }
        //      });
        //  }
    }
}
