import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const YBEYAPP());
}

class MyApp extends StatelessWidget {
  const YBEYAPP({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(child: Text("Firebase Connected ✅")),
      ),
    );
  }
}


void main() {
  runApp(const YBEYApp());
}

class WelcomeAudioController {
  WelcomeAudioController._() {
    _player.onPlayerComplete.listen((_) {
      _markCompleted();
    });
  }

  static final WelcomeAudioController instance = WelcomeAudioController._();

  final AudioPlayer _player = AudioPlayer();
  FlutterTts? _tts;
  bool started = false;
  bool completed = false;
  bool blocked = false;
  String? lastError;
  String? lastAssetTried;
  Completer<void>? _completion;

  static const List<String> _assetCandidates = <String>[
    'assets/audio/welcome.mp3',
    'assets/audio/welcome.mpeg',
    'audio/welcome.mp3',
    'audio/welcome.mpeg',
  ];

  Future<void> start({bool userInitiated = false}) async {
    if (completed) return;
    if (started && !blocked) return;

    blocked = false;
    lastError = null;
    lastAssetTried = null;
    started = true;
    completed = false;
    _completion ??= Completer<void>();

    for (final String assetPath in _assetCandidates) {
      try {
        lastAssetTried = assetPath;
        await _player.setVolume(1.0);
        await _player.play(AssetSource(assetPath));
        await _player.setVolume(1.0);
        return;
      } catch (e) {
        lastError = e.toString();
        if (kIsWeb && !userInitiated) {
          started = false;
          completed = false;
          blocked = true;
          return;
        }
      }
    }

    _tts ??= FlutterTts();
    await _tts?.setSpeechRate(0.45);
    await _tts?.setVolume(1.0);
    _tts?.setErrorHandler((dynamic _) async {
      _markCompleted();
    });
    _tts?.setCompletionHandler(() async {
      _markCompleted();
    });

    try {
      await _tts?.speak('Welcome to YBEY Web Site');
    } catch (e) {
      lastError = e.toString();
      _markCompleted();
    }
  }

  void handleUserInteraction() {
    if (!blocked || completed) return;
    unawaited(start(userInitiated: true));
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts?.stop();
    } catch (_) {}
  }

  void _markCompleted() {
    if (completed) return;
    completed = true;
    blocked = false;
    started = true;
    _completion?.complete();
    _completion = null;
  }
}

class ApiConfig {
  static const String _envBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get baseUrl {
    final String fromEnv = _envBaseUrl.trim();
    if (fromEnv.isNotEmpty) {
      return fromEnv.endsWith('/') ? fromEnv.substring(0, fromEnv.length - 1) : fromEnv;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    return 'http://10.0.2.2:8000';
  }
}

class RegistrationData extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String _problemDescription = '';
  bool _rememberMe = false;

  String? _emailErrorKey;
  String? _passwordErrorKey;
  String _languageCode;

  // Static map for error message translations
  static const Map<String, Map<String, String>> _errorTranslations = {
    'EN': {
      'emailEmptyError': 'Email cannot be empty',
      'emailInvalidError': 'Enter a valid email address',
      'passwordEmptyError': 'Password cannot be empty',
      'passwordLengthError': 'Password must be at least 6 characters',
      'confirmPasswordEmptyError': 'Confirm password cannot be empty',
      'passwordsMismatchError': 'Passwords do not match',
    },
    'HI': {
      'emailEmptyError': 'ईमेल खाली नहीं हो सकता',
      'emailInvalidError': 'एक वैध ईमेल पता दर्ज करें',
      'passwordEmptyError': 'पासवर्ड खाली नहीं हो सकता',
      'passwordLengthError': 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए',
      'confirmPasswordEmptyError': 'पासवर्ड की पुष्टि खाली नहीं हो सकती',
      'passwordsMismatchError': 'पासवर्ड मेल नहीं खाते',
    },
    'TA': {
      'emailEmptyError': 'மின்னஞ்சல் காலியாக இருக்கக்கூடாது',
      'emailInvalidError': 'சரியான மின்னஞ்சல் முகவரியை உள்ளிடவும்',
      'passwordEmptyError': 'கடவுச்சொல் காலியாக இருக்கக்கூடாது',
      'passwordLengthError': 'கடவுச்சொல் குறைந்தபட்சம் 6 எழுத்துகள் இருக்க வேண்டும்',
      'confirmPasswordEmptyError': 'கடவுச்சொல்லை உறுதிப்படுத்தவும் காலியாக இருக்கக்கூடாது',
      'passwordsMismatchError': 'கடவுச்சொற்கள் பொருந்தவில்லை',
    },
    'TE': {
      'emailEmptyError': 'ఇమెయిల్ ఖాళీగా ఉండకూడదు',
      'emailInvalidError': 'చెల్లుబాటు అయ్యే ఇమెయిల్ చిరునామాను నమోదు చేయండి',
      'passwordEmptyError': 'పాస్‌వర్డ్ ఖాళీగా ఉండకూడదు',
      'passwordLengthError': 'పాస్‌వర్డ్ కనీసం 6 అక్షరాలు ఉండాలి',
      'confirmPasswordEmptyError': 'పాస్‌వర్డ్‌ను నిర్ధారించండి ఖాళీగా ఉండకూడదు',
      'passwordsMismatchError': 'పాస్‌వర్డ్‌లు సరిపోలడం లేదు',
    },
    'KN': {
      'emailEmptyError': 'ಇಮೇಲ್ ಖಾಲಿಯಾಗಿರಬಾರದು',
      'emailInvalidError': 'ಮಾನ್ಯವಾದ ಇಮೇಲ್ ವಿಳಾಸವನ್ನು ನಮೂದಿಸಿ',
      'passwordEmptyError': 'ಪಾಸ್‌ವರ್ಡ್ ಖಾಲಿಯಾಗಿರಬಾರದು',
      'passwordLengthError': 'ಪಾಸ್‌ವರ್ಡ್ ಕನಿಷ್ಠ 6 ಅಕ್ಷರಗಳನ್ನು ಹೊಂದಿರಬೇಕು',
      'confirmPasswordEmptyError': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ ಖಾಲಿಯಾಗಿರಬಾರದು',
      'passwordsMismatchError': 'ಪಾಸ್‌ವರ್ಡ್‌ಗಳು ಹೊಂದಿಕೆಯಾಗುವುದಿಲ್ಲ',
    },
    'ML': {
      'emailEmptyError': 'ഇമെയിൽ ശൂന്യമായിരിക്കാൻ പാടില്ല',
      'emailInvalidError': 'സാധുവായ ഒരു ഇമെയിൽ വിലാസം നൽകുക',
      'passwordEmptyError': 'പാസ്‌വേഡ് ശൂന്യമായിരിക്കാൻ പാടില്ല',
      'passwordLengthError': 'പാസ്‌വേഡിന് കുറഞ്ഞത് 6 അക്ഷരങ്ങൾ ഉണ്ടായിരിക്കണം',
      'confirmPasswordEmptyError': 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക ശൂന്യമായിരിക്കാൻ പാടില്ല',
      'passwordsMismatchError': 'പാസ്‌വേഡുകൾ പൊരുത്തപ്പെടുന്നില്ല',
    },
  };

  String get name => _name;
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get problemDescription => _problemDescription;
  bool get rememberMe => _rememberMe;
  String get languageCode => _languageCode;

  String? get emailError {
    if (_emailErrorKey == null) return null;
    return _errorTranslations[_languageCode]![_emailErrorKey!];
  }

  String? get passwordError {
    if (_passwordErrorKey == null) return null;
    return _errorTranslations[_languageCode]![_passwordErrorKey!];
  }

  RegistrationData({String languageCode = 'EN'})
      : _languageCode = languageCode {
    _validateForm();
  }

  void updateName(String value) {
    _name = value;
    _validateForm();
    notifyListeners();
  }

  void updateEmail(String value) {
    _email = value;
    _validateForm();
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    _validateForm();
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    _validateForm();
    notifyListeners();
  }

  void updateProblemDescription(String value) {
    _problemDescription = value;
    notifyListeners();
  }

  void updateRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void updateLanguageCode(String newCode) {
    if (_languageCode != newCode) {
      _languageCode = newCode;
      _validateForm();
      notifyListeners();
    }
  }

  void _validateForm() {
    if (_email.isEmpty) {
      _emailErrorKey = 'emailEmptyError';
    } else if (!_email.contains('@')) {
      _emailErrorKey = 'emailInvalidError';
    } else {
      _emailErrorKey = null;
    }

    if (_password.isEmpty) {
      _passwordErrorKey = 'passwordEmptyError';
    } else if (_password.length < 6) {
      _passwordErrorKey = 'passwordLengthError';
    } else if (_confirmPassword.isEmpty && _password.isNotEmpty) {
      _passwordErrorKey = 'confirmPasswordEmptyError';
    } else if (_password != _confirmPassword &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty) {
      _passwordErrorKey = 'passwordsMismatchError';
    } else {
      _passwordErrorKey = null;
    }
  }

  bool get isFormValid {
    return _name.isNotEmpty &&
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _emailErrorKey == null &&
        _passwordErrorKey == null;
  }

  Future<void> submitRegistration(BuildContext context) async {
    if (isFormValid) {
      try {
        final String baseUrl = ApiConfig.baseUrl;

        final http.Response response = await http.post(
          Uri.parse('$baseUrl/api/register'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, dynamic>{
            'username': _name,
            'email': _email,
            'password': _password,
            'confirm_password': _confirmPassword,
            'problem_description': _problemDescription,
            'remember_me': _rememberMe,
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('Registration successful: ${response.body}');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Registration Successful!')),
            );
          }

          _name = '';
          _email = '';
          _password = '';
          _confirmPassword = '';
          _problemDescription = '';
          _validateForm();
          notifyListeners();
        } else {
          debugPrint('Registration failed: ${response.body}');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Registration Failed: ${response.body}')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error connecting to backend: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connection Error: $e')),
          );
        }
      }
    } else {
      debugPrint('Form is invalid. Cannot submit.');
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _splashController;
  late final Animation<double> _scaleAnimation;
  bool _navigated = false;
  bool _navigationScheduled = false;
  late final DateTime _splashStartedAt;
  bool _soundDialogShown = false;

  static const String _splashImageUrl =
      "https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg";
  static const Duration _minSplashDuration = Duration(seconds: 3);
  static const Duration _maxSplashDuration = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    _splashStartedAt = DateTime.now();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.75, end: 1.04).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );

    unawaited(WelcomeAudioController.instance.start());

    Future.delayed(_minSplashDuration, _maybeProceedToApp);
    Future.delayed(_maxSplashDuration, _proceedToApp);
  }

  void _maybeProceedToApp() {
    if (!mounted || _navigated) return;
    final Duration elapsed = DateTime.now().difference(_splashStartedAt);
    if (elapsed < _minSplashDuration) return;
    final WelcomeAudioController audio = WelcomeAudioController.instance;
    if (audio.started && !audio.completed) return;
    _proceedToApp();
  }

  Future<void> _proceedToApp() async {
    if (!mounted || _navigated || _navigationScheduled) return;
    _navigationScheduled = true;
    _navigated = true;
    _splashController.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const YBEYHomePage()),
    );
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final WelcomeAudioController audio = WelcomeAudioController.instance;
    if (kIsWeb && audio.blocked && !_soundDialogShown) {
      _soundDialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Enable sound'),
              content: const Text(
                'Browser autoplay is blocked. Tap Enable to play the welcome audio.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Not now'),
                ),
                TextButton(
                  onPressed: () {
                    unawaited(audio.start(userInitiated: true));
                    Navigator.of(dialogContext).pop();
                    if (mounted) {
                      setState(() {});
                    }
                  },
                  child: const Text('Enable'),
                ),
              ],
            );
          },
        );
      });
    }
    return Scaffold(
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => setState(() => audio.handleUserInteraction()),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                Color(0xFF11526D),
                Color(0xFF3B9E59),
              ],
            ),
          ),
          child: Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Tooltip(
                    message: 'Loading',
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2F8F6B),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                          width: 3,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: const Color.fromARGB(255, 9, 125, 174)
                                .withOpacity(0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 140,
                          height: 140,
                          fit: BoxFit.cover,
                          errorBuilder: (BuildContext context, Object error,
                              StackTrace? s) {
                            return Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to YBEY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (audio.lastError != null && !audio.blocked) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      'Sound error. Try MP3 file. (${audio.lastAssetTried ?? 'unknown'})',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

class YBEYApp extends StatelessWidget {
  const YBEYApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YBEY',
      debugShowCheckedModeBanner: false,
      builder: (BuildContext context, Widget? child) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => WelcomeAudioController.instance.handleUserInteraction(),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.icon,
    this.errorText,
  });

  final String label;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final IconData? icon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: icon != null ? Icon(icon, color: Colors.white70) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.white),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }
}


class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  late TextEditingController _problemDescriptionController;

  @override
  void initState() {
    super.initState();
    _problemDescriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _problemDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the current language from RegistrationData
    final registrationData = Provider.of<RegistrationData>(context, listen: false);
    
    // Get translations based on the language code
    final currentTranslations = _getTranslations(registrationData.languageCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTranslations['registerAppBarTitle']!,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF11526D),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              Color(0xFF11526D),
              Color(0xFF3B9E59),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Consumer<RegistrationData>(
              builder: (BuildContext context, RegistrationData registrationData,
                  Widget? child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      currentTranslations['registrationMainText']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 30),
                    CustomTextFormField(
                      label: currentTranslations['userNameLabel']!,
                      initialValue: registrationData.name,
                      onChanged: registrationData.updateName,
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      label: currentTranslations['emailLabel']!,
                      initialValue: registrationData.email,
                      onChanged: registrationData.updateEmail,
                      keyboardType: TextInputType.emailAddress,
                      icon: Icons.email,
                      errorText: registrationData.emailError,
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      label: currentTranslations['passwordLabel']!,
                      initialValue: registrationData.password,
                      onChanged: registrationData.updatePassword,
                      obscureText: true,
                      icon: Icons.lock,
                      errorText: registrationData.passwordError,
                    ),
                    const SizedBox(height: 20),
                    CustomTextFormField(
                      label: currentTranslations['confirmPasswordLabel']!,
                      initialValue: registrationData.confirmPassword,
                      onChanged: registrationData.updateConfirmPassword,
                      obscureText: true,
                      icon: Icons.lock_reset,
                      errorText: registrationData.passwordError,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _problemDescriptionController,
                      onChanged: registrationData.updateProblemDescription,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: currentTranslations['problemDescriptionLabel'] ?? 'Problem Description (Optional)',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: currentTranslations['problemDescriptionHint'] ?? 'Describe any issues...',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                          borderSide: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: <Widget>[
                        Checkbox(
                          value: registrationData.rememberMe,
                          onChanged: (bool? value) =>
                              registrationData.updateRememberMe(value ?? false),
                          activeColor: Colors.white,
                          checkColor: const Color(0xFF11526D),
                        ),
                        Text(
                          currentTranslations['rememberMe']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: registrationData.isFormValid
                          ? () {
                              registrationData.submitRegistration(context);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF11526D),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(currentTranslations['registerButton']!),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get translations
  Map<String, String> _getTranslations(String languageCode) {
    final allTranslations = {
      'EN': {
        'registerAppBarTitle': 'Register for Early Access',
        'registrationMainText': 'Join the YBEY movement now!',
        'userNameLabel': 'User Name',
        'emailLabel': 'Email',
        'passwordLabel': 'Password',
        'confirmPasswordLabel': 'Confirm Password',
        'problemDescriptionLabel': 'Problem Description (Optional)',
        'problemDescriptionHint': 'Describe any issues you want help with...',
        'rememberMe': 'Remember Me',
        'registerButton': 'Register',
      },
      'HI': {
        'registerAppBarTitle': 'अर्ली एक्सेस के लिए रजिस्टर करें',
        'registrationMainText': 'अभी YBEY आंदोलन में शामिल हों!',
        'userNameLabel': 'यूज़र नेम',
        'emailLabel': 'ईमेल',
        'passwordLabel': 'पासवर्ड',
        'confirmPasswordLabel': 'पासवर्ड की पुष्टि करें',
        'problemDescriptionLabel': 'समस्या विवरण (वैकल्पिक)',
        'problemDescriptionHint': 'किसी भी समस्या का वर्णन करें...',
        'rememberMe': 'मुझे याद रखें',
        'registerButton': 'रजिस्टर करें',
      },
      'TA': {
        'registerAppBarTitle': 'முன்கூட்டிய அணுகலுக்குப் பதிவு செய்யவும்',
        'registrationMainText': 'இப்போதே YBEY இயக்கத்தில் இணையுங்கள்!',
        'userNameLabel': 'பயனர் பெயர்',
        'emailLabel': 'மின்னஞ்சல்',
        'passwordLabel': 'கடவுச்சொல்',
        'confirmPasswordLabel': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
        'problemDescriptionLabel': 'சிக்கல் விளக்கம் (விருப்பமானது)',
        'problemDescriptionHint': 'ஏதேனும் சிக்கல்களை விவரிக்கவும்...',
        'rememberMe': 'என்னை நினைவில் வைத்துக்கொள்',
        'registerButton': 'பதிவு செய்யவும்',
      },
      'TE': {
        'registerAppBarTitle': 'ముందస్తు ప్రవేశం కోసం నమోదు చేసుకోండి',
        'registrationMainText': 'ఇప్పుడే YBEY ఉద్యమంలో చేరండి!',
        'userNameLabel': 'వినియోగదారు పేరు',
        'emailLabel': 'ఇమెయిల్',
        'passwordLabel': 'పాస్‌వర్డ్',
        'confirmPasswordLabel': 'పాస్‌వర్డ్‌ను నిర్ధారించండి',
        'problemDescriptionLabel': 'సమస్య వివరణ (ఐచ్ఛికం)',
        'problemDescriptionHint': 'ఏదైనా సమస్యలను వివరించండి...',
        'rememberMe': 'నన్ను గుర్తుంచుకోండి',
        'registerButton': 'నమోదు చేయండి',
      },
      'KN': {
        'registerAppBarTitle': 'ಮುಂಚಿತ ಪ್ರವೇಶಕ್ಕಾಗಿ ನೋಂದಾಯಿಸಿ',
        'registrationMainText': 'ಈಗಲೇ YBEY ಆಂದೋಲನಕ್ಕೆ ಸೇರಿಕೊಳ್ಳಿ!',
        'userNameLabel': 'ಬಳಕೆದಾರ ಹೆಸರು',
        'emailLabel': 'ಇಮೇಲ್',
        'passwordLabel': 'ಪಾಸ್‌ವರ್ಡ್',
        'confirmPasswordLabel': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
        'problemDescriptionLabel': 'ಸಮಸ್ಯೆ ವಿವರಣೆ (ಐಚ್ಛಿಕ)',
        'problemDescriptionHint': 'ಯಾವುದೇ ಸಮಸ್ಯೆಗಳನ್ನು ವಿವರಿಸಿ...',
        'rememberMe': 'ನನ್ನನ್ನು ನೆನಪಿಡಿ',
        'registerButton': 'ನೋಂದಾಯಿಸಿ',
      },
      'ML': {
        'registerAppBarTitle': 'തുടക്കത്തിലുള്ള പ്രവേശനത്തിനായി രജിസ്റ്റർ ചെയ്യുക',
        'registrationMainText': 'ഇപ്പോൾ YBEY പ്രസ്ഥാനത്തിൽ ചേരുക!',
        'userNameLabel': 'ഉപയോക്തൃനാമം',
        'emailLabel': 'ഇമെയിൽ',
        'passwordLabel': 'പാസ്‌വേഡ്',
        'confirmPasswordLabel': 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക',
        'problemDescriptionLabel': 'പ്രശ്ന വിവരണം (ഓപ്ഷണൽ)',
        'problemDescriptionHint': 'എന്തെങ്കിലും പ്രശ്നങ്ങൾ വിവരിക്കുക...',
        'rememberMe': 'എന്നെ ഓർക്കുക',
        'registerButton': 'രജിസ്റ്റർ ചെയ്യുക',
      },
    };
    
    return allTranslations[languageCode] ?? allTranslations['EN']!;
  }
}

class YBEYHomePage extends StatefulWidget {
  const YBEYHomePage({super.key});

  @override
  State<YBEYHomePage> createState() => _YBEYHomePageState();
}

class _YBEYHomePageState extends State<YBEYHomePage>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  late final AnimationController _bgController;
  late final Animation<Color?> _bgColor1;
  late final Animation<Color?> _bgColor2;

  bool _contentVisible = true; // Content visible by default

  String _selectedLanguage = 'EN'; // Default to English

  static const String _placeholderImageUrl =
      "https://www.gstatic.com/flutter-onestack-prototype/genui/example_1.jpg";

  // Define translation maps for all languages
  final Map<String, String> _enStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'YOU BECOME YOURSELF',
    'mainDescription':
        "The system for disciplined living — mind, body, and lifestyle.\n\nBuilt for you — to help you find focus, discipline, and the real transformation, without slipping back into old habits.",
    'getEarlyAccess': 'Get Early Access',
    'whatYbeyWillDo': 'WHAT YBEY WILL DO FOR YOU',
    'benefit1': 'Transform with a system that actually works.',
    'benefit2': 'Build discipline with structured daily routines',
    'benefit3': 'Control your mind: urges, overthinking, and distractions',
    'benefit4': 'Follow physical transformation plans (home + gym)',
    'benefit5': 'Track your mood, progress, habits, and journey',
    'benefit6': 'Stay consistent with AI guidance tailored to you',
    'benefit7': 'Grow with a community aiming for the same goals',
    'benefit8': 'Provide specialist help for healing mentally & physically',
    'benefit9': 'It helps you to achieve your potential',
    'benefit10': 'Data security',
    'benefit11': 'Partner who will grow with you',
    'whyYbeyExists': 'WHY YBEY EXISTS',
    'whyExistsDesc1': 'Made for young people who want a comeback.',
    'whyExistsDesc2':
        "Ybey is built for those who know they can be more — but lack the structure, support, and help. This app gives you a daily system to rebuild your life from the inside out ( Your data is 100% secured with us ).",
    'earlyAccessRewards': 'EARLY ACCESS REWARDS',
    'earlyAccessDesc': 'Join before launch and get:',
    'reward1': 'Reserved username',
    'reward2': 'Priority access to beta features',
    'reward3': 'Founding Member status (limited to the first 1000)',
    'reward4': 'Be the first to shape the future of Ybey',
    'communityEnergy': 'COMMUNITY ENERGY',
    'communityDesc1': 'Join youth transformation movement.',
    'communityDesc2':
        'A generation breaking distraction, addiction, and inconsistency — and building discipline, strength, and purpose.',
    'aboutFounder': 'ABOUT FOUNDER',
    'founderMessage':
        "I built Ybey after seeing the same cycle everywhere:\nBig goals on Sunday.\nBurnout by Wednesday.\nGym memberships unused.\nSelf-help books unfinished.\nAnother “fresh start” that dies in a week.\n\nThe problem isn't laziness.\nThe real gap is between wanting to change and actually changing.\n\nMotivation disappears.\nDiscipline collapses without structure.\nAnd an entire generation is stuck restarting again and again.\n\nThat's why Ybey exists.\n\nNot another pep talk.\nNot another “just be consistent” lecture.\nBut a system — built on psychology, behavior science, and daily execution.\n\nTools for when motivation dies.\nStructure for when your mind slips.\nA framework that rebuilds your mind, body, and lifestyle — one day at a time.\n\nFor anyone done with excuses and ready for actual transformation.",
    'founderNote':
        "Note\n\n“Ybey was created with one mission: to give young people a real system to rebuild their mind, body, and lifestyle — not with motivation, but with structure.”",
    'connectWithUs': 'CONNECT WITH US',
    'whatsappCommunity': 'WhatsApp Community',
    'instagram': 'Instagram',
    'youtube': 'YouTube',
    'registerAppBarTitle': 'Register for Early Access',
    'registrationMainText': 'Join the YBEY movement now!',
    'userNameLabel': 'user name',
    'emailLabel': 'Email',
    'passwordLabel': 'Password',
    'confirmPasswordLabel': 'Confirm Password',
    'rememberMe': 'Remember Me',
    'registerButton': 'Register',
  };

  final Map<String, String> _hiStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'YOU BECOME YOURSELF',
    'mainDescription':
        "डिसिप्लिन्ड लाइफ के लिए सिस्टम — Mind, Body और Lifestyle के लिए।\n\nतुम्हारे लिए बना — ताकि तुम Focus, Discipline और Real Transformation पा सको, बिना बार‑बार पुरानी आदतों में फिसले।",
    'getEarlyAccess': 'जल्दी जुड़ें',
    'whatYbeyWillDo': 'YBEY आपके लिए क्या करेगा',
    'benefit1': 'ऐसी प्रणाली जो सच में काम करती है।',
    'benefit2': 'रोज़ के स्ट्रक्चर से अनुशासन बनाओ।',
    'benefit3': 'मन पर नियंत्रण: इच्छाएँ, ओवरथिंकिंग और भटकाव।',
    'benefit4': 'फिजिकल ट्रांसफॉर्मेशन प्लान (होम + जिम) फॉलो करो।',
    'benefit5': 'मूड, प्रोग्रेस, आदतें और जर्नी ट्रैक करो।',
    'benefit6': 'तुम्हारे लिए बने हुए AI गाइडेंस से Consistent रहो।',
    'benefit7': 'उसी गोल्स वाली कम्युनिटी के साथ Grow करो।',
    'benefit8': 'मानसिक और शारीरिक रूप से स्वस्थ होने के लिए विशेषज्ञ सहायता प्रदान करना',
    'benefit9': 'यह आपको अपनी क्षमता हासिल करने में मदद करता है',
    'benefit10': 'डेटा सुरक्षा',
    'benefit11': 'एक साथी जो आपके साथ बढ़ेगा',
    'whyYbeyExists': 'YBEY क्यों मौजूद है',
    'whyExistsDesc1': 'उन युवाओं के लिए जो वापस उठना चाहते हैं।',
    'whyExistsDesc2':
        "YBey उन लोगों के लिए बनाया गया है जो जानते हैं कि वे अधिक कर सकते हैं — लेकिन उन्हें सही ढांचे, समर्थन और उपचार की कमी है। यह ऐप आपको अपने जीवन को अंदर से बाहर तक पुनर्निर्माण करने के लिए एक दैनिक प्रणाली प्रदान करता है। आपका डेटा 100% हमारे साथ सुरक्षित है।",
    'earlyAccessRewards': 'अर्ली एक्सेस रिवार्ड्स',
    'earlyAccessDesc': 'लॉन्च से पहले जुड़ें और पाएँ:',
    'reward1': 'आपका यूज़रनेम पहले से Reserve रहेगा',
    'reward2': 'Beta features का Priority access',
    'reward3': 'Founding Member status (पहले 1000 लोगों के लिए)',
    'reward4': 'Ybey के Future को Shape करने वाले सबसे पहले लोगों में बनो',
    'communityEnergy': 'कम्युनिटी एनर्जी',
    'communityDesc1': 'युवा ट्रांसफॉर्मेशन मूवमेंट से जुड़ो।',
    'communityDesc2':
        'एक ऐसी पीढ़ी जो Distraction, Addiction और Inconsistency को तोड़ रही है — और Discipline, Strength और Purpose बना रही है।',
    'aboutFounder': 'संस्थापक के बारे में',
    'founderMessage':
        "मैंने Ybey तब बनाया जब हर जगह एक जैसा Pattern देखा:\nSunday को बड़े Goals.\nWednesday तक Burnout.\nGym membership इस्तेमाल ही नहीं होती।\nSelf-help किताबें अधूरी रह जाती हैं।\nहर हफ्ते नया “fresh start” — जो एक हफ्ते में खत्म हो जाता है।\n\nसमस्या आलस नहीं है।\nअसल कमी है Change चाहने और सच में Change करने के बीच।\n\nMotivation गायब हो जाती है।\nStructure के बिना Discipline टूट जाता है।\nऔर पूरी एक Generation बार‑बार वहीं से शुरू करने पर मजबूर है।\n\nइसीलिए Ybey बना।\n\nना एक और pep talk।\nना एक और “बस Consistent रहो” वाली Lecture।\nबल्कि एक System — जो Psychology, Behaviour Science और Daily Execution पर बना है।\n\nजब Motivation मर जाए तो Tools।\nजब Mind फिसले तो Structure।\nऐसा Framework जो Mind, Body और Lifestyle को एक‑एक दिन में दोबारा बनाता है।\n\nउन सबके लिए जो बहाने खत्म करके सच में Transformation चाहते हैं।",
    'founderNote':
        "नोट\n\n“Ybey एक ही मिशन के साथ बनाया गया: युवाओं को एक Real System देना, जिससे वे अपना Mind, Body और Lifestyle दोबारा बना सकें — Motivation से नहीं, Structure से।”",
    'connectWithUs': 'हमसे कनेक्ट हों',
    'whatsappCommunity': 'व्हाट्सएप कम्युनिटी',
    'instagram': 'इंस्टाग्राम',
    'youtube': 'यूट्यूब',
    'registerAppBarTitle': 'अर्ली एक्सेस के लिए रजिस्टर करें',
    'registrationMainText': 'अभी YBEY आंदोलन में शामिल हों!',
    'userNameLabel': 'यूज़र नेम',
    'emailLabel': 'ईमेल',
    'passwordLabel': 'पासवर्ड',
    'confirmPasswordLabel': 'पासवर्ड की पुष्टि करें',
    'rememberMe': 'मुझे याद रखें',
    'registerButton': 'रजिस्टर करें',
  };

  final Map<String, String> _taStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'நீங்களே ஆகுங்கள்',
    'mainDescription':
        "ஒழுக்கமான வாழ்க்கைக்கான அமைப்பு — மனம், உடல் மற்றும் வாழ்க்கை முறைக்கு.\n\nஉங்களுக்காக உருவாக்கப்பட்டது — கவனம், ஒழுக்கம் மற்றும் உண்மையான மாற்றத்தைக் கண்டறிய, பழைய பழக்கவழக்கங்களுக்கு மீண்டும் செல்லாமல் இருக்க.",
    'getEarlyAccess': 'முன்கூட்டிய அணுகலைப் பெறுங்கள்',
    'whatYbeyWillDo': 'YBEY உங்களுக்கு என்ன செய்யும்',
    'benefit1': 'உண்மையில் செயல்படும் ஒரு அமைப்புடன் மாற்றியமைக்கவும்.',
    'benefit2': 'கட்டமைக்கப்பட்ட தினசரி வழக்கங்கள் மூலம் ஒழுக்கத்தை உருவாக்குங்கள்',
    'benefit3': 'உங்கள் மனதை கட்டுப்படுத்துங்கள்: தூண்டுதல்கள், அதீத சிந்தனை மற்றும் கவனச்சிதறல்கள்',
    'benefit4': 'உடல் மாற்ற திட்டங்களை (வீடு + ஜிம்) பின்பற்றுங்கள்',
    'benefit5': 'உங்கள் மனநிலை, முன்னேற்றம், பழக்கவழக்கங்கள் மற்றும் பயணத்தைக் கண்காணிக்கவும்',
    'benefit6': 'உங்களுக்கு ஏற்ற AI வழிகாட்டுதலுடன் நிலையானதாக இருங்கள்',
    'benefit7': 'அதே இலக்குகளைக் கொண்ட சமூகத்துடன் வளருங்கள்',
    'benefit8': 'மனரீதியாகவும் உடல் ரீதியாகவும் குணமடைய சிறப்பு நிபுணர் உதவியை வழங்குதல்',
    'benefit9': 'இது உங்கள் திறனை அடைய உதவுகிறது',
    'benefit10': 'தரவு பாதுகாப்பு',
    'benefit11': 'உங்களுடன் வளரும் ஒரு பங்குதாரர்',
    'whyYbeyExists': 'YBEY ஏன் உள்ளது',
    'whyExistsDesc1': 'மீண்டும் வர விரும்பும் இளைஞர்களுக்காக உருவாக்கப்பட்டது.',
    'whyExistsDesc2':
        "தாங்கள் இன்னும் அதிகமாக இருக்க முடியும் என்று அறிந்தவர்களுக்காக Ybey உருவாக்கப்பட்டது — ஆனால் சரியான அமைப்பு, ஆதரவு மற்றும் உதவி இல்லாதவர்கள். இந்த செயலி உங்கள் வாழ்க்கையை உள்ளிருந்து வெளியே மறுசீரமைக்க தினசரி அமைப்பை வழங்குகிறது (உங்கள் தரவு எங்களிடம் 100% பாதுகாப்பானது).",
    'earlyAccessRewards': 'முன்கூட்டிய அணுகல் வெகுமதிகள்',
    'earlyAccessDesc': 'வெளியீட்டிற்கு முன் இணைந்து பெறுங்கள்:',
    'reward1': 'முன்பதிவு செய்யப்பட்ட பயனர்பெயர்',
    'reward2': 'பீட்டா அம்சங்களுக்கு முன்னுரிமை அணுகல்',
    'reward3': 'நிறுவனர் உறுப்பினர் நிலை (முதல் 1000 பேருக்கு மட்டும்)',
    'reward4': 'YBEY இன் எதிர்காலத்தை வடிவமைப்பதில் முதல்வராக இருங்கள்',
    'communityEnergy': 'சமூக ஆற்றல்',
    'communityDesc1': 'இளைஞர் மாற்ற இயக்கத்தில் சேருங்கள்.',
    'communityDesc2':
        'கவனச்சிதறல், அடிமைத்தனம் மற்றும் சீரற்ற தன்மையை உடைத்து — ஒழுக்கம், வலிமை மற்றும் நோக்கத்தை உருவாக்கும் ஒரு தலைமுறை.',
    'aboutFounder': 'நிறுவனர் பற்றி',
    'founderMessage':
        "நான் எங்கு பார்த்தாலும் ஒரே மாதிரியான சுழற்சியைக் கண்ட பிறகு Ybey ஐ உருவாக்கினேன்:\nஞாயிற்றுக்கிழமைகளில் பெரிய இலக்குகள்.\nபுதன்கிழமைக்குள் சோர்வு.\nஜிம் உறுப்பினர் சந்தா பயன்படுத்தப்படாமல் உள்ளது.\nசுய உதவி புத்தகங்கள் முடிக்கப்படாமல் உள்ளன.\nஒரு வாரத்தில் முடிந்துவிடும் மற்றொரு “புதிய ஆரம்பம்”.\n\nபிரச்சனை சோம்பேறித்தனம் அல்ல.\nஉண்மையான இடைவெளி மாற்றம் செய்ய விரும்புவதற்கும் உண்மையில் மாற்றுவதற்கும் இடையில் உள்ளது.\n\nஉந்துதல் மறைந்துவிடும்.\nஅமைப்பு இல்லாமல் ஒழுக்கம் சரிந்துவிடும்.\nமற்றும் ஒரு தலைமுறை மீண்டும் மீண்டும் புதிதாகத் தொடங்க வேண்டியுள்ளது.\n\nஅதனால்தான் Ybey உள்ளது.\n\nஇன்னொரு ஊக்கப் பேச்சு அல்ல.\nஇன்னொரு “நிலையானமாக இருங்கள்” சொற்பொழிவு அல்ல.\nஆனால் ஒரு அமைப்பு — உளவியல், நடத்தை அறிவியல் மற்றும் தினசரி செயல்பாடுகளின் அடிப்படையில் கட்டப்பட்டது.\n\nஉந்துதல் சாகும் போது கருவிகள்.\nஉங்கள் மனம் சறுக்கும் போது அமைப்பு.\nஉங்கள் மனம், உடல் மற்றும் வாழ்க்கை முறையை ஒரு நாள் ஒரு முறையாக மீண்டும் உருவாக்கும் ஒரு கட்டமைப்பு.\n\nசாக்குப்போக்குகளை முடித்துவிட்டு உண்மையான மாற்றத்திற்கு தயாராக இருப்பவர்களுக்கு.",
    'founderNote':
        "குறிப்பு\n\n“YBEY ஒரே ஒரு நோக்கத்துடன் உருவாக்கப்பட்டது: இளைஞர்களுக்கு அவர்களின் மனம், உடல் மற்றும் வாழ்க்கை முறையை மீண்டும் உருவாக்க ஒரு உண்மையான அமைப்பை வழங்குதல் — உந்துதலால் அல்ல, கட்டமைப்பால்.”",
    'connectWithUs': 'எங்களுடன் இணையுங்கள்',
    'whatsappCommunity': 'வாட்ஸ்அப் சமூகம்',
    'instagram': 'இன்ஸ்டாகிராம்',
    'youtube': 'யூடியூப்',
    'registerAppBarTitle': 'முன்கூட்டிய அணுகலுக்குப் பதிவு செய்யவும்',
    'registrationMainText': 'இப்போதே YBEY இயக்கத்தில் இணையுங்கள்!',
    'userNameLabel': 'பயனர் பெயர்',
    'emailLabel': 'மின்னஞ்சல்',
    'passwordLabel': 'கடவுச்சொல்',
    'confirmPasswordLabel': 'கடவுச்சொல்லை உறுதிப்படுத்தவும்',
    'rememberMe': 'என்னை நினைவில் வைத்துக்கொள்',
    'registerButton': 'பதிவு செய்யவும்',
  };

  final Map<String, String> _teStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'మీరే అవుతారు',
    'mainDescription':
        "క్రమశిక్షణతో కూడిన జీవనం కోసం వ్యవస్థ — మనస్సు, శరీరం మరియు జీవనశైలికి.\n\nమీ కోసం నిర్మించబడింది — దృష్టి, క్రమశిక్షణ మరియు నిజమైన పరివర్తనను కనుగొనడానికి, పాత అలవాట్లకు తిరిగి వెళ్లకుండా ఉండటానికి.",
    'getEarlyAccess': 'ముందస్తు ప్రవేశం పొందండి',
    'whatYbeyWillDo': 'YBEY మీ కోసం ఏమి చేస్తుంది',
    'benefit1': 'నిజంగా పని చేసే వ్యవస్థతో మార్చుకోండి.',
    'benefit2': 'నిర్దిష్ట దినచర్యలతో క్రమశిక్షణను పెంచుకోండి',
    'benefit3': 'మీ మనస్సును నియంత్రించండి: కోరికలు, అతిగా ఆలోచించడం మరియు పరధ్యానాలు',
    'benefit4': 'శారీరక పరివర్తన ప్రణాళికలను (ఇల్లు + జిమ్) అనుసరించండి',
    'benefit5': 'మీ మానసిక స్థితి, పురోగతి, అలవాట్లు మరియు ప్రయాణాన్ని ట్రాక్ చేయండి',
    'benefit6': 'మీకు అనుగుణంగా AI మార్గదర్శకత్వంతో నిలకడగా ఉండండి',
    'benefit7': 'అదే లక్ష్యాలను కలిగి ఉన్న సంఘంతో వృద్ధి చెందండి',
    'benefit8': 'మానసికంగా మరియు శారీరకంగా నయం చేయడానికి నిపుణుల సహాయాన్ని అందించడం',
    'benefit9': 'ఇది మీ సామర్థ్యాన్ని సాధించడంలో మీకు సహాయపడుతుంది',
    'benefit10': 'డేటా భద్రత',
    'benefit11': 'మీతో పాటు పెరిగే భాగస్వామి',
    'whyYbeyExists': 'YBEY ఎందుకు ఉంది',
    'whyExistsDesc1': 'తిరిగి రావాలనుకునే యువకుల కోసం రూపొందించబడింది.',
    'whyExistsDesc2':
        "తాము ఇంకా చాలా చేయగలమని తెలిసిన వారి కోసం Ybey నిర్మించబడింది — కానీ సరైన నిర్మాణం, మద్దతు మరియు సహాయం లేనివారు. ఈ యాప్ మీ జీవితాన్ని లోపలి నుండి బయటికి పునర్నిర్మించడానికి ఒక రోజువారీ వ్యవస్థను అందిస్తుంది (మీ డేటా మా వద్ద 100% సురక్షితం).",
    'earlyAccessRewards': 'ముందస్తు ప్రవేశ బహుమతులు',
    'earlyAccessDesc': 'ప్రారంభానికి ముందు చేరండి మరియు పొందండి:',
    'reward1': 'రిజర్వ్ చేయబడిన వినియోగదారు పేరు',
    'reward2': 'బీటా ఫీచర్లకు ప్రాధాన్యత ప్రవేశం',
    'reward3': 'వ్యవస్థాపక సభ్యుని హోదా (మొదటి 1000 మందికి మాత్రమే)',
    'reward4': 'YBEY భవిష్యత్తును రూపొందించే మొదటి వ్యక్తి అవ్వండి',
    'communityEnergy': 'కమ్యూనిటీ శక్తి',
    'communityDesc1': 'యువజన పరివర్తన ఉద్యమంలో చేరండి.',
    'communityDesc2':
        'పరధ్యానం, వ్యసనం మరియు అస్థిరతను విచ్ఛిన్నం చేసి — క్రమశిక్షణ, బలం మరియు ఉద్దేశ్యాన్ని నిర్మించే తరం.',
    'aboutFounder': 'వ్యవస్థాపకుడి గురించి',
    'founderMessage':
        "ప్రతిచోటా ఒకే చక్రం చూసిన తర్వాత నేను Ybey ను నిర్మించాను:\nఆదివారం పెద్ద లక్ష్యాలు.\nబుధవారానికల్లా అలసట.\nజిమ్ సభ్యత్వాలు ఉపయోగించబడవు.\nస్వయం సహాయక పుస్తకాలు అసంపూర్ణంగా ఉన్నాయి.\nఒక వారంలో చనిపోయే మరో “కొత్త ప్రారంభం”.\n\nసమస్య సోమరితనం కాదు.\nనిజమైన అంతరం మార్చాలనుకోవడానికి మరియు వాస్తవంగా మార్చడానికి మధ్య ఉంది.\n\nప్రేరణ అదృశ్యమవుతుంది.\nనిర్మాణం లేకుండా క్రమశిక్షణ కుప్పకూలుతుంది.\nమరియు ఒక తరం మళ్లీ మళ్లీ పునఃప్రారంభించవలసి వస్తుంది.\n\nఅందుకే Ybey ఉంది.\n\nమరో ప్రోత్సాహక ఉపన్యాసం కాదు.\nమరో “స్థిరంగా ఉండండి” ఉపన్యాసం కాదు.\nకానీ ఒక వ్యవస్థ — మనస్తత్వశాస్త్రం, ప్రవర్తనా శాస్త్రం మరియు రోజువారీ అమలు ఆధారంగా నిర్మించబడింది.\n\nప్రేరణ చనిపోయినప్పుడు సాధనాలు.\nమీ మనస్సు జారిపోయినప్పుడు నిర్మాణం.\nమీ మనస్సు, శరీరం మరియు జీవనశైలిని ఒక రోజు ఒక రోజు పునర్నిర్మించే ఒక ఫ్రేమ్‌వర్క్.\n\nసాకులు చెప్పడం మానేసి నిజమైన పరివర్తనకు సిద్ధంగా ఉన్న ఎవరికైనా.",
    'founderNote':
        "గమనిక\n\n“YBEY ఒకే ఒక లక్ష్యంతో సృష్టించబడింది: యువతకు వారి మనస్సు, శరీరం మరియు జీవనశైలిని పునర్నిర్మించడానికి నిజమైన వ్యవస్థను అందించడం — ప్రేరణతో కాదు, నిర్మాణంతో.”",
    'connectWithUs': 'మాతో కనెక్ట్ అవ్వండి',
    'whatsappCommunity': 'వాట్సాప్ కమ్యూనిటీ',
    'instagram': 'ఇన్‌స్టాగ్రామ్',
    'youtube': 'యూట్యూబ్',
    'registerAppBarTitle': 'ముందస్తు ప్రవేశం కోసం నమోదు చేసుకోండి',
    'registrationMainText': 'ఇప్పుడే YBEY ఉద్యమంలో చేరండి!',
    'userNameLabel': 'వినియోగదారు పేరు',
    'emailLabel': 'ఇమెయిల్',
    'passwordLabel': 'పాస్‌వర్డ్',
    'confirmPasswordLabel': 'పాస్‌వర్డ్‌ను నిర్ధారించండి',
    'rememberMe': 'నన్ను గుర్తుంచుకోండి',
    'registerButton': 'నమోదు చేయండి',
  };

  final Map<String, String> _knStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'ನೀವೇ ಆಗಿ',
    'mainDescription':
        "ಶಿಸ್ತುಬದ್ಧ ಜೀವನಕ್ಕಾಗಿ ಒಂದು ವ್ಯವಸ್ಥೆ — ಮನಸ್ಸು, ದೇಹ ಮತ್ತು ಜೀವನಶೈಲಿಗೆ.\n\nನಿಮಗಾಗಿ ನಿರ್ಮಿಸಲಾಗಿದೆ — ಗಮನ, ಶಿಸ್ತು ಮತ್ತು ನಿಜವಾದ ಪರಿವರ್ತನೆಯನ್ನು ಕಂಡುಹಿಡಿಯಲು, ಹಳೆಯ ಅಭ್ಯಾಸಗಳಿಗೆ ಮತ್ತೆ ಜಾರಿಕೊಳ್ಳದೆ.",
    'getEarlyAccess': 'ಮುಂಚಿತ ಪ್ರವೇಶ ಪಡೆಯಿರಿ',
    'whatYbeyWillDo': 'YBEY ನಿಮಗೆ ಏನು ಮಾಡುತ್ತದೆ',
    'benefit1': 'ವಾಸ್ತವವಾಗಿ ಕಾರ್ಯನಿರ್ವಹಿಸುವ ವ್ಯವಸ್ಥೆಯೊಂದಿಗೆ ರೂಪಾಂತರಗೊಳ್ಳಿ.',
    'benefit2': 'ರಚನಾತ್ಮಕ ದೈನಂದಿನ ದಿನಚರಿಗಳೊಂದಿಗೆ ಶಿಸ್ತನ್ನು ಬೆಳೆಸಿಕೊಳ್ಳಿ',
    'benefit3': 'ನಿಮ್ಮ ಮನಸ್ಸನ್ನು ನಿಯಂತ್ರಿಸಿ: ಪ್ರಚೋದನೆಗಳು, ಅತಿಯಾದ ಆಲೋಚನೆ ಮತ್ತು ಗೊಂದಲಗಳು',
    'benefit4': 'ದೈಹಿಕ ರೂಪಾಂತರ ಯೋಜನೆಗಳನ್ನು (ಮನೆ + ಜಿಮ್) ಅನುಸರಿಸಿ',
    'benefit5': 'ನಿಮ್ಮ ಮನಸ್ಥಿತಿ, ಪ್ರಗತಿ, ಅಭ್ಯಾಸಗಳು ಮತ್ತು ಪ್ರಯಾಣವನ್ನು ಟ್ರ್ಯಾಕ್ ಮಾಡಿ',
    'benefit6': 'ನಿಮಗಾಗಿ ರೂಪಿಸಿದ AI ಮಾರ್ಗದರ್ಶನದೊಂದಿಗೆ ಸ್ಥಿರವಾಗಿರಿ',
    'benefit7': 'ಅದೇ ಗುರಿಗಳನ್ನು ಹೊಂದಿರುವ ಸಮುದಾಯದೊಂದಿಗೆ ಬೆಳೆಯಿರಿ',
    'benefit8': 'ಮಾನಸಿಕವಾಗಿ ಮತ್ತು ದೈಹಿಕವಾಗಿ ಗುಣಪಡಿಸಲು ತಜ್ಞರ ಸಹಾಯವನ್ನು ಒದಗಿಸುವುದು',
    'benefit9': 'ಇದು ನಿಮ್ಮ ಸಾಮರ್ಥ್ಯವನ್ನು ಸಾಧಿಸಲು ಸಹಾಯ ಮಾಡುತ್ತದೆ',
    'benefit10': 'ಡೇಟಾ ಭದ್ರತೆ',
    'benefit11': 'ನಿಮ್ಮೊಂದಿಗೆ ಬೆಳೆಯುವ ಪಾಲುದಾರ',
    'whyYbeyExists': 'YBEY ಏಕೆ ಅಸ್ತಿತ್ವದಲ್ಲಿದೆ',
    'whyExistsDesc1': 'ಮರಳಿ ಬರಲು ಬಯಸುವ ಯುವಕರಿಗಾಗಿ ಮಾಡಲ್ಪಟ್ಟಿದೆ.',
    'whyExistsDesc2':
        "Ybey ಅನ್ನು ಹೆಚ್ಚು ಆಗಬಹುದು ಎಂದು ತಿಳಿದಿರುವವರಿಗಾಗಿ ನಿರ್ಮಿಸಲಾಗಿದೆ — ಆದರೆ ಸರಿಯಾದ ರಚನೆ, ಬೆಂಬಲ ಮತ್ತು ಸಹಾಯದ ಕೊರತೆಯಿರುವವರು. ಈ ಅಪ್ಲಿಕೇಶನ್ ನಿಮ್ಮ ಜೀವನವನ್ನು ಒಳಗಿನಿಂದ ಹೊರಕ್ಕೆ ಪುನರ್ನಿರ್ಮಿಸಲು ದೈನಂದಿನ ವ್ಯವಸ್ಥೆಯನ್ನು ನೀಡುತ್ತದೆ (ನಿಮ್ಮ ಡೇಟಾ ನಮ್ಮೊಂದಿಗೆ 100% ಸುರಕ್ಷಿತವಾಗಿದೆ).",
    'earlyAccessRewards': 'ಮುಂಚಿತ ಪ್ರವೇಶ ಬಹುಮಾನಗಳು',
    'earlyAccessDesc': 'ಬಿಡುಗಡೆಗೆ ಮೊದಲು ಸೇರಿಕೊಂಡು ಪಡೆಯಿರಿ:',
    'reward1': 'ಮೀಸಲಾದ ಬಳಕೆದಾರಹೆಸರು',
    'reward2': 'ಬೀಟಾ ವೈಶಿಷ್ಟ್ಯಗಳಿಗೆ ಆದ್ಯತೆಯ ಪ್ರವೇಶ',
    'reward3': 'ಸ್ಥಾಪಕ ಸದಸ್ಯ ಸ್ಥಾನಮಾನ (ಮೊದಲ 1000 ಜನರಿಗೆ ಮಾತ್ರ)',
    'reward4': 'YBEY ನ ಭವಿಷ್ಯವನ್ನು ರೂಪಿಸುವ ಮೊದಲ ವ್ಯಕ್ತಿ ನೀವಾಗಿರಿ',
    'communityEnergy': 'ಸಮುದಾಯ ಶಕ್ತಿ',
    'communityDesc1': 'ಯುವ ಪರಿವರ್ತನೆ ಚಳುವಳಿಗೆ ಸೇರಿಕೊಳ್ಳಿ.',
    'communityDesc2':
        'ಗೊಂದಲ, ವ್ಯಸನ ಮತ್ತು ಅಸ್ಥಿರತೆಯನ್ನು ಮುರಿಯುವ — ಮತ್ತು ಶಿಸ್ತು, ಶಕ್ತಿ ಮತ್ತು ಉದ್ದೇಶವನ್ನು ನಿರ್ಮಿಸುವ ಪೀಳಿಗೆ.',
    'aboutFounder': 'ಸ್ಥಾಪಕರು ಬಗ್ಗೆ',
    'founderMessage':
        "ನಾನು ಎಲ್ಲೆಡೆ ಒಂದೇ ಚಕ್ರವನ್ನು ನೋಡಿದ ನಂತರ Ybey ಅನ್ನು ನಿರ್ಮಿಸಿದೆ:\nಭಾನುವಾರ ದೊಡ್ಡ ಗುರಿಗಳು.\nಬುಧವಾರದ ವೇಳೆಗೆ ಸುಸ್ತಾಗುತ್ತದೆ.\nಜಿಮ್ ಸದಸ್ಯತ್ವಗಳು ಬಳಕೆಯಾಗುವುದಿಲ್ಲ.\nಸ್ವಸಹಾಯ ಪುಸ್ತಕಗಳು ಅಪೂರ್ಣವಾಗಿವೆ.\nಒಂದು ವಾರದಲ್ಲಿ ಸಾಯುವ ಮತ್ತೊಂದು “ತಾಜಾ ಆರಂಭ”.\n\nಸಮಸ್ಯೆ ಸೋಮಾರಿತನವಲ್ಲ.\nನಿಜವಾದ ಅಂತರವು ಬದಲಾಯಿಸಲು ಬಯಸುವುದು ಮತ್ತು ವಾಸ್ತವವಾಗಿ ಬದಲಾಯಿಸುವುದರ ನಡುವೆ ಇದೆ.\n\nಪ್ರೇರಣೆ ಕಣ್ಮರೆಯಾಗುತ್ತದೆ.\nರಚನೆಯಿಲ್ಲದೆ ಶಿಸ್ತು ಕುಸಿಯುತ್ತದೆ.\nಮತ್ತು ಇಡೀ ಪೀಳಿಗೆ ಮತ್ತೆ ಮತ್ತೆ ಮರುಪ್ರಾರಂಭಿಸಲು ಸಿಕ್ಕಿಹಾಕಿಕೊಂಡಿದೆ.\n\nಅದಕ್ಕಾಗಿಯೇ Ybey ಅಸ್ತಿತ್ವದಲ್ಲಿದೆ.\n\nಮತ್ತೊಂದು ಪ್ರೇರಣಾ ಭಾಷಣವಲ್ಲ.\nಮತ್ತೊಂದು “ಕೇವಲ ಸ್ಥಿರವಾಗಿರಿ” ಉಪನ್ಯಾಸವಲ್ಲ.\nಆದರೆ ಒಂದು ವ್ಯವಸ್ಥೆ — ಮನೋವಿಜ್ಞಾನ, ನಡವಳಿಕೆ ವಿಜ್ಞಾನ ಮತ್ತು ದೈನಂದಿನ ಕಾರ್ಯಗತಗೊಳಿಸುವಿಕೆಯ ಮೇಲೆ ನಿರ್ಮಿಸಲಾಗಿದೆ.\n\nಪ್ರೇರಣೆ ಸತ್ತಾಗ ಉಪಕರಣಗಳು.\nನಿಮ್ಮ ಮನಸ್ಸು ಜಾರಿದಾಗ ರಚನೆ.\nನಿಮ್ಮ ಮನಸ್ಸು, ದೇಹ ಮತ್ತು ಜೀವನಶೈಲಿಯನ್ನು ಒಂದು ದಿನದಲ್ಲಿ ಮರುನಿರ್ಮಿಸುವ ಒಂದು ಚೌಕಟ್ಟು.\n\nನೆಪಗಳನ್ನು ಮುಗಿಸಿ ಮತ್ತು ನಿಜವಾದ ರೂಪಾಂತರಕ್ಕೆ ಸಿದ್ಧವಾಗಿರುವ ಯಾರಿಗಾದರೂ.",
    'founderNote':
        "ಗಮನಿಸಿ\n\n“YBEY ಒಂದೇ ಒಂದು ಉದ್ದೇಶದಿಂದ ರಚಿಸಲಾಗಿದೆ: ಯುವಕರಿಗೆ ಅವರ ಮನಸ್ಸು, ದೇಹ ಮತ್ತು ಜೀವನಶೈಲಿಯನ್ನು ಪುನರ್ನಿರ್ಮಿಸಲು ನಿಜವಾದ ವ್ಯವಸ್ಥೆಯನ್ನು ನೀಡಲು — ಪ್ರೇರಣೆಯಿಂದಲ್ಲ, ರಚನೆಯಿಂದ.”",
    'connectWithUs': 'ನಮ್ಮೊಂದಿಗೆ ಸಂಪರ್ಕಿಸಿ',
    'whatsappCommunity': 'ವಾಟ್ಸಾಪ್ ಸಮುದಾಯ',
    'instagram': 'ಇನ್‌ಸ್ಟಾಗ್ರಾಮ್',
    'youtube': 'ಯೂಟ್ಯೂಬ್',
    'registerAppBarTitle': 'ಮುಂಚಿತ ಪ್ರವೇಶಕ್ಕಾಗಿ ನೋಂದಾಯಿಸಿ',
    'registrationMainText': 'ಈಗಲೇ YBEY ಆಂದೋಲನಕ್ಕೆ ಸೇರಿಕೊಳ್ಳಿ!',
    'userNameLabel': 'ಬಳಕೆದಾರ ಹೆಸರು',
    'emailLabel': 'ಇಮೇಲ್',
    'passwordLabel': 'ಪಾಸ್‌ವರ್ಡ್',
    'confirmPasswordLabel': 'ಪಾಸ್‌ವರ್ಡ್ ದೃಢೀಕರಿಸಿ',
    'rememberMe': 'ನನ್ನನ್ನು ನೆನಪಿಡಿ',
    'registerButton': 'ನೋಂದಾಯಿಸಿ',
  };

  final Map<String, String> _mlStrings = {
    'appTitle': 'YBEY',
    'appSubtitle': 'നിങ്ങൾ നിങ്ങളാകുന്നു',
    'mainDescription':
        "അച്ചടക്കമുള്ള ജീവിതത്തിനുള്ള സംവിധാനം — മനസ്സ്, ശരീരം, ജീവിതശൈലി എന്നിവയ്ക്ക്.\n\nനിങ്ങൾക്കായി നിർമ്മിച്ചത് — ശ്രദ്ധ, അച്ചടക്കം, യഥാർത്ഥ പരിവർത്തനം എന്നിവ കണ്ടെത്താൻ, പഴയ ശീലങ്ങളിലേക്ക് തിരിച്ചുപോകാതെ.",
    'getEarlyAccess': 'തുടക്കത്തിൽ പ്രവേശനം നേടുക',
    'whatYbeyWillDo': 'YBEY നിങ്ങൾക്ക് എന്ത് ചെയ്യും',
    'benefit1': 'യഥാർത്ഥത്തിൽ പ്രവർത്തിക്കുന്ന ഒരു സിസ്റ്റം ഉപയോഗിച്ച് രൂപാന്തരപ്പെടുത്തുക.',
    'benefit2': 'ഘടനയുള്ള ദിനചര്യകളിലൂടെ അച്ചടക്കം വളർത്തുക',
    'benefit3': 'നിങ്ങളുടെ മനസ്സിനെ നിയന്ത്രിക്കുക: ആഗ്രഹങ്ങൾ, അമിത ചിന്ത, ശ്രദ്ധ വ്യതിചലിക്കൽ',
    'benefit4': 'ശാരീരിക പരിവർത്തന പദ്ധതികൾ (വീട് + ജിം) പിന്തുടരുക',
    'benefit5': 'നിങ്ങളുടെ മാനസികാവസ്ഥ, പുരോഗതി, ശീലങ്ങൾ, യാത്ര എന്നിവ നിരീക്ഷിക്കുക',
    'benefit6': 'നിങ്ങൾക്കായി തയ്യാറാക്കിയ AI മാർഗ്ഗനിർദ്ദേശങ്ങളോടെ സ്ഥിരത പുലർത്തുക',
    'benefit7': 'ഒരേ ലക്ഷ്യങ്ങളുള്ള ഒരു കമ്മ്യൂണിറ്റിയുമായി വളരുക',
    'benefit8': 'മാനസികമായും ശാരീരികമായും സുഖം പ്രാപിക്കാൻ വിദഗ്ദ്ധ സഹായം നൽകുക',
    'benefit9': 'ഇത് നിങ്ങളുടെ കഴിവ് നേടാൻ സഹായിക്കുന്നു',
    'benefit10': 'ഡാറ്റാ സുരക്ഷ',
    'benefit11': 'നിങ്ങളോടൊപ്പം വളരുന്ന ഒരു പങ്കാളി',
    'whyYbeyExists': 'YBEY എന്തുകൊണ്ട് നിലനിൽക്കുന്നു',
    'whyExistsDesc1': 'തിരിച്ചുവരാൻ ആഗ്രഹിക്കുന്ന യുവജനങ്ങൾക്കായി നിർമ്മിച്ചത്.',
    'whyExistsDesc2':
        "തങ്ങൾക്ക് കൂടുതൽ ആകാൻ കഴിയുമെന്ന് അറിയുന്നവർക്ക് വേണ്ടിയാണ് Ybey നിർമ്മിച്ചത് — എന്നാൽ ശരിയായ ഘടന, പിന്തുണ, സഹായം എന്നിവയില്ലാത്തവർക്ക്. ഈ ആപ്ലിക്കേഷൻ നിങ്ങളുടെ ജീവിതത്തെ ഉള്ളിൽ നിന്ന് പുറത്തേക്ക് പുനർനിർമ്മിക്കാൻ ഒരു ദൈനംദിന സംവിധാനം നൽകുന്നു (നിങ്ങളുടെ ഡാറ്റ ഞങ്ങളോടൊപ്പം 100% സുരക്ഷിതമാണ്).",
    'earlyAccessRewards': 'തുടക്കത്തിലുള്ള പ്രവേശനത്തിനുള്ള പ്രതിഫലങ്ങൾ',
    'earlyAccessDesc': 'തുടക്കത്തിൽ ചേരുക, നേടുക:',
    'reward1': 'സംവരണം ചെയ്ത ഉപയോക്തൃനാമം',
    'reward2': 'ബീറ്റാ സവിശേഷതകളിലേക്ക് മുൻഗണനാ പ്രവേശനം',
    'reward3': 'സ്ഥാപക അംഗത്വ പദവി (ആദ്യത്തെ 1000 പേർക്ക് മാത്രം)',
    'reward4': 'YBEY യുടെ ഭാവി രൂപപ്പെടുത്തുന്ന ആദ്യത്തെയാളാകുക',
    'communityEnergy': 'കമ്മ്യൂണിറ്റി ഊർജ്ജം',
    'communityDesc1': 'യുവജന പരിവർത്തന പ്രസ്ഥാനത്തിൽ ചേരുക.',
    'communityDesc2':
        'ശ്രദ്ധ വ്യതിചലിക്കൽ, ആസക്തി, സ്ഥിരതയില്ലായ്മ എന്നിവയെ തകർത്ത് — അച്ചടക്കം, ശക്തി, ലക്ഷ്യം എന്നിവ വളർത്തുന്ന ഒരു തലമുറ.',
    'aboutFounder': 'സ്ഥാപകനെക്കുറിച്ച്',
    'founderMessage':
        "എല്ലായിടത്തും ഒരേ ചക്രം കണ്ടതിനുശേഷം ഞാൻ Ybey നിർമ്മിച്ചു:\nഞായറാഴ്ച വലിയ ലക്ഷ്യങ്ങൾ.\nബുധനാഴ്ചയോടെ തളർച്ച.\nജിം അംഗത്വങ്ങൾ ഉപയോഗിക്കാതെ കിടക്കുന്നു.\nസ്വാശ്രയ പുസ്തകങ്ങൾ പൂർത്തിയാക്കാതെ കിടക്കുന്നു.\nഒരു ആഴ്ചയിൽ ഇല്ലാതാകുന്ന മറ്റൊരു “പുതിയ തുടക്കം”.\n\nപ്രശ്നം മടിയില്ല.\nയഥാർത്ഥ വിടവ് മാറ്റാൻ ആഗ്രഹിക്കുന്നതിനും യഥാർത്ഥത്തിൽ മാറ്റുന്നതിനും ഇടയിലാണ്.\n\nപ്രചോദനം അപ്രത്യക്ഷമാകുന്നു.\nഘടനയില്ലാതെ അച്ചടക്കം തകരുന്നു.\nഒരു തലമുറ മുഴുവൻ വീണ്ടും വീണ്ടും പുനരാരംഭിക്കാൻ നിർബന്ധിതരാകുന്നു.\n\nഅതുകൊണ്ടാണ് Ybey നിലനിൽക്കുന്നത്.\n\nമറ്റൊരു പ്രചോദന പ്രസംഗമല്ല.\nമറ്റൊരു “സ്ഥിരത പുലർത്തുക” പ്രഭാഷണമല്ല.\nഎന്നാൽ ഒരു സിസ്റ്റം — മനഃശാസ്ത്രം, പെരുമാറ്റ ശാസ്ത്രം, ദൈനംദിന നിർവ്വഹണം എന്നിവയെ അടിസ്ഥാനമാക്കി നിർമ്മിച്ചത്.\n\nപ്രചോദനം ഇല്ലാതാകുമ്പോൾ ടൂളുകൾ.\nനിങ്ങളുടെ മനസ്സ് വഴുതിവീഴുമ്പോൾ ഘടന.\nനിങ്ങളുടെ മനസ്സ്, ശരീരം, ജീവിതശൈലി എന്നിവയെ ഒരു ദിവസം കൊണ്ട് പുനർനിർമ്മിക്കുന്ന ഒരു ചട്ടക്കൂട്.\n\nഒഴികഴിവുകൾ അവസാനിപ്പിച്ച് യഥാർത്ഥ പരിവർത്തനത്തിന് തയ്യാറായ ആർക്കും.",
    'founderNote':
        "ശ്രദ്ധിക്കുക\n\n“YBEY ഒരൊറ്റ ദൗത്യത്തോടെയാണ് സൃഷ്ടിക്കപ്പെട്ടത്: യുവജനങ്ങൾക്ക് അവരുടെ മനസ്സ്, ശരീരം, ജീവിതശൈലി എന്നിവയെ പുനർനിർമ്മിക്കാൻ ഒരു യഥാർത്ഥ സംവിധാനം നൽകുക — പ്രചോദനത്തിലൂടെയല്ല, ഘടനയിലൂടെ.”",
    'connectWithUs': 'ഞങ്ങളുമായി ബന്ധപ്പെടുക',
    'whatsappCommunity': 'വാട്ട്‌സ്ആപ്പ് കമ്മ്യൂണിറ്റി',
    'instagram': 'ഇൻസ്റ്റാഗ്രാം',
    'youtube': 'യൂട്യൂബ്',
    'registerAppBarTitle': 'തുടക്കത്തിലുള്ള പ്രവേശനത്തിനായി രജിസ്റ്റർ ചെയ്യുക',
    'registrationMainText': 'ഇപ്പോൾ YBEY പ്രസ്ഥാനത്തിൽ ചേരുക!',
    'userNameLabel': 'ഉപയോക്തൃനാമം',
    'emailLabel': 'ഇമെയിൽ',
    'passwordLabel': 'പാസ്‌വേഡ്',
    'confirmPasswordLabel': 'പാസ്‌വേഡ് സ്ഥിരീകരിക്കുക',
    'rememberMe': 'എന്നെ ഓർക്കുക',
    'registerButton': 'രജിസ്റ്റർ ചെയ്യുക',
  };

  // Combine all translations into a single map
  late final Map<String, Map<String, String>> _allTranslations;

  @override
  void initState() {
    super.initState();

    _allTranslations = {
      'EN': _enStrings,
      'HI': _hiStrings,
      'TA': _taStrings,
      'TE': _teStrings,
      'KN': _knStrings,
      'ML': _mlStrings,
    };

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.16),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _animationController.forward();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bgColor1 = ColorTween(
      begin: const Color(0xFF11526D),
      end: const Color(0xFF3B9E59),
    ).animate(_bgController);

    _bgColor2 = ColorTween(
      begin: const Color(0xFF3B9E59),
      end: const Color(0xFF11526D),
    ).animate(_bgController);
    
    // Track visitor (statistics only visible in backend)
    _trackVisitor();
  }
  
  Future<void> _trackVisitor() async {
    try {
      final String baseUrl = ApiConfig.baseUrl;

      await http.post(
        Uri.parse('$baseUrl/api/track-visitor'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );
      debugPrint('Visitor tracked successfully');
    } catch (e) {
      debugPrint('Error tracking visitor: $e');
      // Silently fail - don't interrupt user experience
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlString')),
        );
      }
      debugPrint('Could not launch $urlString');
    }
  }

  Map<String, String> get _currentTranslations =>
      _allTranslations[_selectedLanguage]!;

  @override
  Widget build(BuildContext context) {
    final List<String> ybeyBenefits = <String>[
      _currentTranslations['benefit1']!,
      _currentTranslations['benefit2']!,
      _currentTranslations['benefit3']!,
      _currentTranslations['benefit4']!,
      _currentTranslations['benefit5']!,
      _currentTranslations['benefit6']!,
      _currentTranslations['benefit7']!,
      _currentTranslations['benefit8']!,
      _currentTranslations['benefit9']!,
      _currentTranslations['benefit10']!,
      _currentTranslations['benefit11']!,
    ];

    final List<String> earlyAccessRewards = <String>[
      _currentTranslations['reward1']!,
      _currentTranslations['reward2']!,
      _currentTranslations['reward3']!,
      _currentTranslations['reward4']!,
    ];

    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (BuildContext context, Widget? child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: <Color>[
                  _bgColor1.value ?? const Color(0xFF11526D),
                  _bgColor2.value ?? const Color(0xFF3B9E59),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Main content
            Center(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 40.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Align(
                            alignment: Alignment.topRight,
                            child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            dropdownColor: const Color(0xFF11526D),
                            icon: const Icon(
                              Icons.language,
                              color: Colors.white,
                              size: 18,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            style: const TextStyle(color: Colors.white),
                            items: const <DropdownMenuItem<String>>[
                              DropdownMenuItem<String>(
                                value: 'EN',
                                child: Text('English'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'HI',
                                child: Text('हिन्दी'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'TA',
                                child: Text('தமிழ்'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'TE',
                                child: Text('తెలుగు'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'KN',
                                child: Text('ಕನ್ನಡ'),
                              ),
                              DropdownMenuItem<String>(
                                value: 'ML',
                                child: Text('മലയാളം'),
                              ),
                            ],
                            onChanged: (String? value) {
                              if (value == null) return;
                              setState(() {
                                _selectedLanguage = value;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          await Future<void>.delayed(const Duration(seconds: 1));
                          if (!mounted) return;
                          Navigator.push<void>(
                            context,
                            PageRouteBuilder<void>(
                              transitionDuration: const Duration(milliseconds: 500),
                              pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                                return MultiProvider(
                                  providers: [
                                    Provider<Map<String, String>>.value(value: _currentTranslations),
                                    ChangeNotifierProvider<RegistrationData>(
                                      create: (BuildContext context) =>
                                          RegistrationData(languageCode: _selectedLanguage),
                                    ),
                                  ],
                                  builder: (BuildContext context, Widget? _) => const RegistrationPage(),
                                );
                              },
                              transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
                                final Animation<double> curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
                                return ScaleTransition(
                                  scale: Tween<double>(begin: 0.9, end: 1.0).animate(curved),
                                  child: FadeTransition(opacity: curved, child: child),
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          width: 144,
                          height: 144,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2F8F6B),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 3,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: const Color.fromARGB(255, 9, 125, 174).withOpacity(0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object error, StackTrace? s) {
                                return Container(
                                  height: 120,
                                  width: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[300],
                                  ),
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        _currentTranslations['appTitle']!,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        _currentTranslations['appSubtitle']!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      _currentTranslations['mainDescription']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) {
                                return MultiProvider(
                                  providers: [
                                    Provider<Map<String, String>>.value(
                                        value: _currentTranslations),
                                    ChangeNotifierProvider<RegistrationData>(
                                      create: (BuildContext context) =>
                                          RegistrationData(
                                              languageCode: _selectedLanguage),
                                    ),
                                  ],
                                  builder: (BuildContext context, Widget? _) =>
                                      const RegistrationPage(),
                                );
                              },
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                Color(0xFFFFFFFF),
                                Color(0xFFE8E8E8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30.0),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 8),
                                blurRadius: 12,
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                offset: const Offset(0, -2),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Text(
                            _currentTranslations['getEarlyAccess']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF11526D),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['whatYbeyWillDo']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: ybeyBenefits.map<Widget>((String benefit) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: <Color>[
                                  Colors.white.withOpacity(0.15),
                                  Colors.white.withOpacity(0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 4),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.1),
                                  offset: const Offset(0, -2),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['whyYbeyExists']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentTranslations['whyExistsDesc1']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentTranslations['whyExistsDesc2']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['earlyAccessRewards']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentTranslations['earlyAccessDesc']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          earlyAccessRewards.map<Widget>((String reward) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Icon(
                                Icons.star_outline,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  reward,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['communityEnergy']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentTranslations['communityDesc1']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _currentTranslations['communityDesc2']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['aboutFounder']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Color(0xFF3B9E59),
                              Color(0xFF11526D),
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 24,
                              offset: const Offset(0, 16),
                            ),
                            BoxShadow(
                              color: Colors.white.withOpacity(0.12),
                              blurRadius: 8,
                              offset: const Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withOpacity(0.08),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/founder.png',
                                fit: BoxFit.cover,
                                errorBuilder: (BuildContext context, Object error, StackTrace? s) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'YASH MEENA',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentTranslations['founderMessage']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _currentTranslations['founderNote']!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Text(
                      _currentTranslations['connectWithUs']!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _SocialMediaLink(
                      logoUrl:
                          'https://cdn-icons-png.flaticon.com/512/3670/3670051.png',
                      label: _currentTranslations['whatsappCommunity']!,
                      url: 'https://chat.whatsapp.com/D5HTss1QyxP4XbQCOxnXGt',
                      onTap: _launchURL,
                    ),
                    const SizedBox(height: 15),
                    _SocialMediaLink(
                      logoUrl:
                          'https://cdn-icons-png.flaticon.com/512/2111/2111463.png',
                      label: _currentTranslations['instagram']!,
                      url:
                          'https://www.instagram.com/yashtamdya?igsh=OHdiaHBpYWdpYzN3',
                      onTap: _launchURL,
                    ),
                    const SizedBox(height: 15),
                    _SocialMediaLink(
                      logoUrl:
                          'https://cdn-icons-png.flaticon.com/512/3670/3670147.png',
                      label: _currentTranslations['youtube']!,
                      url:
                          'https://youtube.com/@yash_tamdya?si=8ooncPL6F5H4k4ct',
                      onTap: _launchURL,
                    ),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _SocialMediaLink extends StatelessWidget {
  const _SocialMediaLink({
    required this.logoUrl,
    required this.label,
    required this.url,
    required this.onTap,
  });

  final String logoUrl;
  final String label;
  final String url;
  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onTap(url),
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Image.network(
              logoUrl,
              width: 24,
              height: 24,
              errorBuilder:
                  (BuildContext context, Object error, StackTrace? stackTrace) {
                return const Icon(Icons.link, color: Colors.white, size: 24);
              },
            ),
            const SizedBox(width: 15),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.open_in_new, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }
}
