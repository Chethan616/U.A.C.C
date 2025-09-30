import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;

class GoogleAuthService {
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();

  GoogleSignIn? _googleSignIn;
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return; // Prevent multiple initializations

    print("🔧 GoogleAuthService: Initializing Google Sign-In with scopes...");
    _googleSignIn = GoogleSignIn(
      scopes: [
        'email',
        'profile',
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events',
        'https://www.googleapis.com/auth/tasks',
      ],
    );

    _googleSignIn!.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      _currentUser = account;
      print("👤 GoogleAuthService: User changed - ${account?.email ?? 'null'}");
    });

    // Try to sign in silently on app start
    print("🤫 GoogleAuthService: Attempting silent sign-in...");
    _googleSignIn!.signInSilently().then((account) {
      if (account != null) {
        print(
            "✅ GoogleAuthService: Silent sign-in successful - ${account.email}");
      } else {
        print("❌ GoogleAuthService: Silent sign-in failed - no cached user");
      }
    }).catchError((error) {
      print("⚠️ GoogleAuthService: Silent sign-in error - $error");
    });
    _isInitialized = true;
    print("✅ GoogleAuthService: Initialization complete");
  }

  Future<bool> signIn() async {
    if (_googleSignIn == null) {
      print("❌ GoogleAuthService: GoogleSignIn not initialized");
      return false;
    }

    try {
      print("🔐 GoogleAuthService: Starting sign-in process...");
      _currentUser = await _googleSignIn!.signIn();
      if (_currentUser != null) {
        print(
            "✅ GoogleAuthService: Sign-in successful - ${_currentUser!.email}");
        final scopes = await _getGrantedScopes();
        print("📋 GoogleAuthService: Available scopes: $scopes");
        return true;
      } else {
        print("❌ GoogleAuthService: Sign-in failed - user cancelled or error");
        return false;
      }
    } catch (e) {
      print("⚠️ GoogleAuthService: Sign-in error - $e");
      return false;
    }
  }

  Future<bool> signOut() async {
    if (_googleSignIn == null) {
      print("GoogleSignIn not initialized");
      return false;
    }

    try {
      await _googleSignIn!.signOut();
      _currentUser = null;
      return true;
    } catch (e) {
      print("Google sign-out error: $e");
      return false;
    }
  }

  Future<String?> getAccessToken() async {
    if (_currentUser == null) return null;
    try {
      final auth = await _currentUser!.authentication;

      // Check if token is expired and refresh if needed
      if (auth.accessToken == null || _isTokenExpired(auth)) {
        print("Access token expired, attempting to refresh...");
        // Try to sign in silently to refresh token
        if (_googleSignIn != null) {
          await _googleSignIn!.signInSilently();
          final refreshedAuth = await _currentUser!.authentication;
          return refreshedAuth.accessToken;
        }
        return null;
      }

      return auth.accessToken;
    } catch (e) {
      print("Error getting access token: $e");
      // Try to sign in again if token is invalid
      try {
        if (_googleSignIn != null) {
          await _googleSignIn!.signIn();
          final auth = await _currentUser!.authentication;
          return auth.accessToken;
        }
        return null;
      } catch (e2) {
        print("Error re-authenticating: $e2");
        return null;
      }
    }
  }

  bool _isTokenExpired(GoogleSignInAuthentication auth) {
    // Check if we have an access token
    if (auth.accessToken == null) return true;

    // For simplicity, we'll assume token needs refresh if it's been a while
    // In a real app, you'd parse the token and check its expiry
    return false; // Let Google handle token refresh automatically
  }

  Future<http.Client?> getAuthenticatedClient() async {
    if (_currentUser == null) {
      print("❌ GoogleAuthService: No current user for authenticated client");
      return null;
    }

    try {
      print(
          "🔑 GoogleAuthService: Creating authenticated client for ${_currentUser!.email}");
      final authentication = await _currentUser!.authentication;

      if (authentication.accessToken == null) {
        print("❌ GoogleAuthService: No access token available");
        return null;
      }

      print(
          "✅ GoogleAuthService: Access token obtained (length: ${authentication.accessToken!.length})");

      // Create a proper UTC DateTime for expiry (1 hour from now)
      final utcExpiry = DateTime.now().toUtc().add(const Duration(hours: 1));

      // Create OAuth2 credentials with proper UTC expiry handling
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          authentication.accessToken!,
          utcExpiry, // Use properly constructed UTC DateTime
        ),
        null, // No refresh token for Google Sign-In
        [
          'https://www.googleapis.com/auth/calendar',
          'https://www.googleapis.com/auth/calendar.events',
          'https://www.googleapis.com/auth/tasks',
        ],
      );

      print(
          "🌐 GoogleAuthService: Creating authenticated HTTP client with scopes: ${credentials.scopes}");
      // Use googleapis_auth to create authenticated client
      final client = auth.authenticatedClient(http.Client(), credentials);
      print("✅ GoogleAuthService: Authenticated client created successfully");
      return client;
    } catch (e) {
      print("⚠️ GoogleAuthService: Error creating authenticated client - $e");
      return null;
    }
  }

  Future<List<String>> _getGrantedScopes() async {
    try {
      if (_currentUser == null) return [];
      // Note: Google Sign-In doesn't provide a direct way to get granted scopes
      // This is a placeholder that returns the requested scopes
      return [
        'email',
        'profile',
        'https://www.googleapis.com/auth/calendar',
        'https://www.googleapis.com/auth/calendar.events',
        'https://www.googleapis.com/auth/tasks',
      ];
    } catch (e) {
      print("⚠️ GoogleAuthService: Error getting scopes - $e");
      return [];
    }
  }

  GoogleSignInAccount? get currentUser => _currentUser;

  bool get isSignedIn => _currentUser != null;

  String get userEmail => _currentUser?.email ?? '';

  String get userName => _currentUser?.displayName ?? '';

  String get userPhotoUrl => _currentUser?.photoUrl ?? '';
}
