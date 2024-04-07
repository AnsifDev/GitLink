using Gtk;
using Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/login_dialog.ui")]
    public class LoginDialog : Adw.Window {
        [GtkChild]
        private unowned Adw.NavigationView nav_view;
        
        [GtkChild]
        private unowned Button btn_start_next;

        private string? device_code = null;
        public string? user_code { get; private set; default = null; }
        private int64? interval = null;
        private int64? expire = null;
        private bool polling = false;
        private Git.User? user = null;
        
        public LoginDialog(Window parent) {
            transient_for = parent;
            modal = true;
            Git.get_login_code.begin((src, res) => {
                try {
                    var response_map = Git.get_login_code.end(res);
                    device_code = (string) response_map["device_code"];
                    user_code = (string) response_map["user_code"];
                    interval = (int64) response_map["interval"];
                    expire = (int64) response_map["expires_in"];

                    btn_start_next.sensitive = true;
                    btn_start_next.label = "Next";
                } catch (Error e) { print(e.message); }
            });
        }

        public signal void success();

        [GtkCallback]
        private void start_next() {
            nav_view.push_by_tag("code");
        }

        [GtkCallback]
        private void code_next() {
            var launcher = new UriLauncher("https://github.com/login/device");
            launcher.launch.begin(this, null);
            if (!polling) {
                polling = true;
                var client = Git.Client.get_default();
                client.authenticate.begin(device_code, (int) expire, (int) interval, (src, res) => {
                    try {
                        user = client.authenticate.end(res);
                        if (user == null) {
                            var msg = new Adw.MessageDialog(transient_for, "Something Wrong", "Login Failed due some unexpected error");
                            msg.add_response("ok", "OK");
                            msg.present();
                            close();
                            return;
                        }

                        //  nav_view.push_by_tag("user_config");
                        close();
                        success();
                    } catch (Error e) { print(e.message); }
                });
            }
        }
    }
}