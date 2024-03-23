using Gee, Gitlink;

namespace Git {
    private const string id = "fe459acb22155ceef1f6";
    private const string secret = "5a76b3547bd2a952b3d881ad3aa0bf3793770595";

    public async string? request(string end_point, User? user) throws Error {
        print(@"Processing Request $end_point\n");
        var url = "https://"+(user == null || user.token == null? @"$id:$secret@": "")+@"api.github.com/$end_point";

        var msg = new Soup.Message("GET", url);
        msg.request_headers.append("Accept", "application/vnd.github+json");
        if (user != null && user.token != null) msg.request_headers.append("Authorization", @"Bearer $(user.token)");
        msg.request_headers.append("User-Agent", "HashFolder");

        var session = new Soup.Session();
        var response_bytes = yield session.send_and_read_async(msg, 0, null);
        var response = (string) response_bytes.get_data();
        print(@"Processing Request $end_point\t\t[OK]\n");
        return msg.status_code-200 < 100? response: null;
    }
}