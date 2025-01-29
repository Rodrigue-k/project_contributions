
class Commit {
  final String url;
  final Map<String, dynamic> commit;
  final Map<String, dynamic> author;
  final List<dynamic>? files;

  Commit({required this.url, required this.commit, required this.author, this.files});

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      url: json['url'],
      commit: json['commit'],
      author: json['author'],
      files: json['files'],
    );
  }
}