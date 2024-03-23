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

        //  private string[] cmd_args;
        //  private GenericArray<weak string> g_cmd_args = new GenericArray<weak string>();

        [GtkChild]
        private unowned Adw.NavigationView nav_view;

        public Window (Gtk.Application app) {
            Object (application: app);
            //  cmd_args = "hashfolder".split(" ");
            //  var client = Git.Client.get_default();
            //  client.get_local_repositories(client.get_local_users()[0]);
            //  var local_users = client.get_local_users();
            //  if (local_users.size > 0) {
            //      var home_page = new HomePage(local_users);
            //      home_page.push_page.connect (nav_view.push);
            //      home_page.close_page.connect (nav_view.pop);
            //      nav_view.push(home_page);
            //  }
            
            
        }

        [GtkCallback]
        public void login() {
            var client = Git.Client.get_default();
            var local_users = client.load_local_users();
            if (local_users.size > 0) {
                var home_page = new HomePage(local_users);
                home_page.push_page.connect (nav_view.push);
                home_page.close_page.connect (nav_view.pop);
                nav_view.push(home_page);
            }
            //  var parent = Xdp.parent_new_gtk(this);
            //  var portal = new Xdp.Portal();
            //  var g_cmd_args = new GenericArray<weak string>();
            //  const string[] cmd_args = {"hashfolder"};
            //  foreach (unowned string word in cmd_args) g_cmd_args.add(word);
            //  print(@"processing:$(g_cmd_args.get(0))\n");
            //  portal.request_background.begin(parent, "Testing Function",  g_cmd_args, Xdp.BackgroundFlags.NONE, null, (src, result) => {
            //      try {
            //          var response = portal.request_background.end(result);
            //          print(@"$response:$(g_cmd_args.get(0))\n");
            //      } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }
            //  });
        }
    }
}
