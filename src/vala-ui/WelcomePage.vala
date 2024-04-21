using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/welcome_page.ui")]
    class WelcomePage: Adw.NavigationPage {
        [GtkCallback]
        private void setup_personal() { next(SetupType.PERSONAL); }

        [GtkCallback]
        private void setup_lab_client() { next(SetupType.LAB_CLIENT); }

        [GtkCallback]
        private void setup_lab_host() { next(SetupType.LAB_HOST); }

        public signal void next(SetupType type);
    }
}