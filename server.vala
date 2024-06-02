int main (string[] args) {
    var mainloop = new MainLoop();
    Gitlink.Connection.Client.connect_to_server("0.0.0.0", 3000, (src, res) => {
        var client = Gitlink.Connection.Client.connect_to_server.end(res);
        if (client == null) mainloop.quit ();

        Timeout.add_once(1000, () => client.send_message("NAME", "S23"));

        Timeout.add_once(10000, () => client.send_message("MOUNT", "Sandisk"));

        client.disconnected.connect(() => {                                
            client = null;
            mainloop.quit ();
            print("Disconnected\n");
        });
    });

    mainloop.run();

    return 0;
}