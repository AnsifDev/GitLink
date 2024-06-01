using Gee, Gitlink;

namespace Git {
    public class Repository: Object {
        public int64 id { get; private set; }
        public string name { get; private set; }
        public string full_name { get; private set; }
        public string url { get; private set; }
        public string? local_url { get; private set; }
        public string ssh_url { get; private set; }
        public bool private_repo { get; private set; }
        public string owner { get; private set; }
        public string? description { get; private set; }
        public int64 forks { get; private set; }

        private Ggit.Repository local_repo;

        internal Repository(HashMap<string, Value?> data_map) {
            id = (int64) data_map["id"];
            update_from_HashMap(data_map);

            if (local_url != null) local_repo = Ggit.Repository.open(File.new_for_path(local_url));
        }

        public string[] list_all_files(string root_path) throws Error {
            var file_paths = new Gee.ArrayList<string>();
            var file_enum = File.new_for_path(root_path).enumerate_children("standard::name", GLib.FileQueryInfoFlags.NOFOLLOW_SYMLINKS);
            FileInfo file_info;
            while ((file_info = file_enum.next_file  ()) != null) {
                if (file_info.get_file_type  () == FileType.DIRECTORY) file_paths.add_all_array(list_all_files  (@"$root_path/$(file_info.get_name())"));
                else file_paths.add(@"$root_path/$(file_info.get_name())");
            }
        
            return file_paths.to_array();
        }

        public static async Repository new_from_path (string path, User user, string name, string? description = null, bool private_repo = false) throws Error {
            var body = new HashMap<string, Value?>();
            body["name"] = name;
            body["private"] = private_repo;
            if (description != null) body["description"] = description;

            var response = yield post_request("user/repos", body, user);
            if (response == null) error("Repository Creation Failed\n");
            var resp_map = new JsonEngine().parse_string_to_hashmap(response);

            var instance = new Repository(resp_map);

            var url = instance.ssh_url.replace("git@github.com", @"git@$(user.username).github.com");
            Posix.system(@"git -C $path init");
            Posix.system(@"git -C $path config user.email \"$(user.email)\"");
            Posix.system(@"git -C $path config user.email \"$(user.email)\"");
            Posix.system(@"git -C $path remote add -f origin $url");
            Posix.system(@"git -C $path add --all");
            Posix.system(@"git -C $path commit -m \"Initial Commit\"");
            Posix.system(@"git -C $path push");

            return instance;
        }

        //  public async Repository.upload2(string path, Ggit.RemoteCallbacks callbacks, User user, string name, string? description, bool private_repo = false) throws Error {
        //      var body = new HashMap<string, Value?>();
        //      body["name"] = name;
        //      body["private"] = private_repo;
        //      if (description != null) body["description"] = description;

        //      var response = yield post_request("user/repos", body, user);
        //      if (response == null) error("Repository Creation Failed\n");

        //      var resp_map = new JsonEngine().parse_string_to_hashmap(response);
        //      update_from_HashMap(resp_map);
            
        //      var url = ssh_url.replace("git@github.com", @"git@$owner.github.com");
            
        //      var repo = Ggit.Repository.init_repository(File.new_for_path(path), false);
        //      Posix.system(@"git -C $path config user.name \"$(user.name)\"");
        //      Posix.system(@"git -C $path config user.email \"$(user.email)\"");

        //      var author_name = user.name;
        //      var author_email = user.email;
        //      var sig = new Ggit.Signature.now(author_name, author_email);

        //      var index = repo.get_index();
        //      foreach (var item in list_all_files(path)) 
        //          if (!repo.path_is_ignored  (item)) index.add_path(item);
        //      index.write();

        //      var tree_id = index.write_tree();
        //      var tree = repo.lookup_tree(tree_id);

        //      repo.create_commit("HEAD", sig, sig, null, "Initial commit", tree, {});

        //      var remote = repo.create_remote("origin", url);
        //      var master_branch = repo.head as Ggit.Branch;

        //      var push_opts = new Ggit.PushOptions();
        //      push_opts.callbacks = callbacks;
        //      push_opts.parallelism = 4;

        //      new Thread<void>(null, () => {
        //          try {
        //              remote.connect(Ggit.Direction.PUSH, callbacks, null, null);
        //              remote.upload({ repo.head.get_name() }, push_opts);
        //              remote.disconnect();

        //              remote.connect(Ggit.Direction.FETCH, callbacks, null, null);
        //              remote.update_tips(callbacks, true, Ggit.RemoteDownloadTagsType.ALL, null);
        //              remote.disconnect();

        //              Idle.add(Repository.upload2.callback);
        //          } catch (Error e) { critical(e.message); }
        //      }); yield;

        //      var upstream_name = @"origin/$(master_branch.get_name())";
        //      master_branch.set_upstream(upstream_name);

        //      local_url = path;
        //  }

        public void update_from_HashMap(HashMap<string, Value?> data_map) {
            name = data_map["name"] as string;
            full_name = data_map["full_name"] as string;
            url = data_map["html_url"] as string;
            if (data_map.has_key("local_url")) local_url = data_map["local_url"] as string;
            ssh_url = data_map["ssh_url"] as string;
            private_repo = (bool) data_map["private"];
            owner = ((HashMap<string, Value?>) data_map["owner"])["login"] as string;
            if (data_map.has_key("description") && data_map["description"] != null) 
                description = data_map["description"] as string;
            forks = (int64) data_map["forks"];
        }

        public async bool update() {
            try {
                var client = Client.get_default();
                var user = yield client.load_user(owner);
                var response = yield request(@"repos/$full_name", user);
                if (response == null) return false;

                var data_map = new JsonEngine().parse_string_to_hashmap(response);
                update_from_HashMap(data_map);
            } catch (Error e) { printerr(@"ERR: $(e.message)\n"); }

            return false;
        }

        public HashMap<string, Value?> to_hashmap() {
            var owner_map = new HashMap<string, Value?>();
            owner_map["login"] = owner;
            
            var data = new HashMap<string, Value?>();
            data["id"] = id;
            data["name"] = name;
            data["full_name"] = full_name;
            data["html_url"] = url;
            if (local_url != null) data["local_url"] = local_url;
            data["ssh_url"] = ssh_url;
            data["private"] = private_repo;
            data["forks"] = forks;
            data["owner"] = owner_map;
            if (description != null) data["description"] = description;

            return data;
        }

        public string[] get_changes() throws Error {
            var index = local_repo.get_index();
            var status_opts = new Ggit.StatusOptions(Ggit.StatusOption.DEFAULT&~Ggit.StatusOption.INCLUDE_IGNORED, Ggit.StatusShow.WORKDIR_ONLY, null);
            var array = new ArrayList<string>();
            local_repo.file_status_foreach(status_opts, (path, f_status) => {
                array.add(path);
                return 0;
            });
            return array.to_array();
        }

        public async bool upload(RepoTransferCallback transfer_cb) throws Error {
            if (local_repo == null)
                if (local_url == null) throw new Error(GLib.Quark.from_string("NOT_LOCAL_REPO"), 100, "Repository is not downloaded yet. Please download the repository and try again");
                else local_repo = Ggit.Repository.open(File.new_for_path(local_url));
            
            // Index retrived
            var index = local_repo.get_index(); 
	
            // Scaning working directory for changes
	        var status_opts = new Ggit.StatusOptions(Ggit.StatusOption.DEFAULT&~Ggit.StatusOption.INCLUDE_IGNORED, Ggit.StatusShow.WORKDIR_ONLY, null);
            local_repo.file_status_foreach(status_opts, (path, f_status) => {
                
                // Staging changes
                if ((f_status & Ggit.StatusFlags.WORKING_TREE_DELETED) != 0) 
                    index.remove(GLib.File.new_for_path(@"$local_url/$path"), 0);
                else index.add_path(path);
                return 0;
            });
            index.write();

            // Generating a tree for commit
            var tree_id = index.write_tree();
            var tree = local_repo.lookup_tree(tree_id);
            
            // Obtaining parent of new commit
            var head = local_repo.head;
            var target = head != null ? head.get_target(): null;
            var target_commit = target != null ? local_repo.lookup_commit(target): null;
            
            // Generating commit parents array
            Ggit.Commit[] parents;
            if (target_commit != null) parents = { target_commit };
            else parents = {};

            // Retriving commit author details and generating a signature
            var configs = local_repo.get_config();
            var author_name = configs.get_entry("user.name").get_value();
            var author_email = configs.get_entry("user.email").get_value();
            var author = new Ggit.Signature.now(author_name, author_email);

            // Commiting the changes
            var commit = local_repo.create_commit("HEAD", author, author, null, "Commit Test", tree, parents);

            var c_branch = head as Ggit.Branch;

            // Setting up Feedback mechanism on data transfer
            var remote_cb = new RemoteCallbacks();
            var status = "";
            var progress = 0f;
            var running = true;
            remote_cb.progress.connect((msg) => { if (msg.strip().length > 0) status = msg.strip().escape(); });
            remote_cb.transfer_progress.connect((stats) => { status = "Downloading..."; progress = (float) stats.get_received_objects()/stats.get_total_objects(); } );

            if (transfer_cb != null) Timeout.add(200, () => { if (running) transfer_cb(status, progress); return running; });

            // Preparing the configurations for a push operation
            var push_opts = new Ggit.PushOptions();
            push_opts.callbacks = remote_cb;
            push_opts.parallelism = 4;
            
            // Threading a push operation
            var thread = new Thread<bool>(null, () => {
                var sucess = true;
                Ggit.Remote? remote = null;
                try {
                    // Connecting with server for a data transfer
                    remote = local_repo.lookup_remote("origin");
                    remote.connect(Ggit.Direction.PUSH, remote_cb, null, null);

                    // Running a force push
                    remote.push({ @"+$(head.get_name())" }, push_opts);
                    remote.update_tips(remote_cb, false, Ggit.RemoteDownloadTagsType.NONE, "pull");
                } catch (Error e) { printerr("ERR: %s\n", e.message); sucess = false; }

                if (remote != null) remote.disconnect();
                
                Idle.add(upload.callback);
                return sucess;
            }); yield;
            
            running = false;
            if (!thread.join()) return false;

            // Updating the upstream of the branch
            c_branch.set_upstream(@"origin/$(c_branch.get_name())");
            
            return true;
        }

        //  public async bool upload() {
        //      Posix.system(@"git -C $local_url add --all");
        //      Posix.system(@"git -C $local_url commit -m \"GitLink Commit\"");
            
        //      var thread = new Thread<bool>(null, () => {
        //          var status = Posix.system(@"git -C $local_url push --force");
    
        //          Idle.add(upload.callback);
        //          return status == 0;
        //      }); yield;
            
        //      return thread.join();
        //  }

        //  public async bool download() {
        //      var thread = new Thread<bool>(null, () => {
        //          var status = Posix.system(@"git -C $local_url pull --force");
    
        //          Idle.add(download.callback);
        //          return status == 0;
        //      }); yield;
            
        //      return thread.join();
        //  }

        public async bool download(RepoTransferCallback transfer_cb) throws Error {
            var head = local_repo.head;

            // Seting up feedback mechanism on data transfer
            var remote_cb = new RemoteCallbacks();
            var status = "";
            var progress = 0f;
            var running = true;
            remote_cb.progress.connect((msg) => { if (msg.strip().length > 0) status = msg.strip().escape(); });
            remote_cb.transfer_progress.connect((stats) => { status = "Downloading..."; progress = (float) stats.get_received_objects()/stats.get_total_objects(); } );

            if (transfer_cb != null) Timeout.add(200, () => { if (running) transfer_cb(status, progress); return running; });
        
            // Configuring a fetch
            var fetch_opts = new Ggit.FetchOptions();
            fetch_opts.set_remote_callbacks(remote_cb);
            fetch_opts.set_download_tags(Ggit.RemoteDownloadTagsType.NONE);

            // Threading a fetch
            var thread = new Thread<bool>(null, () => {
                var sucess = true;

                try {
                    // Connecting to server
                    var remote = local_repo.lookup_remote("origin");
                    remote.connect(Ggit.Direction.FETCH, remote_cb, null, null);
                    
                    // Fetching
                    remote.download(null, fetch_opts);
                    
                    // Extracting data and updating remote branches
                    remote.update_tips(remote_cb, false, Ggit.RemoteDownloadTagsType.NONE, "pull");
                    remote.prune(remote_cb);

                    // Disconnection from server
                    remote.disconnect();
                } catch (Error e) { printerr("%s", e.message); sucess = false; }
                
                return sucess;
            }); yield;

            running = false;
            if (!thread.join()) return false;

            var c_branch = head as Ggit.Branch;

            // Retriving checkout parameters
            var upstream = c_branch.get_upstream();
            var upstream_target = upstream.get_target();
            var upstream_commit = local_repo.lookup_commit(upstream_target);
            var upstream_tree = upstream_commit.get_tree();
        
            // Configuring a checkout & applying changes
            var checkout_opts = new Ggit.CheckoutOptions();
            checkout_opts.set_strategy(Ggit.CheckoutStrategy.SAFE);
            local_repo.checkout_tree(upstream_tree, checkout_opts);
        
            // Updating head
            head.set_target(upstream_target, "pull");
            
            return true;
        }

        public void wipe() {
            var client = Git.Client.get_default ();
            client.load_user.begin (owner, (src, res) => {
                try {
                    var user = client.load_user.end(res);
                    for (int index = 0; index < user.local_repos.size; index++ ) if (user.local_repos[index].get_int64() == id) {
                        user.local_repos.remove_at(index);
                        break;
                    }
                } catch (Error e) { print("ERR: %s\n", e.message); }
            });
            
            Posix.system(@"rm -fr $local_url");
            local_url = null;
        }

        //  public async bool clone() {
        //      var url = ssh_url.replace("git@github.com", @"git@$owner.github.com");
        //      var path = @"$(Environment.get_home_dir())/$full_name";
        //      var client = Client.get_default();
        //      var user = yield client.load_user(owner);

        //      var thread = new Thread<bool>  (null, () => {
        //          var rt = Posix.system(@"git clone $url $path");

        //          Idle.add(clone.callback);
        //          return rt == 0;
        //      }); yield;

        //      if (!thread.join()) return false;

        //      Posix.system(@"git -C $path config user.name \"$(user.name)\"");
        //      Posix.system(@"git -C $path config user.email \"$(user.email)\"");

        //      local_url = path;
        //      user.local_repos.add(id);

        //      return true;
        //  }

        public delegate void RepoTransferCallback (string status, float progress);

        public async bool clone(RepoTransferCallback transfer_cb) throws Error {
            var url = ssh_url.replace("git@github.com", @"git@$owner.github.com");
            var path = @"$(Environment.get_home_dir())/$full_name";
            var client = Client.get_default();
            var user = yield client.load_user(owner);

            Posix.system (@"rm -fr $path");

            var remote_cb = new RemoteCallbacks();
            var status = "";
            var progress = 0f;
            var running = true;
            remote_cb.progress.connect((msg) => { if (msg.strip().length > 0) status = msg.strip().escape(); });
            remote_cb.transfer_progress.connect((stats) => { status = "Downloading..."; progress = (float) stats.get_received_objects()/stats.get_total_objects(); } );
            //  remote_cb.completion.connect(() => { running = false; });

            if (transfer_cb != null) Timeout.add(200, () => { if (running) transfer_cb(status, progress); return running; });

            var fetch_opts = new Ggit.FetchOptions();
            fetch_opts.set_remote_callbacks(remote_cb);

            var clone_opts = new Ggit.CloneOptions();
            clone_opts.set_fetch_options(fetch_opts);

            var thread = new Thread<Ggit.Repository>(null, () => {
                Ggit.Repository repo = null;
                try { repo = Ggit.Repository.clone(url, File.new_for_path(path), clone_opts); }
                catch (Error e) {}
                Idle.add(clone.callback);
                return repo;
            }); yield;

            running = false;
            if (transfer_cb != null) transfer_cb("Downloading... [OK]", progress);

            local_repo = thread.join();
            if (local_repo == null) return false;

            var configs = local_repo.get_config();
            configs.set_string("user.name", user.name);
            configs.set_string("user.email", user.email);

            local_url = path;
            user.local_repos.add(id);
            
            return true;
        } 
    }
}