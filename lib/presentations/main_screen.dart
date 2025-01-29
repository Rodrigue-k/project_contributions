import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/Providers/github_provider.dart';
import 'package:project_contributions/models/commit.dart';
import 'package:project_contributions/presentations/ressourses/app_colors.dart';
import 'package:project_contributions/utils/result_util.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen>
    with SingleTickerProviderStateMixin {
  static const Color textColor = Color(0xFF3FDBF2);
  static const Color backgroundColorSecondary = Color(0xFF0F394F);
  static const Color backgroundColor = Color(0xFF021124);

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _repoUrlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _token = '';
  String _repoUrl = '';
  double progress = 0.0;

  late final AnimationController _animationController = AnimationController(
    duration: const Duration(milliseconds: 300),
    vsync: this,
  );

  late final Animation<double> _scaleAnimation = Tween<double>(
    begin: 1.0,
    end: 0.95,
  ).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),
  );

  String step = "login";

  Map<String, String> sep() {
    RegExp githubUrlRegex = RegExp(r'github\.com/([^/]+)/([^/]+)');
    Match? match = githubUrlRegex.firstMatch(_repoUrl.trim());
    String? owner = match?.group(1)!;
    String? repo = match?.group(2)!;
    return {"owner": owner!, "repo": repo!};
  }

  void inputValidation() async {
    if (_formKey.currentState!.validate()) {
      //step = "progressing";
      await ref
          .read(githubProvider.notifier)
          .getRepoCommits(sep()["owner"]!, sep()["repo"]!, _token.trim());

      var commits = ref.read(githubProvider).commits;
      ref.read(githubProvider.notifier).calculateFinalContributions(commits);

      //simulateProgress();
    }
  }

  /*void simulateProgress() async {
    final totalCommits = ref.watch(githubProvider).totalCommits;
    final processedCommits = ref.watch(githubProvider).processedCommits;

    if (totalCommits > 0) {
      setState(() {
        progress = (processedCommits * 100) / totalCommits;
        print("progress $progress");
      });
    } else {
      setState(() {
        progress = 0.0;
      });
    }

    setState(() {
      step = "results";
    });
  }*/

  @override
  void dispose() {
    _tokenController.dispose();
    _repoUrlController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    Key? key,
  }) {
    return MouseRegion(
      key: key,
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColorSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 8,
            shadowColor: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = ref.watch(githubProvider).error;
    final isLoading = ref.watch(githubProvider).isLoading;
    final isProgressing = ref.watch(githubProvider).isProgressing;
    final isReady = ref.watch(githubProvider).isReady;
    final totalCommits = ref.watch(githubProvider).totalCommits;
    final processedCommits = ref.watch(githubProvider).processedCommits;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColorSecondary,
            ],
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOutCubic,
            height:
                isReady == true && processedCommits == totalCommits ? 500 : 350,
            width:
                isReady == true && processedCommits == totalCommits ? 400 : 300,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              borderRadius: BorderRadius.circular(40),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
              border: Border.all(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                width: 1,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (step == "login") ...[
                    _buildButton(
                      key: const Key('login_button'),
                      text: "Connexion GitHub",
                      onPressed: () => setState(() => step = "token"),
                    ),
                  ] else if (step == "token") ...[
                    Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: TextFormField(
                        key: const Key('token_field'),
                        controller: _tokenController,
                        onChanged: (value) => _token = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un token valide';
                          }
                          return null;
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'GitHub Token',
                          hintStyle: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(63, 219, 242, 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: textColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                      ),
                    ),
                    Container(
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: TextFormField(
                        key: const Key('repo_url_field'),
                        controller: _repoUrlController,
                        onChanged: (value) => _repoUrl = value,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une URL de dépôt valide';
                          }
                          final urlPattern =
                              r'^(https?:\/\/)?(www\.)?github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\/?$';
                          if (!RegExp(urlPattern).hasMatch(value)) {
                            return 'Veuillez entrer une URL GitHub valide';
                          }
                          return null;
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'URL du dépôt GitHub',
                          hintStyle: const TextStyle(
                            color: Color.fromRGBO(255, 255, 255, 0.7),
                            fontWeight: FontWeight.w500,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Color.fromRGBO(63, 219, 242, 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: textColor,
                              width: 2,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: Colors.red,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(255, 255, 255, 0.05),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildButton(
                      key: const Key('next_button'),
                      text: "Suivant",
                      onPressed: () => setState(() {
                        step = "progressing";
                        inputValidation();
                        if (kDebugMode) {
                          print(isLoading);
                        }
                      }),
                    ),
                  ] else if (isLoading == true) ...[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Validation en cours..."),
                  ] else if (error.isNotEmpty) ...[
                    Text(
                      "Erreur: $error",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 25),
                    _buildButton(
                      key: const Key('retry_button'),
                      text: "Réessayer",
                      onPressed: () => setState(() => step = "token"),
                    ),
                  ] else if (isProgressing == true) ...[
                    LinearPercentIndicator(
                      width: 260,
                      animation: true,
                      lineHeight: 20.0,
                      percent: totalCommits == 0
                          ? 0.0
                          : processedCommits / totalCommits,
                      center: Text(
                        "${(totalCommits == 0 ? 0 : (processedCommits / totalCommits) * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      barRadius: Radius.circular(10.0),
                      progressColor: backgroundColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                        "Récupération des commits : $processedCommits/$totalCommits"),
                    SizedBox(height: 40),
                    _buildButton(
                      key: const Key('retry_button'),
                      text: "Réessayer",
                      onPressed: () => setState(() => step = "token"),
                    ),
                  ] else if (isReady == true &&
                      processedCommits == totalCommits) ...[
                    Text("Résultats disponibles !",
                        style: TextStyle(
                          color: textColor,
                          fontSize: 25,
                        )),
                    SizedBox(height: 16),
                    Result(),
                    SizedBox(height: 05),
                    _buildButton(
                      key: const Key('retry_button'),
                      text: "Relancer",
                      onPressed: () => setState(() => step = "token"),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
