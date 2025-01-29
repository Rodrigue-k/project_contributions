import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/models/commit.dart';

//-------------STATE-------------------STATE---------------------------STATE------------------------//
class GithubState {
  final bool isLoading;
  final bool isReady;
  final List<Commit> commits;
  final List<Map<String, String>> avatarUrls;
  final String error;
  final int totalCommits;
  final int processedCommits;

  GithubState({
    this.isLoading = false,
    this.isReady = false,
    this.commits = const [],
    this.avatarUrls = const [],
    this.error = '',
    this.totalCommits = 0,
    this.processedCommits = 0,
  });

  GithubState copyWith({
    bool? isLoading,
    bool? isReady,
    List<Commit>? commits,
    List<Map<String, String>>? avatarUrls,
    String? error,
    int? totalCommits,
    int? processedCommits,
  }) {
    return GithubState(
      isLoading: isLoading ?? this.isLoading,
      isReady: isReady ?? this.isReady,
      commits: commits ?? this.commits,
      avatarUrls: avatarUrls ?? this.avatarUrls,
      error: error ?? this.error,
      totalCommits: totalCommits ?? this.totalCommits,
      processedCommits: processedCommits ?? this.processedCommits,
    );
  }
}

//-------------NOTIFIER--------------- NOTIFIER------------------------NOTIFIER----------------------------------------------------------------------------------------------------------------------------------------////
class GithubStateNotifier extends StateNotifier<GithubState> {
  GithubStateNotifier() : super(GithubState());

  Future<bool> validateToken(String token) async {
    final headers = {'Authorization': 'Bearer $token'};

    final response = await http.get(Uri.parse('https://api.github.com/user'),
        headers: headers);

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print("Utilisateur récupéré avec succès !");
      }
      return true;
    } else if (response.statusCode == 401) {
      state = state.copyWith(error: "Mauvaises informations d'identification. Vérifiez votre token.");
      if (kDebugMode) {
        print("Erreur: Bad credentials. Vérifiez votre token.");
      }
      return false;
    } else {
      state = state.copyWith(error: "Erreur inconnue.");
      if (kDebugMode) {
        print("Erreur inconnue: ${response.body}");
      }
      return false;
    }
  }

  Future<bool> validateRepo(String owner, String repo, String token) async {
    final headers = {'Authorization': 'token $token'};
    final response = await http.get(
        Uri.parse('https://api.github.com/repos/$owner/$repo'),
        headers: headers);

    if (response.statusCode == 200) {
      return true;
    } else {
      state = state.copyWith(error: "Dépôt introuvable ou inaccessible.");
      return false;
    }
  }

  Future<void> getRepoCommits(String owner, String repo, String token) async {
    if(await validateToken(token) && await validateRepo(owner, repo, token) ){
      try {
        state = state.copyWith(isLoading: true, error: '', processedCommits: 0);

        if (!await validateToken(token) ||
            !await validateRepo(owner, repo, token)) {
          state = state.copyWith(isLoading: false);
          return;
        }

        // Initialisation de l'appel API
        final headers = {'Authorization': 'token $token'};
        String url =
            'https://api.github.com/repos/$owner/$repo/commits?per_page=100';
        List<Commit> commits = [];
        List<Map<String, String>> avatarUrls = [];

        while (url.isNotEmpty) {
          final response = await http.get(Uri.parse(url), headers: headers);

          if (response.statusCode != 200) {
            state = state.copyWith(
                isLoading: false, error: "Erreur: ${response.statusCode}");
            return;
          }

          final jsonResponse = jsonDecode(response.body) as List;
          commits
              .addAll(jsonResponse.map((data) => Commit.fromJson(data)).toList());
          avatarUrls.addAll(jsonResponse
              .map((data) {
            return {
              'avatar_url': data['author']['avatar_url'],
              'login': data['author']['login'],
            };
          })
              .where((author) => author['login'] != null)
              .toSet()
              .map((e) => Map<String, String>.from(e)));

          final linkHeader = response.headers['link'];
          url = _getNextPageUrl(linkHeader);
        }

        state = state.copyWith(totalCommits: commits.length, avatarUrls: avatarUrls);

        List<Commit?> detailedCommits = await Future.wait(
          commits.map((commit) async {
            final commitResponse =
            await http.get(Uri.parse(commit.url), headers: headers);

            if (commitResponse.statusCode == 200) {
              final commitDetails = jsonDecode(commitResponse.body);
              state =
                  state.copyWith(processedCommits: state.processedCommits + 1);
              return Commit.fromJson(commitDetails);
            } else {
              return null;
            }
          }),
        );

        state = state.copyWith(
          isLoading: false,
          isReady: true,
          commits: detailedCommits.whereType<Commit>().toList(),
        );
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    } else{
      state = state.copyWith(isLoading: false);
    }
  }

  String _getNextPageUrl(String? linkHeader) {
    if (linkHeader != null && linkHeader.contains('rel="next"')) {
      var nextUrlMatch =
          RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
      return nextUrlMatch?.group(1) ?? '';
    }
    return '';
  }
}

//---------------------------------PROVIDER------------------------------------------//
final githubProvider =
    StateNotifierProvider<GithubStateNotifier, GithubState>((ref) {
  return GithubStateNotifier();
});
