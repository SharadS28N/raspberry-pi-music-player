import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseConfig {
  final String projectId;
  final String apiKey;
  final String appId;

  const FirebaseConfig({
    required this.projectId,
    required this.apiKey,
    this.appId = '',
  });

  bool get isValid => projectId.trim().isNotEmpty && apiKey.trim().isNotEmpty;
}

class FirebaseService extends ChangeNotifier {
  static final FirebaseService instance = FirebaseService._internal();
  FirebaseService._internal();

  static const String _prefProjectIdKey = 'firebase_project_id';
  static const String _prefApiKeyKey = 'firebase_api_key';
  static const String _prefAppIdKey = 'firebase_app_id';

  String _projectId = '';
  String _apiKey = '';
  String _appId = '';

  bool _isConfigured = false;
  bool _isConnected = false;
  DateTime? _lastSyncTime;
  String _statusMessage = 'Local Cache Mode';

  String get projectId => _projectId;
  String get apiKey => _apiKey;
  String get appId => _appId;
  bool get isConfigured => _isConfigured;
  bool get isConnected => _isConnected;
  DateTime? get lastSyncTime => _lastSyncTime;
  String get statusMessage => _statusMessage;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _projectId = prefs.getString(_prefProjectIdKey) ?? '';
      _apiKey = prefs.getString(_prefApiKeyKey) ?? '';
      _appId = prefs.getString(_prefAppIdKey) ?? '';

      if (_projectId.isNotEmpty && _apiKey.isNotEmpty) {
        _isConfigured = true;
        _statusMessage = 'Configured ($projectId)';
        await testConnection();
      } else {
        _isConfigured = false;
        _isConnected = false;
        _statusMessage = 'Local Cache Mode (No Firebase Credentials)';
      }
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Local Cache Mode ($e)';
    }
    notifyListeners();
  }

  Future<void> updateCredentials({
    required String projectId,
    required String apiKey,
    String appId = '',
  }) async {
    _projectId = projectId.trim();
    _apiKey = apiKey.trim();
    _appId = appId.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefProjectIdKey, _projectId);
    await prefs.setString(_prefApiKeyKey, _apiKey);
    await prefs.setString(_prefAppIdKey, _appId);

    _isConfigured = _projectId.isNotEmpty && _apiKey.isNotEmpty;
    if (_isConfigured) {
      await testConnection();
    } else {
      _isConnected = false;
      _statusMessage = 'Local Cache Mode';
      notifyListeners();
    }
  }

  Future<bool> testConnection() async {
    if (!_isConfigured) {
      _isConnected = false;
      _statusMessage = 'Firebase not configured';
      notifyListeners();
      return false;
    }

    try {
      // Test Firebase Auth Identity Toolkit endpoint
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=$_apiKey',
      );
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'continueUri': 'http://localhost',
              'identifier': 'test@openaamps.ai',
            }),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200 || resp.statusCode == 400) {
        // If 200 or 400 with invalid continueUri/auth response, the API key is verified with Google Cloud Identity Toolkit
        _isConnected = true;
        _statusMessage = 'Connected to Firebase ($projectId)';
        notifyListeners();
        return true;
      } else {
        _isConnected = false;
        _statusMessage = 'Firebase Auth error (${resp.statusCode})';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isConnected = false;
      _statusMessage = 'Connection failed ($e)';
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> signInWithFirebase({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) return null;

    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_apiKey',
      );
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _isConnected = true;
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return data;
      }
    } catch (e) {
      debugPrint('[FirebaseService] Sign-in error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> signUpWithFirebase({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) return null;

    try {
      final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$_apiKey',
      );
      final resp = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _isConnected = true;
        _lastSyncTime = DateTime.now();
        notifyListeners();
        return data;
      }
    } catch (e) {
      debugPrint('[FirebaseService] Sign-up error: $e');
    }
    return null;
  }

  Future<bool> syncDocumentToFirestore({
    required String collection,
    required String documentId,
    required Map<String, dynamic> fields,
  }) async {
    if (!_isConfigured || _projectId.isEmpty) return false;

    try {
      final url = Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$_projectId/databases/(default)/documents/$collection/$documentId?key=$_apiKey',
      );

      // Convert standard JSON map to Firestore document structure
      final firestoreFields = <String, dynamic>{};
      fields.forEach((k, v) {
        if (v is String) {
          firestoreFields[k] = {'stringValue': v};
        } else if (v is int) {
          firestoreFields[k] = {'integerValue': v.toString()};
        } else if (v is double) {
          firestoreFields[k] = {'doubleValue': v};
        } else if (v is bool) {
          firestoreFields[k] = {'booleanValue': v};
        } else if (v is List) {
          firestoreFields[k] = {
            'arrayValue': {
              'values': v.map((item) => {'stringValue': item.toString()}).toList(),
            }
          };
        }
      });

      final resp = await http
          .patch(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'fields': firestoreFields}),
          )
          .timeout(const Duration(seconds: 6));

      if (resp.statusCode == 200) {
        _lastSyncTime = DateTime.now();
        _isConnected = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('[FirebaseService] Firestore sync error: $e');
    }
    return false;
  }

  Future<bool> syncAcousticPreferences(Map<String, dynamic> prefs) async {
    return syncDocumentToFirestore(
      collection: 'user_preferences',
      documentId: 'acoustic_profile',
      fields: prefs,
    );
  }
}
