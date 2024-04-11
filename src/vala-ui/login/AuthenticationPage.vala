using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/authentication_page.ui")]
    public class AuthenticationPage : Adw.NavigationPage {
        [GtkChild]
        private unowned Button btn_authorize;

        [GtkChild]
        private unowned Adw.ToastOverlay toast_overlay;

        public string? user_code { get; private set; default = "OCSD-12DE"; }

        private string? device_code = null;
        private int64? interval = null;
        private int64? expire = null;
        private bool polling = false;
        
        public AuthenticationPage() {
            btn_authorize.sensitive = true;
            btn_authorize.label = "Authorize";
            //  Git.get_login_code.begin((src, res) => {
            //      try {
            //          var response_map = Git.get_login_code.end(res);
            //          device_code = (string) response_map["device_code"];
            //          user_code = (string) response_map["user_code"];
            //          interval = (int64) response_map["interval"];
            //          expire = (int64) response_map["expires_in"];

            //          btn_authorize.sensitive = true;
            //          btn_authorize.label = "Authorize";
            //      } catch (Error e) { print(e.message); }
            //  });
        }

        public signal void authorized(Git.User user);

        [GtkCallback]
        private void copy_code() {
            var clipboard = get_clipboard();
            clipboard.set_text(user_code);
            var toast = new Adw.Toast(@"User Code $user_code Copied");
            toast_overlay.add_toast(toast);
        }

        [GtkCallback]
        private void authorize() {
            var client  = Git.Client.get_default();
            var user = client.load_local_users()[0];
            authorized(user);

            //  bind_property("display_name", this, "title_display", GLib.BindingFlags.SYNC_CREATE, (src, item, ref to_val) => { to_val = @"Welcome $(item.get_string())"; return true; }, null);
            //  var launcher = new UriLauncher("https://github.com/login/device");
            //  launcher.launch.begin(this, null);
            //  if (!polling) {
            //      polling = true;
            //      var client = Git.Client.get_default();
            //      client.authenticate.begin(device_code, (int) expire, (int) interval, (src, res) => {
            //          try {
            //              user = client.authenticate.end(res);

            //              // nav_view.push_by_tag("user_config");
            //              success(user);
            //          } catch (Error e) {
            //              var msg = new Adw.MessageDialog(transient_for, "Something Wrong", "Login Failed due some unexpected error");
            //              msg.add_response("ok", "OK");
            //              msg.present();
            //          }

            //          close();
            //      });
            //  }
        }
    }
}