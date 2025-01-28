import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../github_contributions_v2.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with SingleTickerProviderStateMixin {
  static const Color textColor = Color(0xFF3FDBF2);
  static const Color backgroundColorSecondary = Color(0xFF0F394F);
  static const Color backgroundColor = Color(0xFF021124);

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _repoUrlController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  String _token = '';
  String _repoUrl = '';
  bool _showTextField = false;
  bool _showResult = false;
  bool _isLoading = false;

  Map<String, double> _contributions = {};

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _showResult = true;
    });
    if (_formKey.currentState!.validate()) {
      RegExp githubUrlRegex = RegExp(r'github\.com/([^/]+)/([^/]+)');
      Match? match = githubUrlRegex.firstMatch(_repoUrl);

      String? owner = match?.group(1)!;
      String? repo = match?.group(2)!;

      if (kDebugMode) {
        print("Propriétaire : $owner");
        print("Nom du dépôt : $repo");
      }

      try {
        var commits = await getRepoCommits(owner!, repo!, _token);
        var contributions = calculateFinalContributions(commits);

        setState(() {
          _contributions = calculateFinalContributions(commits);
          _isLoading = false;
        });

        if (kDebugMode) {
          print("\nPourcentages de contribution par auteur:");
          for (var entry in contributions.entries) {
            print("${entry.key}: ${entry.value.toStringAsFixed(2)}%");
          }
        }

        setState(() => _isLoading = false);
      } catch (e) {
        setState(() => _isLoading = false);
        if (kDebugMode) {
          print("Erreur : $e");
        }
      }
    }
  }

  Widget _buildResultsView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var entry in _contributions.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "${entry.value.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 1000),
                    tween: Tween<double>(begin: 0, end: entry.value / 100),
                    builder: (context, double value, _) =>
                        LinearProgressIndicator(
                      value: value,
                      backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(textColor),
                      minHeight: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
      ],
    );
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
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColorSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color.fromRGBO(0, 0, 0, 0.5),
          ),
          child: _isLoading
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
    return Scaffold(
      backgroundColor: backgroundColor,
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
            child: _showResult
                ? _buildResultsView()
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!_showTextField)
                          _buildButton(
                            key: const Key('login_button'),
                            text: "Connexion GitHub",
                            onPressed: () =>
                                setState(() => _showTextField = true),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: _showTextField ? 60 : 0,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _showTextField ? 1.0 : 0.0,
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
                          height: _showTextField ? 60 : 0,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 500),
                            opacity: _showTextField ? 1.0 : 0.0,
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
                        if (_showTextField)
                          _buildButton(
                            key: const Key('next_button'),
                            text: "Suivant",
                            onPressed: () {
                              _submit();
                            },
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
