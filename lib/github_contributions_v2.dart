import 'dart:core';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'models/commit.dart';


void showProgress(int current, int total) {
  double progress = (current / total) * 100;
  stdout.write("\rProgression : [${'=' * (progress ~/ 5)}${' ' * (20 - (progress ~/ 5))}] ${progress.toStringAsFixed(2)}%");
  if (current == total) {
    stdout.writeln();
  }
}

Future<List<Commit>> getRepoCommits(String owner, String repo, String githubToken) async {
  try{
    var headers = {
      'Authorization': 'token $githubToken',
    };

    String url = 'https://api.github.com/repos/$owner/$repo/commits?per_page=100';
    List<Commit> commits = [];

    while (url.isNotEmpty) {
      var response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200) {
        throw Exception("Erreur lors de la récupération des commits: ${response.statusCode}");
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
        throw Exception("Erreur lors de la récupération des détails du commit: ${commitResponse.statusCode}");
      }

      var commitDetails = jsonDecode(commitResponse.body);
      detailedCommits.add(Commit.fromJson(commitDetails));
      showProgress(detailedCommits.length, commits.length);
    }
    return detailedCommits;
  } catch (e){
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
    print("Aucune ligne trouvée dans le projet final.");
    return {};
  }

  Map<String, double> percentages = {};
  for (var entry in finalContributions.entries) {
    percentages[entry.key] = (entry.value / totalLines) * 100;
  }

  return percentages;
}


/*void main() async {
  var env = DotEnv(includePlatformEnvironment: true)..load();
  String? githubToken = env['GITHUB_TOKEN'];
  if (githubToken == null) {
    print("La variable GITHUB_TOKEN n'est pas définie.");
    return;
  }

  print("Entrez l'URL du dépôt GitHub:");
  String repoUrl = stdin.readLineSync()!.trim();

  RegExp githubUrlRegex = RegExp(r'github\.com\/([^\/]+)\/([^\/]+)');
  Match? match = githubUrlRegex.firstMatch(repoUrl);

  if (match == null) {
    print("URL GitHub invalide.");
    return;
  }

  String owner = match.group(1)!;
  String repo = match.group(2)!;

  print("Propriétaire : $owner");
  print("Nom du dépôt : $repo");

  try {
    var commits = await getRepoCommits(owner, repo, githubToken);
    var contributions = calculateFinalContributions(commits);

    print("\nPourcentages de contribution par auteur:");
    for (var entry in contributions.entries) {
      print("${entry.key}: ${entry.value.toStringAsFixed(2)}%");
    }
  } catch (e) {
    print("Erreur : $e");
  }
}*/