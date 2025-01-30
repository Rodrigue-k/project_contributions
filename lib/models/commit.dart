class Commit {
        final String url;
        final Map<String, dynamic> commit;
        final List<dynamic>? files;
        final Map<String, dynamic>? author;

        Commit({required this.url, required this.commit, this.files, this.author});

        factory Commit.fromJson(Map<String, dynamic> json) {
          return Commit(
            url: json['url'] ?? '',
            commit: json['commit'] ?? {},
            files: json['files'],
            author: json['author'],
          );
        }
      }