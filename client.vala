int main (string[] args) {
    print(">> Enter the ip address: ");
    var ip = stdin.read_line();
    Gitlink.Connection.Client.connect_to_server.begin(ip, 3000, (src, res) => {
        var client = Gitlink.Connection.Client.connect_to_server.end(res);

        print(@"Connected to $(client.inet_addr)\n");

        client.on_message_received.connect((action, payload) => {
            print(@"[$(client.inet_addr)] $action%s", payload == null? "\n": @": $payload\n");
        });

        client.disconnected.connect(() => {
            print(@"Disconnected from $(client.inet_addr)\n");
        });
        
        while (true) {
            string write_buff;

            write_buff = stdin.read_line ();
            var items = write_buff.split (" ", 2);
            client.send_message(items[0].strip (), items[1].strip ());
        }
    });

    new MainLoop().run();

    return 0;
}