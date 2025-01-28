import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../github_contributions_v2.dart';
import '../models/commit.dart';

class GithubService {
  final String githubToken;
  bool isLoading;
  bool isReady;

  GithubService(this.githubToken, {this.isLoading = false, this.isReady = false});

  Future<List<Commit>> getRepoCommits(String owner, String repo) async {
    try {
      isLoading = true;
      var headers = {
        'Authorization': 'token $githubToken',
      };

      String url = 'https://api.github.com/repos/$owner/$repo/commits?per_page=100';
      List<Commit> commits = [];

      while (url.isNotEmpty) {
        var response = await http.get(Uri.parse(url), headers: headers);

        if (response.statusCode == 404) {
          isLoading = false;
          throw Exception("Dépôt introuvable. Vérifiez le nom du propriétaire et du dépôt.");
        } else if (response.statusCode == 401) {
          isLoading = false;
          throw Exception("Token GitHub invalide ou non autorisé.");
        } else if (response.statusCode != 200) {
          isLoading = false;
          throw Exception("Erreur de connexion: ${response.statusCode}");
        }

        var jsonResponse = jsonDecode(response.body);
        commits.addAll((jsonResponse as List).map((commit) => Commit.fromJson(commit)).toList());

        // Gérer la pagination
        var linkHeader = response.headers['link'];
        if (linkHeader != null && linkHeader.contains('rel="next"')) {
          var nextUrlMatch = RegExp(r'<([^>]+)>; rel="next"').firstMatch(linkHeader);
          url = nextUrlMatch?.group(1) ?? '';
        } else {
          url = '';
        }
      }

      // Récupérer les détails de chaque commit (y compris les fichiers modifiés)
      List<Commit> detailedCommits = [];
      for (var commit in commits) {
        String commitUrl = commit.url;
        var commitResponse = await http.get(Uri.parse(commitUrl), headers: headers);

        if (commitResponse.statusCode != 200) {
          isLoading = false;
          throw Exception("Erreur lors de la récupération des détails du commit: ${commitResponse.statusCode}");
        }

        var commitDetails = jsonDecode(commitResponse.body);
        detailedCommits.add(Commit.fromJson(commitDetails));
        isLoading = false;
        isReady = true;
        showProgress(detailedCommits.length, commits.length);
      }
      isReady = false;
      return detailedCommits;
    } catch (e) {
      isLoading = false;
      isReady = false;
      throw Exception("Erreur lors de la récupération des détails du commit: $e");
    }
  }

  Map<String, double> calculateFinalContributions(List<Commit> commits) {
    Map<String, String> lineOwnership = {}; // Traque quelle ligne appartient à quel auteur
    Map<String, int> finalContributions = {}; // Contributions finales par auteur

    for (var commit in commits) {
      String author = commit.commit["author"]["name"];
      var files = commit.files ?? [];

      for (var file in files) {
        var patch = file['patch'] ?? '';

        if (patch.isNotEmpty) {
          for (var line in patch.split('\n')) {
            if (line.startsWith('+') && !line.startsWith('+++')) {
              // Ligne ajoutée : attribuer à l'auteur
              lineOwnership[line] = author;
            } else if (line.startsWith('-') && !line.startsWith('---')) {
              // Ligne supprimée : retirer de l'historique
              lineOwnership.remove(line);
            }
          }
        }
      }
    }

    // Compter les lignes finales attribuables à chaque auteur
    for (var entry in lineOwnership.entries) {
      finalContributions.update(entry.value, (value) => value + 1, ifAbsent: () => 1);
    }

    // Calculer les pourcentages
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

    return percentages;
  }
}