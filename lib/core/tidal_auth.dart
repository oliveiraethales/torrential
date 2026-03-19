import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Audio quality levels matching Tidal's API values.
enum AudioQuality {
  low('LOW', 'Low (AAC 96kbps)'),
  high('HIGH', 'High (AAC 320kbps)'),
  lossless('LOSSLESS', 'Lossless (FLAC 16-bit/44.1kHz)'),
  hiResLossless('HI_RES_LOSSLESS', 'Max (Hi-Res FLAC 24-bit/192kHz)');

  final String apiValue;
  final String label;
  const AudioQuality(this.apiValue, this.label);
}

/// Tidal API client IDs extracted from the official apps.
/// PKCE client is required for Hi-Res FLAC access.
class _TidalCredentials {
  // PKCE client ID — required for HI_RES_LOSSLESS
  static String get clientId {
    final p1 = utf8.decode(base64.decode(utf8.decode(base64.decode('TmtKRVUxSmtjRXM='))));
    final p2 = utf8.decode(base64.decode(utf8.decode(base64.decode('NWFIRkZRbFJuVlE9PQ=='))));
    return '$p1$p2';
  }
}

/// Result of initiating the device authorization flow.
class DeviceAuthResult {
  final String deviceCode;
  final String userCode;
  final String verificationUri;
  final String verificationUriComplete;
  final int expiresIn;
  final int interval;

  DeviceAuthResult({
    required this.deviceCode,
    required this.userCode,
    required this.verificationUri,
    required this.verificationUriComplete,
    required this.expiresIn,
    required this.interval,
  });

  factory DeviceAuthResult.fromJson(Map<String, dynamic> json) {
    return DeviceAuthResult(
      deviceCode: json['deviceCode'] as String,
      userCode: json['userCode'] as String,
      verificationUri: json['verificationUri'] as String,
      verificationUriComplete: json['verificationUriComplete'] as String,
      expiresIn: json['expiresIn'] as int,
      interval: json['interval'] as int,
    );
  }
}

/// Stored session tokens.
class TidalTokens {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime expiresAt;
  final int? userId;
  final String? countryCode;

  TidalTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresAt,
    this.userId,
    this.countryCode,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresAt': expiresAt.toIso8601String(),
        'userId': userId,
        'countryCode': countryCode,
      };

  factory TidalTokens.fromJson(Map<String, dynamic> json) {
    return TidalTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      userId: json['userId'] as int?,
      countryCode: json['countryCode'] as String?,
    );
  }
}

/// Handles Tidal OAuth2 PKCE authentication flow.
class TidalAuth {
  static const _authBaseUrl = 'https://auth.tidal.com/v1/oauth2';
  static const _apiBaseUrl = 'https://api.tidal.com/v1';
  static const _tokenKey = 'tidal_tokens';

  final http.Client _httpClient;
  TidalTokens? _tokens;

  TidalTokens? get tokens => _tokens;
  bool get isLoggedIn => _tokens != null && !_tokens!.isExpired;
  String get clientId => _TidalCredentials.clientId;

  TidalAuth({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  /// Generate PKCE code verifier (43-128 chars, unreserved characters).
  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  /// Generate S256 PKCE code challenge from verifier.
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Try to restore a saved session.
  Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_tokenKey);
    if (stored == null) return false;

    try {
      _tokens = TidalTokens.fromJson(jsonDecode(stored) as Map<String, dynamic>);
      if (_tokens!.isExpired) {
        return await _refreshToken();
      }
      return true;
    } catch (_) {
      await prefs.remove(_tokenKey);
      return false;
    }
  }

  /// Start the device authorization flow.
  /// Returns device auth info for the user to visit the verification URL.
  Future<DeviceAuthResult> startDeviceAuth() async {
    final response = await _httpClient.post(
      Uri.parse('$_authBaseUrl/device_authorization'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'scope': 'r_usr w_usr w_sub',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Device auth failed: ${response.statusCode} ${response.body}');
    }

    return DeviceAuthResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Poll for token after user has authorized via the verification URL.
  /// Returns true when authorization is complete.
  Future<bool> pollForToken(DeviceAuthResult authResult) async {
    final response = await _httpClient.post(
      Uri.parse('$_authBaseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'device_code': authResult.deviceCode,
        'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        'scope': 'r_usr w_usr w_sub',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _tokens = TidalTokens(
        accessToken: data['access_token'] as String,
        refreshToken: data['refresh_token'] as String,
        tokenType: data['token_type'] as String,
        expiresAt: DateTime.now().add(
          Duration(seconds: data['expires_in'] as int),
        ),
      );

      // Fetch user info
      await _fetchUserInfo();
      await _saveTokens();
      return true;
    }

    // 400 with authorization_pending means keep polling
    if (response.statusCode == 400) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['error'] == 'authorization_pending') {
        return false;
      }
      if (data['error'] == 'expired_token') {
        throw Exception('Authorization expired. Please try again.');
      }
    }

    throw Exception('Token poll failed: ${response.statusCode} ${response.body}');
  }

  /// Refresh the access token using the refresh token.
  Future<bool> _refreshToken() async {
    if (_tokens == null) return false;

    final response = await _httpClient.post(
      Uri.parse('$_authBaseUrl/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'grant_type': 'refresh_token',
        'refresh_token': _tokens!.refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _tokens = TidalTokens(
        accessToken: data['access_token'] as String,
        refreshToken: _tokens!.refreshToken,
        tokenType: data['token_type'] as String,
        expiresAt: DateTime.now().add(
          Duration(seconds: data['expires_in'] as int),
        ),
        userId: _tokens!.userId,
        countryCode: _tokens!.countryCode,
      );
      await _saveTokens();
      return true;
    }

    // Refresh failed — clear tokens
    await logout();
    return false;
  }

  /// Fetch user session info (userId, countryCode).
  Future<void> _fetchUserInfo() async {
    if (_tokens == null) return;

    final response = await _httpClient.get(
      Uri.parse('$_apiBaseUrl/sessions'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _tokens = TidalTokens(
        accessToken: _tokens!.accessToken,
        refreshToken: _tokens!.refreshToken,
        tokenType: _tokens!.tokenType,
        expiresAt: _tokens!.expiresAt,
        userId: data['userId'] as int?,
        countryCode: data['countryCode'] as String?,
      );
    }
  }

  /// Ensure token is valid, refreshing if needed.
  Future<void> ensureValidToken() async {
    if (_tokens == null) throw Exception('Not logged in');
    if (_tokens!.isExpired) {
      final success = await _refreshToken();
      if (!success) throw Exception('Session expired. Please log in again.');
    }
  }

  /// Get authorization headers for API requests.
  Map<String, String> _authHeaders() {
    return {
      'Authorization': '${_tokens!.tokenType} ${_tokens!.accessToken}',
    };
  }

  /// Get headers for Tidal API v1 requests.
  Map<String, String> get apiHeaders {
    if (_tokens == null) throw Exception('Not logged in');
    return {
      'Authorization': '${_tokens!.tokenType} ${_tokens!.accessToken}',
      'x-tidal-token': clientId,
    };
  }

  String get countryCode => _tokens?.countryCode ?? 'US';
  int? get userId => _tokens?.userId;

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, jsonEncode(_tokens!.toJson()));
  }

  Future<void> logout() async {
    _tokens = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}
