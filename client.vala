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
        
        
    });

    new MainLoop().run();

    return 0;
}