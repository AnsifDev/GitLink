using Gtk, Gee, Soup, Gitlink;

namespace Git {
    public class Client: Object {
        private static Client? instance;

        public static Client get_default() {
            if (instance == null) instance = new Client();
            return instance;
        }

        private ArrayList<User> user_store = new ArrayList<User>();
        private ArrayList<Repository> repo_store = new ArrayList<Repository>();

        private ArrayList<Value?> local_users;
        //  public User? active_user { get; set; default = null; }

        private Client() {
            print("Booting Git Client...\n");
            var config_path = @"$(Environment.get_user_config_dir())/git_client.config";
            if (File.new_for_path(config_path).query_exists()) {
                print("\t* Loading Configuration...\n");

                HashMap<string, Value?> config_map = null;
                try { config_map = new JsonEngine().parse_file_to_hashmap(config_path); }
                catch (Error e) { print(@"ERR: $(e.message)\n"); }

                if (config_map != null) {
                    if (config_map.has_key("users")) local_users = config_map["users"] as ArrayList<Value?>;
                }
            } else print("\t* Configurations are set to defaults\n");

            if (local_users == null) local_users = new ArrayList<Value?>();

            GLib.Application.get_default().shutdown.connect(save);
            print("Booting Git Client\t\t[OK]\n");
        }

        private void save() {
            print("Shuting down Git Client\n");
            var config_path = @"$(Environment.get_user_config_dir())/git_client.config";
            var config_map = new HashMap<string, Value?>();
            var json_engine = new JsonEngine();

            print("\t* Saving Configuration...\n");
            config_map["users"] = local_users;
            try { json_engine.parse_hashmap_to_file(config_map, config_path); }
            catch (Error e) { print(@"ERR: $(e.message)\n"); }
            
            foreach (var uid_value in local_users) try {
                var uid = uid_value.get_int64();

                //Cache check
                foreach (var cached_user in user_store) if (cached_user.id == uid) {
                    var user_data_map = cached_user.to_hashmap();
                    var user_data_path = @"$(Environment.get_user_data_dir())/$(cached_user.id)";

                    print(@"\t* Saving Data of User: $(cached_user.name)...\n");
                    json_engine.parse_hashmap_to_file(user_data_map, user_data_path);

                    print(@"\t* Saving Configurations of User: $(cached_user.name)...\n");
                    cached_user.save_configurations();

                    print(@"\t* Saving Local Repository Data of User: $(cached_user.name)...\n");
                    if (cached_user.local_repos != null) foreach (var rid_value in cached_user.local_repos) {
                        var rid = rid_value.get_int64();
        
                        //Cache check
                        foreach (var cached_repo in repo_store) if (cached_repo.id == rid) {
                            var repo_data_map = cached_repo.to_hashmap();
                            var repo_data_path = @"$(Environment.get_user_data_dir())/$(cached_repo.id)";

                            print(@"\t\t* Saving Data of Repository: $(cached_repo.name)...\n");
                            json_engine.parse_hashmap_to_file(repo_data_map, repo_data_path);

                            break;
                        }
                    }

                    break;
                }
            } catch (Error e) { print(@"ERR: $(e.message)\n"); }

            print("Shuting down Git Client\t\t[OK]\n");
        }

        public async ArrayList<Repository>? load_repositories(User user) {
            try {
                var response = yield request(@"user/repos", user);
                if (response == null) return null;

                var json_engine = new JsonEngine();
                var data_array = json_engine.parse_string_to_array(response);
                var repos = new ArrayList<Repository>();

                foreach (var data_map_value in data_array) {
                    var data_map = data_map_value as HashMap<string, Value?>;
                    var rid = (int64) data_map["id"];
                    Repository? repo = null;
                    
                    foreach (var cached_repo in repo_store) if (cached_repo.id == rid) {
                        repo = cached_repo;
                        break;
                    }

                    if (repo == null) repo_store.add(repo = new Repository(data_map));
                    else repo.update_from_HashMap(data_map);

                    repos.add(repo);
                }

                return repos;
            } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return null;
        }

        public ArrayList<Repository> load_local_repositories(User user) {
            var repos = new ArrayList<Repository>();
            var invalid_repos = new ArrayList<Value?>();

            if (user.local_repos != null) foreach (var rid_value in user.local_repos) {
                var rid = rid_value.get_int64();
                Repository? repo = null;

                //Cache check
                foreach (var cached_repo in repo_store) if (cached_repo.id == rid) {
                    repo = cached_repo;
                    break;
                }

                //User loading
                if (repo == null) {
                    var file_path = @"$(Environment.get_user_data_dir())/$rid";
                    if (File.new_for_path(file_path).query_exists()) try {
                        var json_engine = new JsonEngine();
                        var data_map = json_engine.parse_file_to_hashmap(file_path);
                        
                        repo_store.add(repo = new Repository(data_map));
                        repo.update.begin();
                    } catch (Error e) { invalid_repos.add(rid_value); }
                    else invalid_repos.add(rid_value);
                    
                }
                
                repos.add(repo);
            }

            foreach (var rid in invalid_repos) user.local_repos.remove(rid);

            return repos;
        }

        public async Repository? load_repository(string full_name, User user) {
            //Cache check
            foreach (var cached_repo in repo_store) 
                if (cached_repo.full_name == full_name) return cached_repo;

            //Repo loading
            try {
                var response = yield request(@"repos/$full_name", user);
                if (response == null) return null;

                var json_engine = new JsonEngine();
                var data_map = json_engine.parse_string_to_hashmap(response);
                return new Repository(data_map);
            } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return null;
        }

        public ArrayList<User> load_local_users() {
            var users = new ArrayList<User>();
            var invalid_users = new ArrayList<Value?>();

            foreach (var uid_value in local_users) {
                var uid = uid_value.get_int64();
                User? user = null;

                //Cache check
                foreach (var cached_user in user_store) if (cached_user.id == uid) {
                    user = cached_user;
                    break;
                }

                //User loading
                if (user == null) {
                    var file_path = @"$(Environment.get_user_data_dir())/$uid";
                    if (File.new_for_path(file_path).query_exists()) try {
                        var json_engine = new JsonEngine();
                        var data_map = json_engine.parse_file_to_hashmap(file_path);
                        
                        user_store.add(user = new User(data_map));
                    } catch (Error e) { invalid_users.add(uid_value); }
                    else invalid_users.add(uid_value);
                    
                }
                
                users.add(user);
            }

            foreach (var uid in invalid_users) local_users.remove(uid);

            return users;
        }

        public async User? load_user(string username) {
            foreach (var cached_user in user_store) 
                if (cached_user.username == username) return cached_user;

            //User loading
            try {
                var response = yield request(@"users/$username", null);
                if (response == null) return null;

                var json_engine = new JsonEngine();
                var data_map = json_engine.parse_string_to_hashmap(response);
                return new User(data_map);
            } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return null;
        }
    }
}