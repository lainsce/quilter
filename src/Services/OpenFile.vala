public class OpenFile : Object {
    public int id { get; set; }
    public string title { get; set; }
    public string path { get; set; }

    public OpenFile (int id, string title, string path) {
        this.id = id;
        this.title = title;
        this.path = path;
    }
}
