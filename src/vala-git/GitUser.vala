using Gee, Gitlink;

namespace Git {
    public class User: Object {
        public int64 id { get; private set; }
        public string? token { get; private set; }
        public string name { get; private set; }
        public string url { get; private set; }
        public string username { get; private set; }
        public string email { get; private set; }
        public string avatar_url { get; private set; }
        public int64 followers { get; private set; }
        public int64 following { get; private set; }
        public ArrayList<Value?>? local_repos { get; private set; }
        
        internal User(HashMap<string, Value?> data_map) {
            id = (int64) data_map["id"];
            extract_HashMap(data_map);
            load_configurations();
        }

        public async bool update(HashMap<string, Value?> data) {
            try {
                var response = yield request(@"users/$username", null);
                if (response == null) return false;

                var json_engine = new JsonEngine();
                var data_map = json_engine.parse_string_to_hashmap(response);
                extract_HashMap(data_map);

                return true;
            } catch(Error e) { print(@"ERR: $(e.message)\n"); }

            return false;
        }
        
        private void extract_HashMap(HashMap<string, Value?> data_map) {
            username = data_map["login"] as string;
            name = data_map["name"] as string;
            url = data_map["html_url"] as string;
            email = data_map["email"] as string;
            avatar_url = data_map["avatar_url"] as string;
            followers = (int64) data_map["followers"];
            following = (int64) data_map["followers"];
            if (data_map.has_key ("local_repos")) local_repos = data_map["local_repos"] as ArrayList<Value?>;
        }

        public HashMap<string, Value?> to_hashmap() {
            var data = new HashMap<string, Value?>();
            data["id"] = id;
            data["login"] = username;
            data["name"] = name;
            data["html_url"] = url;
            data["email"] = email;
            data["avatar_url"] = avatar_url;
            data["followers"] = followers;
            data["followers"] = followers;
            data["local_repos"] = local_repos;

            return data;
        }

        private void load_configurations() {
            var config_path = @"$(Environment.get_user_config_dir())/$id";

            if (!File.new_for_path(config_path).query_exists()) return;
            
            try {
                var json_engine = new JsonEngine();
                var config = json_engine.parse_file_to_hashmap(config_path);

                if (config.has_key ("token")) token = config["token"] as string;
            } catch (Error e) { print(@"ERR: $(e.message)\n"); }
        }

        public void save_configurations() {
            var config = new HashMap<string, Value?>();
            if (token != null) config["token"] = token;

            var config_path = @"$(Environment.get_user_config_dir())/$id";
            var json_engine = new JsonEngine();
            try { json_engine.parse_hashmap_to_file(config, config_path); }
            catch (Error e) { print(@"ERR: $(e.message)\n"); }
        }
    }
}