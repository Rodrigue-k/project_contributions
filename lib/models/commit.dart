
class Commit {
  final String url;
  final Map<String, dynamic> commit;
  final List<dynamic>? files;

  Commit({required this.url, required this.commit, this.files});

  factory Commit.fromJson(Map<String, dynamic> json) {
    return Commit(
      url: json['url'],
      commit: json['commit'],
      files: json['files'],
    );
  }
}