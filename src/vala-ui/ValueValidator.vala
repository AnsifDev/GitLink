using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/value_validator.ui")]
    class ValueValidator: Adw.AlertDialog {
        public string description { get; set; default = ""; }
        public string value { get; set; default = ""; }
        public string error { get; set; default = ""; }
        public bool valid {
            get { return has_response("confirm")? get_response_enabled("confirm"): false; }
            set { set_response_enabled("confirm", value); }
        }

        public ValueValidator(string heading, string? body) {
            Object(heading: heading, body: body);
        }

        [GtkCallback]
        public void on_text_changed(Editable src) { on_value_changed(src.text); }

        public signal void on_value_changed(string value);
    }
}