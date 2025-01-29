import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_contributions/Providers/github_provider.dart';

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
    Match? match = githubUrlRegex.firstMatch(_repoUrl);
    String? owner = match?.group(1)!;
    String? repo = match?.group(2)!;
    return {"owner": owner!, "repo": repo!};
  }

  void inputValidation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        //step = "progressing";
        ref
            .read(githubProvider.notifier)
            .getRepoCommits(sep()["owner"]!, sep()["repo"]!, _token);
      });
      simulateProgress();
    }
  }

  void simulateProgress() async {
    setState(() {
      progress = (ref.watch(githubProvider).processedCommits * 100) /
          ref.watch(githubProvider).totalCommits;
    });
    setState(() {
      step = "results";
    });
  }

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
          onPressed: ref.read(githubProvider).isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColorSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          child: ref.read(githubProvider).isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: textColor,
                    strokeWidth: 2,
                  ),
                )
              : Text(
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
    final isReady = ref.watch(githubProvider).isReady;

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
          child: Container(
            height: 350,
            width: 300,
            padding: const EdgeInsets.all(24),
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: 1.0,
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
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(63, 219, 242, 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: textColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color.fromRGBO(255, 255, 255, 0.05),
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      height: 60,
                      margin: const EdgeInsets.symmetric(vertical: 20),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 500),
                        opacity: 1.0,
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
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: Color.fromRGBO(63, 219, 242, 0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: const BorderSide(
                                color: textColor,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor:
                                const Color.fromRGBO(255, 255, 255, 0.05),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildButton(
                      key: const Key('next_button'),
                      text: "Suivant",
                      onPressed: () {
                        inputValidation();
                        print(isLoading);
                      },
                    ),
                  ] else if (isLoading == true) ...[
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Validation en cours..."),
                  ] else if (isLoading == false && isReady == false) ...[

                    Text("Erreur: $error", style: TextStyle(
                      color: Colors.red,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),),
                    SizedBox(height: 25),
                    _buildButton(
                        key: const Key('retry_button'),
                        text: "Réessayer",
                        onPressed: () => setState(() => step = "token")),
                  ] else if (isReady == true) ...[
                    LinearPercentIndicator(
                      lineHeight: 14.0,
                      percent: progress,
                      backgroundColor: Colors.grey[300]!,
                      progressColor: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                        "Récupération des commits : ${(progress * 100).toStringAsFixed(0)}%"),
                  ] else if (ref.read(githubProvider).isReady == true) ...[
                    LinearPercentIndicator(
                      lineHeight: 14.0,
                      percent: progress,
                      backgroundColor: Colors.grey[300]!,
                      progressColor: Colors.blue,
                    ),
                    SizedBox(height: 16),
                    Text(
                        "Récupération des commits : ${(progress * 100).toStringAsFixed(0)}%"),
                  ] else if (step == "results") ...[
                    Text("Résultats disponibles !",
                        style: Theme.of(context).textTheme.titleLarge),
                    SizedBox(height: 16),
                    // Placeholder pour les graphiques
                    Placeholder(fallbackHeight: 200),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => setState(() => step = "token"),
                      child: Text("Recommencer"),
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
