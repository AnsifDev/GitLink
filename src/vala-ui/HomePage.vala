using Gtk, Gee;

namespace Gitlink {
    [GtkTemplate (ui = "/com/asiet/lab/GitLink/gtk/home_page.ui")]
    public class HomePage: Adw.NavigationPage {
        [GtkChild]
        private unowned ListBox list_box;

        private AccountsListModel model;

        public HomePage(ArrayList<Git.User> local_users) {
            //  var client = Git.Client.get_default ();
            //  var local_users = client.get_local_users ();
            model = new AccountsListModel(local_users);
            list_box.bind_model (model, (obj) => obj as Widget);
            if (model.get_n_items () > 0) list_box.select_row (model.get_item (0) as ListBoxRow);
            
            //  if (model.get_n_items () > 0) nav_view.push (new UserPage(local_users[0]));

            //  client.get_authenticated_user.begin ((src, result) => {
            //      var user = client.get_authenticated_user.end(result);
            //      var users = new ArrayList<Git.User>();
            //      if (user != null) users.add (user);
            //      model = new AccountsListModel(users);
            //      list_box.bind_model (model, (obj) => obj as Widget);
            //      if (model.get_n_items () > 0) list_box.select_row (model.get_item (0) as ListBoxRow);
            //  });

            list_box.row_activated.connect((obj, row) => {
                //  view_account(model.get_data_for_row(row) as HashMap<string, Value?>);
                push_page (new UserPage(model.get_data_for_row(row)));
            });
        }
        
        public signal void push_page(Adw.NavigationPage page);
        
        public signal bool close_page();
    }
}