import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/models/commit.dart';

//---------------------------STATE---------------------------//
class GithubState {
  final bool isLoading;
  final bool isProgressing;
  final bool isReady;
  final List<Commit> commits;
  final Map<String, double> contributions;
  final List<Map<String, String>> avatarUrls;
  final String error;
  final int totalCommits;
  final int processedCommits;

  GithubState({
    this.isLoading = false,
    this.isProgressing = false,
    this.isReady = false,
    this.contributions = const {},
    this.commits = const [],
    this.avatarUrls = const [],
    this.error = '',
    this.totalCommits = 0,
    this.processedCommits = 0,
  });

  GithubState copyWith({
    bool? isLoading,
    bool? isProgressing,
    bool? isReady,
    Map<String, double>? contributions,
    List<Commit>? commits,
    List<Map<String, String>>? avatarUrls,
    String? error,
    int? totalCommits,
    int? processedCommits,
  }) {
    return GithubState(
      isLoading: isLoading ?? this.isLoading,
      isProgressing: isProgressing ?? this.isProgressing,
      isReady: isReady ?? this.isReady,
      contributions: contributions ?? this.contributions,
      commits: commits ?? this.commits,
      avatarUrls: avatarUrls ?? this.avatarUrls,
      error: error ?? this.error,
      totalCommits: totalCommits ?? this.totalCommits,
      processedCommits: processedCommits ?? this.processedCommits,
    );
  }
}

//---------------------------NOTIFIER---------------------------//
class GithubStateNotifier extends StateNotifier<GithubState> {
  GithubStateNotifier() : super(GithubState());

 bool isReadyToFalse (){
   state = state.copyWith(isReady: false);
   return state.isReady;
 }

  Future<bool> validateToken(String token) async {
    try {
      print(token);
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: headers
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print("Token validé avec succès !");
        }
        return true;
      } else if (response.statusCode == 401) {
        state = state.copyWith(error: "Token invalide. Vérifiez le Token.");
        return false;
      } else {
        state = state.copyWith(error: "Erreur inconnue lors de la validation du token.");
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: "Erreur lors de la validation du token: ${e.toString()}");
      return false;
    }
  }

  Future<bool> validateRepo(String owner, String repo, String token) async {
    try {
     print(repo);
      final headers = {'Authorization': 'token $token'};
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        state = state.copyWith(error: "Dépôt introuvable ou inaccessible.");
        return false;
      }
    } catch (e) {
      state = state.copyWith(error: "Erreur lors de la validation du dépôt: ${e.toString()}");
      return false;
    }
  }

  // Récupère les commits du dépôt
  Future<void> getRepoCommits(String owner, String repo, String token) async {
    try {
      state = state.copyWith(isLoading: true, error: '', processedCommits: 0);

      if (!await validateToken(token) || !await validateRepo(owner, repo, token)) {
        state = state.copyWith(isLoading: false);
        return;
      }else{
        state = state.copyWith(isLoading: false);
      }

      final headers = {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github.v3+json',
      };
      String url = 'https://api.github.com/repos/$owner/$repo/commits?per_page=100';
      List<Commit> commits = [];
      List<Map<String, String>> avatarUrls = [];

      while (url.isNotEmpty) {
        final response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode != 200) {
          state = state.copyWith(error: "Erreur: ${response.statusCode}");
          return;
        }

        final jsonResponse = jsonDecode(response.body) as List;
        commits.addAll(jsonResponse.map((data) => Commit.fromJson(data)).toList());

        avatarUrls.addAll(
          jsonResponse.map((data) {
            return {
              'avatar_url': data['author']?['avatar_url'] ?? '',
              'login': data['author']?['login'] ?? '',
              'name': data['commit']?['author']?['name'] ?? '',
            };
          }).where((author) => author['login'] != null).toSet()
          .map((e) => Map<String, String>.from(e)),
        );

        final linkHeader = response.headers['link'];
        url = _getNextPageUrl(linkHeader);
      }

      state = state.copyWith(totalCommits: commits.length, avatarUrls: avatarUrls, isProgressing: true);

      print("Commits récupérés avec succès: ${commits.length}");
      // Récupère les détails de chaque commit
      List<Commit?> detailedCommits = await Future.wait(
        commits.map((commit) async {
          try {
            final commitResponse = await http.get(Uri.parse(commit.url), headers: headers);

            if (commitResponse.statusCode == 200) {
              final commitDetails = jsonDecode(commitResponse.body);
              state = state.copyWith(processedCommits: state.processedCommits + 1);
              return Commit.fromJson(commitDetails);
            } else {
              print("Erreur lors de la récupération des détails du commit: ${commitResponse.statusCode}");
              return null;
            }
          } catch (e) {
            print("Erreur lors de la récupération des détails du commit: $e");
            return null;
          }
        }),
      );

      state = state.copyWith(
        isProgressing: false,
        isReady: true,
        commits: detailedCommits.whereType<Commit>().toList(),
      );
    } catch (e) {
      print("Erreur lors de la récupération des commits: $e");
      state = state.copyWith(error: "Erreur lors de la récupération des commits: ${e.toString()}");
    }
  }

  Map<String, double> calculateFinalContributions(List<Commit> commits) {
    Map<String, String> lineOwnership = {};
    Map<String, int> finalContributions = {};
    Map<String, String> authorNameMap = {};

    for (var commit in commits) {
      String name = commit.commit["author"]["name"] ?? 'Unknown';
      String login = commit.author?["login"] ?? 'Unknown';

      authorNameMap[login] = name;

      var files = commit.files ?? [];

      for (var file in files) {
        var patch = file['patch'] ?? '';

        if (patch.isNotEmpty) {
          for (var line in patch.split('\n')) {
            if (line.startsWith('+') && !line.startsWith('+++')) {
              lineOwnership[line] = login;
            } else if (line.startsWith('-') && !line.startsWith('---')) {
              lineOwnership.remove(line);
            }
          }
        }
      }
    }

    for (var entry in lineOwnership.entries) {
      finalContributions.update(entry.value, (value) => value + 1, ifAbsent: () => 1);
    }

    int totalLines = finalContributions.values.fold(0, (sum, netLines) => sum + netLines);
    if (totalLines == 0) {
      if (kDebugMode) {
        print("Aucune ligne trouvée dans le projet final.");
      }
      return {};
    }

    Map<String, double> percentages = {};
    for (var entry in finalContributions.entries) {
      percentages[entry.key] = (entry.value / totalLines) * 100;
    }

    state = state.copyWith(contributions: percentages);

    return percentages;
  }


  String _getNextPageUrl(String? linkHeader) {
    if (linkHeader != null && linkHeader.contains('rel="next"')) {
      var nextUrlMatch = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
      return nextUrlMatch?.group(1) ?? '';
    }
    return '';
  }
}

//---------------------------PROVIDER---------------------------//
final githubProvider = StateNotifierProvider<GithubStateNotifier, GithubState>((ref) {
  return GithubStateNotifier();
});