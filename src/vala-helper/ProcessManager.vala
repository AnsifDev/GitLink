using Gee;

namespace Gitlink {
    public class Process: Object {
        public string id { get; construct set; }
        public string name { get; set; }
        public string status { get; set; }
        public float progress { get; set; default = -1; }

        public Process(string id, string name) {  Object(id: id, name: name); }

        public signal void completed();
    }

    public class ProcessManager: Gee.ArrayQueue<Process> {
        private Application app;

        public ProcessManager(Application app) { 
            this.app = app;
            //  base(equal_function);
        }

        private bool equal_function (Process a, Process b) { return a == b || a.id == b.id; }
        
        public new Process? @get(string id) {
            foreach (var item in this) if (item.id == id) return item;
            return null;
        }

        private void process_cb(Process process) { remove(process); }

        public override bool add (Process process) {
            if (process in this) return false;
            base.add (process);
            if (size == 1) app.hold();
            process.completed.connect (process_cb);
            process_added(process);
            return true;
        }

        public override bool remove (Process process) {
            var rt = base.remove (process);
            if (rt) process.completed.disconnect (process_cb);
            if (size == 0) app.release();
            return rt;
        }

        public signal void process_added(Process process);
    }
}