int main (string[] args) {
    var mainloop = new MainLoop();
    //  Gitlink.Connection.Client.connect_to_server("0.0.0.0", 3000, (src, res) => {
    //      var client = Gitlink.Connection.Client.connect_to_server.end(res);
    //      if (client == null) mainloop.quit ();

    //      Timeout.add_once(1000, () => client.send_message("NAME", "S23"));

    //      Timeout.add_once(10000, () => client.send_message("MOUNT", "Sandisk"));

    //      client.disconnected.connect(() => {                                
    //          client = null;
    //          mainloop.quit ();
    //          print("Disconnected\n");
    //      });
    //  });


    var connections = 0;
    var server = new Gitlink.Connection.Server();
    server.start(3000);
    server.connected.connect ((client) => {
        print("%s is connected\n", client.inet_addr.address.to_string());
        connections++;
    });
    server.disconnected.connect ((client) => {
        print("%s is disconnected\n", client.inet_addr.address.to_string());
        if (--connections == 0) mainloop.quit();
    });
    server.on_message_received.connect ((client, action, payload) => {
        print("[%s] %s: %s\n", client.inet_addr.address.to_string(), action, payload);
    });

    print("Server Started\n");
    mainloop.run();
    print("Server Stopped\n");

    return 0;
}