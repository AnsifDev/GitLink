namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/logout_dialog.ui")]
    public class LogoutDialog: Adw.AlertDialog {
        [GtkChild]
        private unowned Gtk.CheckButton logout_btn;

        [GtkChild]
        private unowned Gtk.CheckButton wipe_btn;

        public bool logout { get; set; }
        public bool logout_freeze { get; set; }
        public bool wipe { get; set; }

        private Git.User user;

        public LogoutDialog(Git.User user) {
            this.user = user;
            var authenticated = user.token != null;
            logout_freeze = true;

            if (authenticated) logout = true;
        }

        [GtkCallback]
        public void selection_changed(Gtk.CheckButton src) {
            var authenticated = user.token != null;
            set_response_enabled("logout", authenticated && logout || wipe);
            if (authenticated) {
                logout_freeze = wipe;
                if (wipe) logout = true;
            }
        }
    }
}