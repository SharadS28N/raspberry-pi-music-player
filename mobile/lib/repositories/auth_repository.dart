import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

abstract class AuthRepository {
  UserProfile? get currentUser;
  Stream<UserProfile?> get authStateChanges;

  Future<UserProfile> signInWithEmail(String email, String password);
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    List<String> preferredGenres = const [],
  });
  Future<UserProfile> signInAsEvaluator({String name = 'Professor / Evaluator'});
  Future<void> signOut();
  Future<void> updateProfile(UserProfile profile);
}

class AppAuthRepository implements AuthRepository {
  static final AppAuthRepository instance = AppAuthRepository._internal();
  AppAuthRepository._internal() {
    _init();
  }

  static const String _prefUserKey = 'auth_cached_user_profile';
  static const String _prefRegisteredDbKey = 'auth_registered_accounts_db';

  final _authStateController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  bool _isInitialized = false;

  @override
  UserProfile? get currentUser => _currentUser;

  bool get isInitialized => _isInitialized;

  Future<void> initialize() => _init();

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefUserKey);
      if (cached != null && cached.isNotEmpty) {
        _currentUser = UserProfile.fromJson(jsonDecode(cached));
      } else {
        // Unauthenticated state: show login screen
        _currentUser = null;
      }
      _isInitialized = true;
      _authStateController.add(_currentUser);
    } catch (e) {
      _currentUser = null;
      _isInitialized = true;
      _authStateController.add(null);
    }
  }

  Future<Map<String, dynamic>> _getAccountsDb() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefRegisteredDbKey);
      if (raw != null && raw.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(raw));
      }
    } catch (_) {}
    return {
      'evaluator@openaamps.ai': {
        'password': 'password123',
        'profile': UserProfile(
          uid: 'evaluator_demo',
          email: 'evaluator@openaamps.ai',
          displayName: 'Music Evaluator',
          photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
          preferredGenres: const ['Rock', 'Synthwave', 'Indie', 'Lo-Fi'],
          topArtists: const ['Coldplay', 'Queen', 'The Weeknd'],
          totalListeningTimeSeconds: 4320,
          totalTracksPlayed: 18,
          tasteVector: const AcousticTasteVector(
            energy: 0.65,
            valence: 0.60,
            danceability: 0.62,
            acousticness: 0.35,
            tempo: 118.0,
          ),
          isGuest: false,
        ).toJson(),
      },
    };
  }

  Future<void> _saveAccountsDb(Map<String, dynamic> db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefRegisteredDbKey, jsonEncode(db));
    } catch (_) {}
  }

  Future<void> _saveCurrentUser(UserProfile? profile) async {
    _currentUser = profile;
    _authStateController.add(profile);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (profile != null) {
        await prefs.setString(_prefUserKey, jsonEncode(profile.toJson()));
      } else {
        await prefs.remove(_prefUserKey);
      }
    } catch (_) {}
  }

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    final db = await _getAccountsDb();
    if (!db.containsKey(cleanEmail)) {
      throw Exception('No account found for $cleanEmail. Please sign up first.');
    }

    final record = Map<String, dynamic>.from(db[cleanEmail] as Map);
    final expectedPass = record['password'] as String?;
    if (expectedPass != password) {
      throw Exception('Incorrect password. Please verify and try again.');
    }

    final profile = UserProfile.fromJson(Map<String, dynamic>.from(record['profile'] as Map));
    await _saveCurrentUser(profile);
    return profile;
  }

  @override
  Future<UserProfile> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    List<String> preferredGenres = const [],
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please provide a valid email');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (displayName.trim().isEmpty) {
      throw Exception('Please provide your name');
    }

    final db = await _getAccountsDb();
    if (db.containsKey(cleanEmail)) {
      throw Exception('An account with $cleanEmail already exists. Please log in.');
    }

    // Map initial taste vector based on user selected genres
    double initialEnergy = 0.65;
    double initialAcoustic = 0.35;
    if (preferredGenres.contains('Rock') || preferredGenres.contains('EDM')) {
      initialEnergy += 0.20;
      initialAcoustic -= 0.15;
    }
    if (preferredGenres.contains('Classical') || preferredGenres.contains('Lo-Fi')) {
      initialEnergy -= 0.25;
      initialAcoustic += 0.35;
    }

    final profile = UserProfile(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: cleanEmail,
      displayName: displayName.trim(),
      photoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      preferredGenres: preferredGenres.isNotEmpty
          ? preferredGenres
          : const ['Rock', 'Pop', 'Lo-Fi'],
      topArtists: const ['Coldplay', 'Queen'],
      tasteVector: AcousticTasteVector(
        energy: initialEnergy.clamp(0.1, 0.95),
        valence: 0.60,
        danceability: 0.62,
        acousticness: initialAcoustic.clamp(0.05, 0.95),
        tempo: 120.0,
      ),
      isGuest: false,
    );

    // Save to registered accounts database
    db[cleanEmail] = {
      'password': password,
      'profile': profile.toJson(),
    };
    await _saveAccountsDb(db);

    await _saveCurrentUser(profile);
    return profile;
  }

  @override
  Future<UserProfile> signInAsEvaluator({String name = 'Professor / Evaluator'}) async {
    final profile = UserProfile.defaultProfile(
      uid: 'evaluator_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    await _saveCurrentUser(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    await _saveCurrentUser(null);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _saveCurrentUser(profile);
    final db = await _getAccountsDb();
    if (db.containsKey(profile.email.toLowerCase())) {
      db[profile.email.toLowerCase()]['profile'] = profile.toJson();
      await _saveAccountsDb(db);
    }
  }
}
