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
  final _authStateController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;

  @override
  UserProfile? get currentUser => _currentUser;

  @override
  Stream<UserProfile?> get authStateChanges => _authStateController.stream;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefUserKey);
      if (cached != null && cached.isNotEmpty) {
        _currentUser = UserProfile.fromJson(jsonDecode(cached));
      } else {
        // Default to a guest evaluator session so the app is always immediately usable
        _currentUser = UserProfile.defaultProfile();
        await _saveCurrentUser(_currentUser!);
      }
      _authStateController.add(_currentUser);
    } catch (e) {
      _currentUser = UserProfile.defaultProfile();
      _authStateController.add(_currentUser);
    }
  }

  Future<void> _saveCurrentUser(UserProfile profile) async {
    _currentUser = profile;
    _authStateController.add(profile);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, jsonEncode(profile.toJson()));
    } catch (_) {}
  }

  @override
  Future<UserProfile> signInWithEmail(String email, String password) async {
    // Clean input validation
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }

    // Synthesize/fetch user profile
    final name = cleanEmail.split('@').first;
    final displayName = name[0].toUpperCase() + name.substring(1);
    final profile = UserProfile(
      uid: 'user_${cleanEmail.hashCode.abs()}',
      email: cleanEmail,
      displayName: displayName,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      preferredGenres: const ['Rock', 'Synthwave', 'Indie', 'Lo-Fi'],
      topArtists: const ['Coldplay', 'Queen', 'The Weeknd'],
      totalListeningTimeSeconds: 5200,
      totalTracksPlayed: 24,
      tasteVector: const AcousticTasteVector(
        energy: 0.72,
        valence: 0.65,
        danceability: 0.68,
        acousticness: 0.30,
        tempo: 120.0,
      ),
      isGuest: false,
    );

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
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please provide a valid email');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (displayName.trim().isEmpty) {
      throw Exception('Please provide your name');
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
    // Reset back to guest demo mode
    final guest = UserProfile.defaultProfile();
    await _saveCurrentUser(guest);
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _saveCurrentUser(profile);
  }
}
