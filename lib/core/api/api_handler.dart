// lib/core/api/api_handler.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:heavy_new/core/api/envelope.dart';
import 'package:heavy_new/core/models/admin/notifications_model.dart';
import 'package:heavy_new/core/models/admin/request_driver_location.dart';
import 'package:heavy_new/core/models/contracts/contract.dart';
import 'package:heavy_new/core/models/contracts/contract_slice.dart';
import 'package:heavy_new/core/models/contracts/contract_slice_sheet.dart';
import 'package:heavy_new/core/models/organization/organization_summary.dart';
import 'package:http/http.dart' as http;

// MODELS
import 'package:heavy_new/core/models/admin/brand.dart';
import 'package:heavy_new/core/models/admin/domain.dart';
import 'package:heavy_new/core/models/admin/employee.dart';
import 'package:heavy_new/core/models/admin/factory.dart';
import 'package:heavy_new/core/models/admin/request.dart';
import 'package:heavy_new/core/models/equipment/equipment.dart';
import 'package:heavy_new/core/models/equipment/equipment_list.dart';
import 'package:heavy_new/core/models/equipment/equipment_location.dart';
import 'package:heavy_new/core/models/equipment/equipment_rate.dart';
import 'package:heavy_new/core/models/equipment/terms.dart';
import 'package:heavy_new/core/models/manage_files/file_request.dart';
import 'package:heavy_new/core/models/manage_files/file_response.dart';
import 'package:heavy_new/core/models/organization/organization_file.dart';
import 'package:heavy_new/core/models/organization/organization_user.dart';
import 'package:heavy_new/core/models/user/auth.dart';
import 'package:heavy_new/core/models/user/city.dart';
import 'package:heavy_new/core/models/user/nationality.dart';
import 'package:heavy_new/core/models/user/user_account.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final Map<String, dynamic>? details; // parsed problem/errors
  ApiException(this.message, {this.statusCode, this.details});
  @override
  String toString() =>
      'ApiException($statusCode): $message'
      '${details != null ? ' | ${jsonEncode(details)}' : ''}';
}

class CertUploadResult {
  final int modelId;
  final String fileName;
  final String publicUrl;
  final ApiEnvelope dbEnvelope;
  final ApiEnvelope uploadEnvelope;

  CertUploadResult({
    required this.modelId,
    required this.fileName,
    required this.publicUrl,
    required this.dbEnvelope,
    required this.uploadEnvelope,
  });
}

class UploadResult {
  final int modelId;
  final String fileName;
  final String publicUrl;

  // Useful to inspect/full logging if needed:
  final ApiEnvelope dbEnvelope;
  final ApiEnvelope uploadEnvelope;

  UploadResult({
    required this.modelId,
    required this.fileName,
    required this.publicUrl,
    required this.dbEnvelope,
    required this.uploadEnvelope,
  });

  @override
  String toString() =>
      'UploadResult(modelId=$modelId, fileName=$fileName, publicUrl=$publicUrl)';
}

extension on DateTime {
  String get ymd =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
}

dynamic _handleResponse(http.Response r) {
  final code = r.statusCode;
  if (code >= 200 && code < 300) {
    if (r.body.isEmpty) return null;
    try {
      return json.decode(r.body);
    } catch (_) {
      return r.body; // plain text
    }
  }

  // Try to decode standard ASP.NET ProblemDetails / ModelState
  Map<String, dynamic>? parsed;
  try {
    parsed = r.body.isNotEmpty ? json.decode(r.body) : null;
  } catch (_) {
    parsed = null;
  }

  // Build a clear message
  var msg = 'HTTP $code';
  if (parsed != null) {
    if (parsed['title'] is String) {
      msg = parsed['title'];
    }
    // ASP.NET validation looks like: { "errors": { "Field": ["err1","err2"] } }
    if (parsed['errors'] is Map) {
      final errs = (parsed['errors'] as Map).entries
          .map((e) => '${e.key}: ${(e.value as List?)?.join(" | ") ?? e.value}')
          .join(' • ');
      if (errs.isNotEmpty) msg = '${msg}: $errs';
    }
  } else if (r.body.isNotEmpty) {
    msg = '$msg: ${r.body}';
  }

  debugPrint('[API] ERROR $code -> $msg');
  if (parsed != null) debugPrint('[API] ProblemDetails: ${jsonEncode(parsed)}');

  throw ApiException(msg, statusCode: code, details: parsed);
}

class Api {
  static const String _kFilePath = 'StaticFiles';
  static const String _kFileModelPath = 'equipimageFiles';
  static const String equipCertsFolder = 'equipcertFiles';
  static const String _kPublicBase =
      'https://sr.visioncit.com/StaticFiles/equipimageFiles/';

  static Future<CertUploadResult> uploadEquipmentCertificateFromPath({
    required int equipmentId,
    int? equipmentCertificateId,
    required int typeId,
    required String nameEnglish,
    required String nameArabic,
    required DateTime issueDate,
    required DateTime expireDate,
    required String path,
    String? originalFileName,
    required bool isImage,
  }) async {
    if (kIsWeb) {
      throw ApiException('Path-based upload is not supported on web.');
    }
    final bytes = await File(path).readAsBytes();
    return uploadEquipmentCertificate(
      equipmentId: equipmentId,
      equipmentCertificateId: equipmentCertificateId,
      typeId: typeId,
      nameEnglish: nameEnglish,
      nameArabic: nameArabic,
      issueDate: issueDate,
      expireDate: expireDate,
      fileBytes: bytes,
      originalFileName:
          originalFileName ?? path.split(Platform.pathSeparator).last,
      isImage: isImage,
    );
  }

  //--------------------------------------------------------------------------------------------------------------------------
  // ---- Config (safe defaults so you never get LateInitializationError) ----
  static String _baseUrl = 'https://sr.visioncit.com/api/';
  // ignore: unused_field
  static Duration _timeout = const Duration(seconds: 30);
  // ignore: unused_field
  static Map<String, String> _defaultHeaders = const {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  static String? _token;

  static final http.Client _client = http.Client();

  // Prefer this to build the "stream file through API" URL.
  static String fileUrlFromName(String? name) {
    if (name == null) return '';
    final n = name.trim();
    if (n.isEmpty) return '';
    if (n.startsWith('http://') || n.startsWith('https://')) return n;
    final encoded = Uri.encodeComponent(n);
    return _u('ManageFiles/GetFile?fileName=$encoded').toString();
  }

  static String _originFromBase() {
    final u = Uri.parse(_baseUrl); // usually .../api/
    return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}/';
  }
  // === Equipment image URLs (CDN) ==============================================

  // Base: https://sr.visioncit.com/StaticFiles/equipimageFiles/
  static String _equipImageBase() {
    final u = Uri.parse(_baseUrl); // e.g. https://sr.visioncit.com/api/
    final origin = '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
    return '$origin/StaticFiles/equipimageFiles/';
  }

  /// Build a single full URL for an equipment image name.
  static String equipmentImageUrl(String? name) {
    if (name == null) return '';
    var n = name.trim();
    if (n.isEmpty) return '';
    if (n.startsWith('http://') || n.startsWith('https://')) return n;

    // keep only the file name (if the API sometimes returns "folder/file.jpg")
    n = n.replaceAll('\\', '/').split('/').last;
    final encoded = Uri.encodeComponent(n);
    return '${_equipImageBase()}$encoded';
  }

  /// Be generous with candidates: encoded + raw + (rare) already-prefixed.
  static List<String> equipmentImageCandidates(String? name) {
    if (name == null) return const [];
    var n = name.trim();
    if (n.isEmpty) return const [];
    if (n.startsWith('http://') || n.startsWith('https://')) return [n];

    n = n.replaceAll('\\', '/').split('/').last; // basename
    final base = _equipImageBase();
    final enc = Uri.encodeComponent(n);

    // de-dupe while preserving order
    final set = <String>{};
    set.add('$base$enc'); // preferred
    set.add('$base$n'); // unencoded (in case server handles it)
    // in case API accidentally already sends the full folder
    set.add(
      '$base${n.replaceFirst(RegExp(r'^(StaticFiles/)?equipimageFiles/'), '')}',
    );
    return set.toList();
  }

  /// Guessed public folders (fallbacks if GetFile doesn't work)
  static List<String> fileCandidates(String? name) {
    if (name == null || name.trim().isEmpty) return const [];
    final n = name.startsWith('/') ? name.substring(1) : name;
    if (name.startsWith('http://') || name.startsWith('https://')) {
      return [name];
    }

    final origin = _originFromBase();
    final prefixes = <String>[
      origin,
      '${origin}StaticFiles/', // some hosts expose static under /api
      '${origin}factoryFiles/',
      '${origin}eqplstFiles/',
      '${origin}orgfileFiles/',
      '${origin}equipimageFiles/',
      '${origin}equipcertFiles/',
      '${origin}driverdocFiles/',
      '${origin}userdocFiles/',
      '${origin}otherFiles/',
    ];

    final out = <String>{};
    for (final p in prefixes) {
      out.add('$p$n');
    }
    return out.toList();
  }

  static List<String> imageCandidates(String? name) {
    final first = fileUrlFromName(name);
    final rest = fileCandidates(name);
    final set = <String>{};
    if (first.isNotEmpty) set.add(first);
    set.addAll(rest);
    return set.toList();
  }

  static Map<String, String> imageAuthHeaders() {
    return (_token != null && _token!.isNotEmpty)
        ? {'Authorization': 'Bearer $_token'}
        : const {};
  }

  /// Optional one-liner at startup.
  static void init({
    String? baseUrl,
    Duration? timeout,
    Map<String, String>? defaultHeaders,
    String? token,
  }) {
    if (baseUrl != null) setBaseUrl(baseUrl);
    if (timeout != null) setTimeout(timeout);
    if (defaultHeaders != null) setDefaultHeaders(defaultHeaders);
    if (token != null) setToken(token);
  }

  static void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  static void setToken(String? token) {
    _token = token;
  }

  static void setTimeout(Duration timeout) {
    _timeout = timeout;
  }

  static void setDefaultHeaders(Map<String, String> headers) {
    _defaultHeaders = {
      ...headers,
      // Always ensure these unless you purposely override:
      'Accept': headers['Accept'] ?? 'application/json',
      'Content-Type': headers['Content-Type'] ?? 'application/json',
    };
  }

  // ===== Auth glue (lightweight, no tight coupling) =====

  static String? Function()? _getRefreshToken; // returns refreshToken or null
  static Future<void> Function(AuthTokens tokens)? _onTokensUpdated;

  static void registerAuthHooks({
    String? Function()? getRefreshToken,
    Future<void> Function(AuthTokens tokens)? onTokensUpdated,
  }) {
    _getRefreshToken = getRefreshToken;
    _onTokensUpdated = onTokensUpdated;
  }

  // ---- Low-level helpers ----

  static const _orgFilesBase =
      'https://sr.visioncit.com/StaticFiles/orgfileFiles/';

  static Future<bool> orgStaticFileExists(String fileName) async {
    if (fileName.trim().isEmpty) return false;
    final url = Uri.parse('$_orgFilesBase${Uri.encodeComponent(fileName)}');
    try {
      final r = await http.head(url);
      return r.statusCode >= 200 && r.statusCode < 400;
    } catch (_) {
      return false;
    }
  }

  // ===== URL + headers =====

  static Uri _u(String path) {
    if (path.startsWith('http')) return Uri.parse(path);
    final clean = path.startsWith('/') ? path.substring(1) : path;
    return Uri.parse('$_baseUrl$clean');
  }

  static Map<String, String> _headers() => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    if ((_token?.isNotEmpty ?? false)) 'Authorization': 'Bearer $_token',
  };

  static Uri _uri(String path) {
    final b = _baseUrl.replaceAll(RegExp(r'/+$'), '');
    final p = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$b/$p');
  }

  static dynamic _decodeBody(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }

  // Helpers to safely send JSON from static methods
  static Object? _encodeBody(Object? body) {
    // If it's already String/bytes, send as-is; else JSON-encode.
    if (body == null || body is String || body is List<int>) return body;
    return jsonEncode(body);
  }

  static Map<String, String> _mergeJsonHeaders(Map<String, String>? headers) {
    final h = <String, String>{'Accept': 'application/json'};
    if (headers != null) h.addAll(headers);
    // Force JSON unless caller explicitly overrides
    h.putIfAbsent('Content-Type', () => 'application/json; charset=utf-8');
    return h;
  }

  // ===== Core HTTP with 401 auto-refresh/retry (once) =====

  static Future<dynamic> _get(String path, {Duration? timeout}) async {
    return _sendWithAuthRetry(
      () => _client.get(_u(path), headers: _headers()),
      debugPrint(path),
      timeout: timeout,
    );
  }

  // --- FIXED: JSON-aware POST ---
  static Future<dynamic> _post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path);
    final h = _mergeJsonHeaders(headers);

    final resp = await http.post(uri, headers: h, body: _encodeBody(body));
    final text = resp.body;

    if (kDebugMode) {
      debugPrint('[Api._post] $path -> ${resp.statusCode} $text');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return text.isEmpty ? null : _decodeBody(text);
    }
    throw Exception('POST $path failed: ${resp.statusCode} $text');
  }

  static Future<dynamic> _postJsonRdl(
    String path,
    Object? body, {
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path);
    final h = _mergeJsonHeaders(headers);
    final payload = _encodeBody(body);

    // Log outgoing payload (pretty)
    dev.log(
      '[Api._postJsonRdl] $path — sending payload:\n${_prettyJson(body)}',
      name: 'API',
    );

    final resp = await http.post(uri, headers: h, body: payload);
    final text = resp.body;

    if (kDebugMode) {
      debugPrint('[Api._postJsonRdl] $path <- ${resp.statusCode} $text');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return text.isEmpty ? null : _decodeBody(text);
    }
    throw Exception('POST $path failed: ${resp.statusCode} $text');
  }

  static Future<Map<String, dynamic>> _getJson(String route) async {
    final uri = Uri.parse('https://sr.visioncit.com/api/$route');
    final headers = <String, String>{'Accept': 'application/json'};
    final resp = await http.get(uri, headers: headers);
    _d('← GET $route status=${resp.statusCode} body=${resp.body}');
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw ApiException(
        'HTTP ${resp.statusCode}',
        statusCode: resp.statusCode,
      );
    }
    final decoded = jsonDecode(resp.body);
    return (decoded is Map<String, dynamic>)
        ? decoded
        : <String, dynamic>{'data': decoded};
  }

  static Future<dynamic> _put(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final uri = _uri(path);
    final h = _mergeJsonHeaders(headers);
    dev.log(
      '[Api._put] $path  — sending payload:\n${_prettyJson(body)}',
      name: 'API',
    );

    final resp = await http.put(uri, headers: h, body: _encodeBody(body));
    final text = resp.body;

    if (kDebugMode) {
      debugPrint('[Api._put] $path -> ${resp.statusCode} $text');
    }

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return text.isEmpty ? null : _decodeBody(text);
    }
    throw Exception('PUT $path failed: ${resp.statusCode} $text');
  }

  static Future<dynamic> _delete(String path, {Duration? timeout}) async {
    return _sendWithAuthRetry(
      () => _client.delete(_u(path), headers: _headers()),
      debugPrint(path),
      timeout: timeout,
    );
  }

  /// Wraps a single request. If it returns 401/403, tries refresh token
  /// (if provided) and replays the request once.
  static Future<dynamic> _sendWithAuthRetry(
    Future<http.Response> Function() send,
    void param1, {
    Duration? timeout,
  }) async {
    try {
      final res = await (timeout == null ? send() : send().timeout(timeout));
      if (_isAuthError(res.statusCode)) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          final retry = await (timeout == null
              ? send()
              : send().timeout(timeout));
          return _handleResponse(retry);
        }
      }
      return _handleResponse(res);
    } on TimeoutException {
      throw ApiException(
        'The request timed out. Please check your connection.',
      );
    } on SocketException {
      throw ApiException('No internet connection. Please try again.');
    } catch (e) {
      // _handleResponse throws ApiException for HTTP errors; keep that behavior
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  static bool _refreshInFlight = false;

  // Call this once from AuthStore.init()
  static void configureAuthHooks({
    required String Function() getRefreshToken,
    required Future<void> Function(AuthTokens) onTokensUpdated,
  }) {
    _getRefreshToken = getRefreshToken;
    _onTokensUpdated = onTokensUpdated;
  }

  // Make the private helper publicly callable
  static Future<bool> tryRefreshToken() => _tryRefreshToken();

  // (your existing private helper)
  static Future<bool> _tryRefreshToken() async {
    if (_refreshInFlight) return false; // prevent stampede
    final rt = _getRefreshToken?.call();
    if (rt == null || rt.isEmpty) return false;

    _refreshInFlight = true;
    try {
      final tokens = await refreshToken(RefreshTokenRequest(rt));
      await _onTokensUpdated?.call(tokens);
      return tokens.token.isNotEmpty;
    } catch (_) {
      return false;
    } finally {
      _refreshInFlight = false;
    }
  }

  static bool _isAuthError(int code) => code == 401 || code == 403;

  // ===== Response handling & utils (unchanged behavior, slightly hardened) =====

  // Utilities for payloads
  static List _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      if (raw['data'] is List) return List.from(raw['data']);
      if (raw['result'] is List) return List.from(raw['result']);
    }
    return const [];
  }

  static Map<String, dynamic> _unwrapMap(
    dynamic raw, {
    required ApiEnvelope envelope,
  }) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return Map<String, dynamic>.from(raw.first as Map);
    }
    return <String, dynamic>{};
  }

  static dynamic _stripNullsDeep(dynamic v) {
    if (v is Map<String, dynamic>) {
      final out = <String, dynamic>{};
      v.forEach((k, val) {
        final s = _stripNullsDeep(val);
        if (s != null) out[k] = s;
      });
      return out;
    }
    if (v is List) {
      return v.map(_stripNullsDeep).where((e) => e != null).toList();
    }
    return v; // keep non-null scalars (incl. false/0)
  }

  // --- Public helper: one-call flow -----------------------------------------

  static Future<UploadResult> uploadEquipmentImage({
    required int equipmentId,
    required Uint8List fileBytes,
    String? originalFileName, // optional, used for extension inference
    bool isActive = true,
  }) async {
    final ext = _inferExtension(originalFileName, fileBytes) ?? 'jpg';
    final isPdf = ext.toLowerCase() == 'pdf';
    final fileName = _makeServerFileName(ext);
    final mime = _mimeFromExt(ext);

    // 1) Create DB row first (so we get modelId)
    final env = await addEquipmentImageEnvelope(
      EquipmentImage(
        equipmentImageId: 0,
        equipmentId: equipmentId,
        equipmentPath: fileName, // IMPORTANT: same name we’ll upload
        isActive: isActive,
        createDateTime: DateTime.now().toUtc(),
        modifyDateTime: DateTime.now().toUtc(),
      ),
    );

    if (env.flag != true || env.modelId == null) {
      throw ApiException(
        'EquipmentImage/add failed: ${env.message ?? 'Unknown error'}',
      );
    }

    // 2) Upload physical file using modelId from step 1
    final req = ManageFileRequest(
      fileId: 0,
      modelId: env.modelId,
      fileBytes: base64Encode(fileBytes), // NO data: prefix
      offset: 0, // not used by your SaveUploadFile action
      fileName: fileName,
      filePath: _kFilePath,
      fileType: mime,
      fileExt: ext,
      fileModelPath: _kFileModelPath,
      fileViewerPath: '',
      fileViewerByte: '',
      isImage: !isPdf,
      isPdf: isPdf,
      fileMessage: '',
    );

    final raw = await _post(
      'ManageFiles/SaveUploadFile',
      body: _stripNullsDeep(req.toJson()),
    );
    final uploadEnv = ApiEnvelope.fromAny(raw);

    if (uploadEnv.flag != true) {
      throw ApiException(
        'SaveUploadFile failed: ${uploadEnv.message ?? 'Unknown error'}',
      );
    }

    // Backend returns file url in otherResult (relative path). Fall back to known pattern.
    final relative = (uploadEnv.raw['otherResult'] as String?)?.trim();
    final publicUrl = (relative != null && relative.isNotEmpty)
        ? 'https://sr.visioncit.com/$relative'
        : '$_kPublicBase${Uri.encodeComponent(fileName)}';

    return UploadResult(
      modelId: env.modelId!,
      fileName: fileName,
      publicUrl: publicUrl,
      dbEnvelope: env,
      uploadEnvelope: uploadEnv,
    );
  }

  /// Convenience overload: pass an [XFile] (image_picker)
  static Future<UploadResult> uploadEquipmentImageFromXFile({
    required int equipmentId,
    required XFile xfile,
    bool isActive = true,
  }) async {
    final bytes = await xfile.readAsBytes();
    return uploadEquipmentImage(
      equipmentId: equipmentId,
      fileBytes: bytes,
      originalFileName: xfile.name,
      isActive: isActive,
    );
  }

  /// Convenience overload: pass a disk path (not for web)
  static Future<UploadResult> uploadEquipmentImageFromPath({
    required int equipmentId,
    required String path,
    bool isActive = true,
  }) async {
    if (kIsWeb) {
      throw ApiException(
        'uploadEquipmentImageFromPath is not supported on web.',
      );
    }
    final file = File(path);
    final bytes = await file.readAsBytes();
    final name = path.split(Platform.pathSeparator).last;
    return uploadEquipmentImage(
      equipmentId: equipmentId,
      fileBytes: bytes,
      originalFileName: name,
      isActive: isActive,
    );
  }

  // --- EquipmentImage helpers ------------------------------------------------
  /// Same as your existing add, but returns the envelope so we can read modelId.
  static Future<ApiEnvelope> addEquipmentImageEnvelope(
    EquipmentImage image,
  ) async {
    final raw = await _post(
      'EquipmentImage/add',
      body: _stripNullsDeep(image.toJson()),
    );
    return ApiEnvelope.fromAny(raw);
  }

  // --- Filename & MIME helpers ----------------------------------------------
  static String _makeServerFileName(String ext) {
    // Example pattern similar to: "23-07-25175326<random>.png"
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');

    final dd = two(now.day);
    final mm = two(now.month);
    final yy = two(now.year % 100);
    final HH = two(now.hour);
    final MM = two(now.minute);
    final SS = two(now.second);

    final rand = _randomDigits(16);
    return '$dd-$mm-$yy$HH$MM$SS$rand.$ext';
  }

  static String _randomDigits(int count) {
    final r = Random.secure();
    final sb = StringBuffer();
    for (var i = 0; i < count; i++) {
      sb.write(r.nextInt(10)); // 0-9
    }
    return sb.toString();
  }

  static String _mimeFromExt(String ext) {
    final e = ext.toLowerCase();
    switch (e) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      default:
        // Fallback to octet-stream (server ignores it anyway for images)
        return 'application/octet-stream';
    }
  }

  static String? _inferExtension(String? original, Uint8List bytes) {
    // 1) Prefer the original file name
    final name = original ?? '';
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }

    // 2) Basic “magic number” sniffing as fallback (very minimal; extend as needed)
    if (bytes.length >= 4) {
      // PNG: 89 50 4E 47
      if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47) {
        return 'png';
      }
      // JPG: FF D8 ... FF D9
      if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
        return 'jpg';
      }
      // PDF: 25 50 44 46
      if (bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46) {
        return 'pdf';
      }
      // WEBP: "RIFF....WEBP"
      if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46) {
        return 'webp';
      }
    }
    return null;
  }

  //certificates images

  static Future<CertUploadResult> uploadEquipmentCertificate({
    required int equipmentId,
    int? equipmentCertificateId, // null to add, else update existing
    required int typeId,
    required String nameEnglish,
    required String nameArabic,
    required DateTime issueDate,
    required DateTime expireDate,
    required Uint8List fileBytes,
    String? originalFileName, // used to infer ext
    required bool isImage, // from UI toggle
  }) async {
    final ext = _inferExtension(originalFileName, fileBytes) ?? 'jpg';
    final isPdf = ext.toLowerCase() == 'pdf';
    final fileName = _makeServerFileName(ext);
    final mime = _mimeFromExt(ext);

    final now = DateTime.now().toUtc();

    // Build payload with the final file name we will upload
    final certPayload = EquipmentCertificate(
      equipmentCertificateId: equipmentCertificateId,
      equipmentId: equipmentId,
      typeId: typeId,
      nameArabic: nameArabic.trim(),
      nameEnglish: nameEnglish.trim(),
      issueDate: issueDate.ymd,
      expireDate: expireDate.ymd,
      isExpire: expireDate.isBefore(DateTime.now()),
      isActive: true,
      createDateTime: equipmentCertificateId == null ? now : null,
      modifyDateTime: now,
      documentPath: fileName, // <- IMPORTANT: DB must point to this
      documentType: null,
      isImage: isImage && !isPdf, // force false for PDFs
    );

    // 1) Upsert the DB row (so we get modelId)
    final env = (equipmentCertificateId == null)
        ? await _addCertificateEnvelope(certPayload)
        : await _updateCertificateEnvelope(certPayload);

    final modelId = env.modelId ?? equipmentCertificateId;
    if (env.flag != true || modelId == null) {
      throw ApiException(
        'Certificate save failed: ${env.message ?? 'Unknown error'}',
      );
    }

    // 2) Upload physical file using modelId
    final req = ManageFileRequest(
      fileId: 0,
      modelId: modelId,
      fileBytes: base64Encode(fileBytes),
      offset: 0,
      fileName: fileName,
      filePath: _kFilePath, // "StaticFiles"
      fileType: mime,
      fileExt: ext,
      fileModelPath: equipCertsFolder, // "equipcertFiles"
      fileViewerPath: '',
      fileViewerByte: '',
      isImage: !isPdf,
      isPdf: isPdf,
      fileMessage: '',
    );

    final raw = await _post(
      'ManageFiles/SaveUploadFile',
      body: _stripNullsDeep(req.toJson()),
    );
    final uploadEnv = ApiEnvelope.fromAny(raw);

    if (uploadEnv.flag != true) {
      throw ApiException(
        'SaveUploadFile failed: ${uploadEnv.message ?? 'Unknown error'}',
      );
    }

    final relative = (uploadEnv.raw['otherResult'] as String?)?.trim();
    final publicUrl = (relative != null && relative.isNotEmpty)
        ? 'https://sr.visioncit.com/$relative'
        : 'https://sr.visioncit.com/StaticFiles/$equipCertsFolder/${Uri.encodeComponent(fileName)}';

    return CertUploadResult(
      modelId: modelId,
      fileName: fileName,
      publicUrl: publicUrl,
      dbEnvelope: env,
      uploadEnvelope: uploadEnv,
    );
  }

  // ---- private wrappers to get envelopes for add/update --------------------
  static Future<ApiEnvelope> _addCertificateEnvelope(
    EquipmentCertificate c,
  ) async {
    final raw = await _post(
      'EquipmentCertificate/add',
      body: _stripNullsDeep(c.toJson()),
    );
    return ApiEnvelope.fromAny(raw);
  }

  static Future<ApiEnvelope> _updateCertificateEnvelope(
    EquipmentCertificate c,
  ) async {
    final raw = await _put(
      'EquipmentCertificate/update',
      body: _stripNullsDeep(c.toJson()),
    );
    return ApiEnvelope.fromAny(raw);
  }

  // ---------------------------------------------------------------------------
  // ENDPOINTS
  // ---------------------------------------------------------------------------

  // -------- NOTIFICATIONS --------
  static Future<List<NotificationsModel>> getNotfTokenById(int userId) async {
    final raw = await _get('TokenFirebase/$userId');
    final list = _unwrapList(raw);
    return list
        .map((e) => NotificationsModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<NotificationsModel> addNotfToken(
    NotificationsModel token,
  ) async {
    final raw = await _post(
      'TokenFirebase/add',
      body: _stripNullsDeep(token.toJson()),
    );
    return NotificationsModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<UserMessage> sendNotif(UserMessage message) async {
    final raw = await _post('UserMessage/sendfcm', body: message.toJson());

    // If your API wraps data, unwrap here; otherwise parse directly:
    final data = _unwrapMap(
      raw,
      envelope: ApiEnvelope(),
    ); // if you have envelopes
    return UserMessage.fromJson(data);
  }

  // -------- NOTIF MESSAGE --------
  static Future<UserMessage> getNotifMessageById(UserMessage id) async {
    final raw = await _get('UserMessage/${id}');
    return UserMessage.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<UserMessage> addNotifMessage(UserMessage message) async {
    final raw = await _post(
      'UserMessage/add',
      body: _stripNullsDeep(message.toJson()),
    );
    return UserMessage.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  // -------- AUTH --------

  // Toggleable debug flag
  static bool _debugApi = true;

  // Tiny safe logger
  static void _d(String msg) {
    if (_debugApi && kDebugMode) debugPrint('[API] $msg');
  }

  // Pretty printer for responses
  static String _pretty(dynamic v) {
    try {
      if (v is String) return v;
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  // Mask secrets in logs
  static String _mask(String? s, {int keepStart = 6, int keepEnd = 4}) {
    if (s == null || s.isEmpty) return '';
    if (s.length <= keepStart + keepEnd) return '***';
    return '${s.substring(0, keepStart)}…${s.substring(s.length - keepEnd)}';
  }

  // ✔ Returns envelope (message contains the OTP hint; modelId is the user id)
  static Future<ApiEnvelope> checkUserByMobile({
    required String mobile,
    int? countryCode,
  }) async {
    final body = <String, dynamic>{
      'mobile': mobile,
      if (countryCode != null) 'countryCode': countryCode,
    };

    _d('→ POST Authentication/CheckUserByMobile body=${jsonEncode(body)}');

    try {
      final raw = await _post('Authentication/CheckUserByMobile', body: body);
      _d('← RESP CheckUserByMobile raw:\n${_pretty(raw)}');

      final env = ApiEnvelope.fromJson(
        _unwrapMap(raw, envelope: ApiEnvelope()),
      );
      _d(
        '← ENV CheckUserByMobile: '
        'flag=${env.flag} type=${env.responseType} '
        'message="${env.message}" modelId=${env.modelId} '
        'token?=${(env.token?.isNotEmpty ?? false)}',
      );

      return env;
    } on ApiException catch (e) {
      _d(
        '✗ API ERR CheckUserByMobile status=${e.statusCode} '
        'msg="${e.message}" data:\n${_pretty(e.message)}',
      );
      rethrow;
    } catch (e, st) {
      _d('✗ ERR CheckUserByMobile $e\n$st');
      rethrow;
    }
  }

  // ✔ Verifies OTP and returns tokens (and sets bearer on success)
  static Future<AuthTokens> checkOtpCode({
    required String mobile,
    required String otpcode,
  }) async {
    final body = {'mobile': mobile, 'otpcode': otpcode};
    _d('→ POST Authentication/CheckOTPCode body=${jsonEncode(body)}');

    try {
      final raw = await _post('Authentication/CheckOTPCode', body: body);
      _d('← RESP CheckOTPCode raw:\n${_pretty(raw)}');

      final env = ApiEnvelope.fromJson(
        _unwrapMap(raw, envelope: ApiEnvelope()),
      );
      _d(
        '← ENV CheckOTPCode: flag=${env.flag} type=${env.responseType} '
        'message="${env.message}" modelId=${env.modelId} '
        'token?=${(env.token?.isNotEmpty ?? false)} '
        'rt?=${(env.refreshToken?.isNotEmpty ?? false)}',
      );

      final tokens = AuthTokens(
        token: env.token ?? '',
        refreshToken: env.refreshToken,
      );

      if (tokens.token.isEmpty) {
        _d('✗ OTP verified but no token in envelope');
        throw ApiException('OTP verified but no token returned', details: raw);
      }

      setToken(tokens.token);
      _d(
        '✔ setToken(access=${_mask(tokens.token)}, '
        'refresh=${_mask(tokens.refreshToken)})',
      );

      return tokens;
    } on ApiException catch (e) {
      _d(
        '✗ API ERR CheckOTPCode status=${e.statusCode} '
        'msg="${e.message}" data:\n${_pretty(e.message)}',
      );
      rethrow;
    } catch (e, st) {
      _d('✗ ERR CheckOTPCode $e\n$st');
      rethrow;
    }
  }

  static Future<AuthUser> register(RegisterRequest req) async {
    final raw = await _post('Authentication/register', body: req.toJson());
    return AuthUser.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<AuthTokens> login(LoginRequest req) async {
    final raw = await _post('Authentication/login', body: req.toJson());
    final tokens = AuthTokens.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
    _d(
      '← ENV Login: '
      'token?=${(tokens.token).isNotEmpty} '
      'rt?=${(tokens.refreshToken ?? '').isNotEmpty}',
    );
    if ((tokens.token).isEmpty) {
      throw ApiException(
        'Login succeeded but no token was returned.',
        details: raw,
      );
    }
    setToken(tokens.token);
    return tokens;
  }

  // Coerce any response payload into Map<String, dynamic>?
  static Map<String, dynamic>? _asDetails(dynamic src) {
    if (src == null) return null;

    if (src is Map<String, dynamic>) return src;
    if (src is Map) return Map<String, dynamic>.from(src);

    if (src is String) {
      try {
        final decoded = json.decode(src);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        // not a map? wrap as text
        return {'message': src};
      } catch (_) {
        // not JSON, keep raw text
        return {'message': src};
      }
    }

    // fallback for other types
    return {'message': src.toString()};
  }

  static Future<AuthTokens> refreshToken(RefreshTokenRequest req) async {
    final raw = await _post('Authentication/refresh-token', body: req.toJson());
    final tokens = AuthTokens.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
    _d(
      '← ENV RefreshToken: '
      'token?=${(tokens.token).isNotEmpty} '
      'rt?=${(tokens.refreshToken ?? '').isNotEmpty}',
    );
    if (tokens.token.isNotEmpty) setToken(tokens.token);
    return tokens;
  }

  static String _kUploadEndpoint = 'File/UploadStatic';

  // Returns the saved filename (basename only)
  static Future<String> uploadStaticBytes({
    required String folderName,
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('$_baseUrl$_kUploadEndpoint');

    final req = http.MultipartRequest('POST', uri)
      ..fields['folder'] = folderName
      ..files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: filename),
      );

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // FIX: message is positional
      throw ApiException(
        'Upload failed (${res.statusCode})',
        statusCode: res.statusCode,
        details: _asDetails(res.body),
      );
    }

    final decoded = json.decode(res.body);
    if (decoded is! Map) {
      throw ApiException(
        'Upload response is not a JSON object',
        statusCode: res.statusCode,
        details: _asDetails(res.body),
      );
    }
    final j = Map<String, dynamic>.from(decoded);
    final raw = (j['fileName'] ?? j['name'] ?? j['path'] ?? '').toString();
    final name = p.basename(raw);
    if (name.isEmpty) {
      // FIX: positional message
      throw ApiException(
        'Upload response missing filename',
        statusCode: res.statusCode,
        details: _asDetails(res.body),
      );
    }
    return name;
  }

  static Future<String> uploadStaticPath({
    required String folderName,
    required String path,
  }) async {
    final bytes = await File(path).readAsBytes();
    final filename = p.basename(path);
    return uploadStaticBytes(
      folderName: folderName,
      bytes: bytes,
      filename: filename,
    );
  }

  // -------- BRAND --------
  static Future<List<Brand>> getBrands() async {
    final raw = await _get('Brand/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Brand.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Brand> getBrandById(int id) async {
    final raw = await _get('Brand/$id');
    return Brand.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Brand> addBrand(Brand brand) async {
    final raw = await _post('Brand/add', body: _stripNullsDeep(brand.toJson()));
    return Brand.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Brand> updateBrand(Brand brand) async {
    final raw = await _put(
      'Brand/update',
      body: _stripNullsDeep(brand.toJson()),
    );
    return Brand.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteBrand(int id) async {
    await _delete('Brand/delete/$id');
    return true;
  }

  // -------- CITY --------
  static Future<List<City>> getCities() async {
    final raw = await _get('City/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => City.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<City> getCityById(int id) async {
    final raw = await _get('City/$id');
    return City.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<List<City>> searchCities(String query) async {
    final raw = await _post('City/AdvanceSearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => City.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<City> addCity(City city) async {
    final raw = await _post('City/add', body: _stripNullsDeep(city.toJson()));
    return City.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<City> updateCity(City city) async {
    final raw = await _put('City/update', body: _stripNullsDeep(city.toJson()));
    return City.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteCity(int id) async {
    await _delete('City/delete/$id');
    return true;
  }

  // -------- DOMAIN + DETAILS --------
  static Future<List<Domain>> getDomains() async {
    final raw = await _get('Domain/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Domain.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Domain> getDomainById(int id) async {
    final raw = await _get('Domain/$id');
    return Domain.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<List<Domain>> searchDomains(String query) async {
    final raw = await _post('Domain/Advancesearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Domain.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Domain> addDomain(Domain domain) async {
    final raw = await _post(
      'Domain/add',
      body: _stripNullsDeep(domain.toJson()),
    );
    return Domain.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Domain> updateDomain(Domain domain) async {
    final raw = await _put(
      'Domain/update',
      body: _stripNullsDeep(domain.toJson()),
    );
    return Domain.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteDomain(int id) async {
    await _delete('Domain/delete/$id');
    return true;
  }

  static Future<List<DomainDetail>> getAllDomainDetails() async {
    final raw = await _get('Domain/alldetails');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => DomainDetail.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<DomainDetail> getDomainDetailById(int domainDetailId) async {
    final raw = await _get('Domain/detail/$domainDetailId');
    return DomainDetail.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<List<DomainDetail>> getDomainDetailsByDomainId(
    int domainId,
  ) async {
    final raw = await _get('Domain/details/$domainId');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => DomainDetail.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<DomainDetail> addDomainDetail(
    DomainDetail detail, {
    Domain? domain,
  }) async {
    final body = _stripNullsDeep(detail.toJson()) as Map<String, dynamic>;
    if (domain != null) body['domain'] = _stripNullsDeep(domain.toJson());
    final raw = await _post('Domain/adddetail', body: body);
    return DomainDetail.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<DomainDetail> updateDomainDetail(
    DomainDetail detail, {
    Domain? domain,
  }) async {
    final body = _stripNullsDeep(detail.toJson()) as Map<String, dynamic>;
    if (domain != null) body['domain'] = _stripNullsDeep(domain.toJson());
    final raw = await _put('Domain/updatedetail', body: body);
    return DomainDetail.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteDomainDetail(int domainDetailId) async {
    await _delete('Domain/deletedetail/$domainDetailId');
    return true;
  }

  // -------- EMPLOYEE --------
  static Future<List<Employee>> getEmployees() async {
    final raw = await _get('Employee/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Employee>> searchEmployees(String query) async {
    final raw = await _post('Employee/AdvanceSearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Employee.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Employee> addEmployee(Employee emp) async {
    final raw = await _post(
      'Employee/add',
      body: _stripNullsDeep(emp.toJson()),
    );
    return Employee.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Employee> updateEmployee(Employee emp) async {
    final raw = await _put(
      'Employee/update',
      body: _stripNullsDeep(emp.toJson()),
    );
    return Employee.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEmployee(int id) async {
    await _delete('Employee/delete/$id');
    return true;
  }

  // ---------- CONTRACT (new domain) ----------
  static String _dateOnly(DateTime d) => d.toIso8601String().split('T').first;

  static List<Map<String, dynamic>> _buildContractSlices({
    required DateTime from,
    required DateTime to,
    required int vendorUserId,
    required int customerUserId,
  }) {
    // create one slice per day (0h default)
    final days = to.difference(from).inDays + 1;
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < days; i++) {
      final d = DateTime(
        from.year,
        from.month,
        from.day,
      ).add(Duration(days: i));
      out.add({
        "contractSliceSheetId": 0,
        "contractSliceId": 0,
        "sliceDate": _dateOnly(d),
        "dailyHours": 0,
        "actualHours": 0,
        "overHours": 0,
        "totalHours": 0,
        "customerUserId": customerUserId,
        "isCustomerAccept": true,
        "vendorUserId": vendorUserId,
        "isVendorAccept": true,
        "customerNote": "",
        "vendorNote": "",
        "contractSlice": "",

        // NOTE: We intentionally omit nested customerUser/vendorUser objects
        // to keep payload lean unless your API *requires* them.
      });
    }
    return out;
  }

  /// Create a Contract from a confirmed Request.
  /// Returns the created contract's envelope (so you can read modelId / message).
  static Future<Map<String, dynamic>> addContractFromRequest({
    required RequestModel request,
    required List<RequestDriverLocation> rdlsAssigned,
  }) async {
    final reqId = request.requestId ?? 0;
    final eqId = request.equipmentId ?? 0;
    if (reqId == 0 || eqId == 0) {
      dev.log(
        '[API][ERR] addContractFromRequest(): reqId=$reqId eqId=$eqId',
        name: 'API',
      );
      throw ApiException('Missing requestId/equipmentId for Contract/add');
    }

    // Dates
    final fromDate = _ymdFromMixed(request.fromDate);
    final toDate = _ymdFromMixed(request.toDate);

    // Choose a driverId for the contract (first assigned driver if any)
    final driverId =
        (rdlsAssigned.isNotEmpty && rdlsAssigned.first.equipmentDriverId > 0)
        ? rdlsAssigned.first.equipmentDriverId
        : (request.driverId ?? 0);

    // Resolve any org users to stamp vendorUserId/customerUserId on slices
    // (pick first active user for each org if available)
    int vendorUserId = 0;
    int customerUserId = 0;
    try {
      final users = await getOrganizationUsers();
      final vOrgId = request.vendorId ?? request.vendor?.organizationId ?? 0;
      final cOrgId =
          request.customerId ?? request.customer?.organizationId ?? 0;
      vendorUserId =
          users
              .firstWhere(
                (u) => (u.organizationId == vOrgId && (u.isActive ?? false)),
                orElse: () => OrganizationUser(),
              )
              .organizationUserId ??
          0;
      customerUserId =
          users
              .firstWhere(
                (u) => (u.organizationId == cOrgId && (u.isActive ?? false)),
                orElse: () => OrganizationUser(),
              )
              .organizationUserId ??
          0;
    } catch (_) {
      // leave zeros if not found
    }

    // Build slice sheets (per day)
    final from = DateTime.parse('${fromDate}T00:00:00.000Z');
    final to = DateTime.parse('${toDate}T00:00:00.000Z');
    final slices = _buildContractSlices(
      from: from,
      to: to,
      vendorUserId: vendorUserId,
      customerUserId: customerUserId,
    );

    // Expire at end of last day
    final expire = DateTime(to.year, to.month, to.day, 23, 59, 59);

    // Root flags (mirror the confirmed request)
    final isVendorAccept = request.isVendorAccept ?? true;
    final isCustomerAccept = request.isCustomerAccept ?? true;

    // Build payload (matches your sample keys exactly)
    final model = <String, dynamic>{
      "contractId": 0,
      "contractNo": 0,
      "contractDate": _dateOnly(DateTime.now()),
      "fromDate": fromDate,
      "toDate": toDate,
      "requestId": reqId,
      "equipmentId": eqId,
      "statusId": 0, // let backend set initial status if it has a domain
      "vendorId": request.vendorId ?? request.vendor?.organizationId ?? 0,
      "customerId": request.customerId ?? request.customer?.organizationId ?? 0,
      "isVendorAccept": isVendorAccept,
      "isCustomerAccept": isCustomerAccept,
      "isDownPayment": ((request.downPayment ?? 0) > 0),
      "isActive": true,
      "expireDateTime": expire.toIso8601String(),
      "createDateTime": DateTime.now().toIso8601String(),
      "modifyDateTime": DateTime.now().toIso8601String(),
      "driverId": driverId,
      "contractSliceSheets": slices,
    };

    // LOG the exact JSON sent
    dev.log(
      '[API] Contract/add — payload:\n${_prettyJson(model)}',
      name: 'API',
    );

    final raw = await _post('Contract/add', body: model);
    dev.log('[API] Contract/add — response:\n${_prettyJson(raw)}', name: 'API');

    // Return the raw map (envelope or direct)
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {"data": raw};
  }

  // ---------- CONTRACTS (browse) ----------
  static Future<List<ContractModel>> searchContracts(String query) async {
    final raw = await _post('Contract/AdvanceSearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => ContractModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<ContractModel> getContractById(int id) async {
    final raw = await _getJson('Contract/$id');
    final map = _unwrapMap(raw, envelope: ApiEnvelope());
    return ContractModel.fromJson(map);
  }

  // ---------- CONTRACT SLICES ----------
  static Future<List<ContractSlice>> getSlicesForContract(
    int contractId,
  ) async {
    final q = 'select * from ContractSlices where ContractId = $contractId';
    final raw = await _post('ContractSlice/AdvanceSearch', body: {'query': q});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => ContractSlice.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<ContractSlice> addContractSlice(ContractSlice m) async {
    final raw = await _post(
      'ContractSlice/add',
      body: _stripNullsDeep(m.toJson()),
    );
    final map = _unwrapMap(raw, envelope: ApiEnvelope());
    return ContractSlice.fromJson(map);
  }

  // ---------- CONTRACT SLICE SHEETS ----------
  static Future<List<ContractSliceSheet>> getSheetsForSlice(int sliceId) async {
    final q =
        'select * from ContractSliceSheets where ContractSliceId = $sliceId';
    final raw = await _post(
      'ContractSliceSheet/AdvanceSearch',
      body: {'query': q},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => ContractSliceSheet.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<ContractSliceSheet> addContractSliceSheet(
    ContractSliceSheet m,
  ) async {
    final raw = await _post(
      'ContractSliceSheet/add',
      body: _stripNullsDeep(m.toJson()),
    );
    final map = _unwrapMap(raw, envelope: ApiEnvelope());
    return ContractSliceSheet.fromJson(map);
  }

  static Future<ContractSliceSheet> updateContractSliceSheet(
    ContractSliceSheet m,
  ) async {
    final raw = await _put(
      'ContractSliceSheet/update',
      body: _stripNullsDeep(m.toJson()),
    );
    /*
    static Future<Equipment> updateEquipment(Equipment e) async {
    final raw = await _put(
      'Equipment/update',
      body: _stripNullsDeep(e.toJson()),
    );
    return Equipment.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }
    */
    return ContractSliceSheet.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  // -------- EQUIPMENT (incl. images, certs, driver files, terms, lists, locations, rates) --------
  static Future<List<Equipment>> getEquipments() async {
    final raw = await _get('Equipment/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Equipment>> getEquipmentsByVendorId({
    int? vendorId,
  }) async {
    final path = 'Equipment/EquipmentsByVendorId/$vendorId';
    final raw = await _get(path);
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Equipment>> searchEquipments(EquipmentSearch req) async {
    final raw = await _post(
      'Equipment/Search',
      body: _stripNullsDeep(req.toJson()),
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Equipment>> advanceSearchEquipments(String query) async {
    final raw = await _post('Equipment/AdvanceSearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Equipment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Equipment> getEquipmentById(int id) async {
    final raw = await _get('Equipment/$id');
    return Equipment.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Equipment> addEquipment(Equipment e) async {
    final raw = await _post('Equipment/add', body: _stripNullsDeep(e.toJson()));
    return Equipment.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  // in api_handler.dart
  static Future<Map<String, dynamic>> addEquipmentRaw(
    Map<String, dynamic> body,
  ) async {
    // IMPORTANT: don’t strip 0/false; only nulls.
    Map<String, dynamic> _stripNulls(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final child = _stripNulls(v);
          if (child.isNotEmpty) out[k] = child;
        } else if (v is List) {
          out[k] = v.where((e) => e != null).toList();
        } else {
          out[k] = v;
        }
      });
      return out;
    }

    final clean = _stripNulls(body);
    debugPrint('[Api.addEquipmentRaw] payload -> $clean');

    final raw = await _post('Equipment/add', body: clean); // keep endpoint
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  static Future<Equipment> updateEquipment(Equipment e) async {
    final raw = await _put(
      'Equipment/update',
      body: _stripNullsDeep(e.toJson()),
    );
    return Equipment.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipment(int id) async {
    await _delete('Equipment/delete/$id');
    return true;
  }

  // Certificates
  static Future<List<EquipmentCertificate>> getEquipmentCertificates() async {
    final raw = await _get('EquipmentCertificate/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentCertificate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentCertificate> getEquipmentCertificateById(
    int id,
  ) async {
    final raw = await _get('EquipmentCertificate/$id');
    return EquipmentCertificate.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<List<EquipmentCertificate>>
  getEquipmentCertificatesByEquipmentId(int equipmentId) async {
    final raw = await _get(
      'EquipmentCertificate/GetByEquipmentId?equipmentId=${Uri.encodeQueryComponent(equipmentId.toString())}',
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentCertificate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentCertificate>> advanceSearchEquipmentCertificates(
    String query,
  ) async {
    final raw = await _post(
      'EquipmentCertificate/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentCertificate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentCertificate> addEquipmentCertificate(
    EquipmentCertificate cert,
  ) async {
    final raw = await _post(
      'EquipmentCertificate/add',
      body: _stripNullsDeep(cert.toJson()),
    );
    return EquipmentCertificate.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<EquipmentCertificate> updateEquipmentCertificate(
    EquipmentCertificate cert,
  ) async {
    final raw = await _put(
      'EquipmentCertificate/update',
      body: _stripNullsDeep(cert.toJson()),
    );
    return EquipmentCertificate.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<bool> deleteEquipmentCertificate(int id) async {
    await _delete('EquipmentCertificate/delete/$id');
    return true;
  }

  //driver

  // --- RequestDriverLocation ---
  Future<void> addRequestDriverLocationExact(RequestDriverLocation m) async {
    await _postJsonRdl('RequestDriverLocation/add', m.toApiEmbedded());
  }

  static Future<void> deleteRequestDriverLocation(int id) async {
    await _delete('RequestDriverLocation/delete/$id');
  }

  // Returns RDLs via AdvanceSearch SQL
  static Future<List<RequestDriverLocation>> searchRequestDriverLocation(
    String query,
  ) async {
    // Post body: include both casings just in case
    final raw = await _post(
      'RequestDriverLocation/AdvanceSearch',
      body: {'query': query, 'Query': query},
    );

    // Prefer using the envelope to normalize shapes
    final env = ApiEnvelope.fromAny(raw);

    // If API signals failure, surface a friendly error
    if (env.flag == false) {
      throw ApiException(env.message ?? 'AdvanceSearch failed', statusCode: 0);
    }

    // Try to pull a list from envelope.data, otherwise fall back to your helper
    final dynamic payload = env.data ?? _unwrapList(raw);

    // Normalize to a List<Map<String, dynamic>>
    final List<Map<String, dynamic>> list;
    if (payload is List) {
      list = payload
          .whereType<Map>() // tolerate dynamic shapes
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } else if (payload is Map) {
      list = [Map<String, dynamic>.from(payload)];
    } else {
      list = const [];
    }

    // Map to models
    return list
        .map((m) => RequestDriverLocation.fromJson(m))
        .toList(growable: false);
  }

  static Future<dynamic> getRequestDriverLocationById(int id) async {
    return await _get('RequestDriverLocation/$id');
  }

  static Future<List<dynamic>> getRequestDriverLocations() async {
    final r = await _get('RequestDriverLocation/all');
    return (r as List?) ?? const [];
  }

  // ==== EquipmentDriver endpoints ====

  static Future<List<EquipmentDriver>> getEquipmentDrivers() async {
    final raw = await _get('EquipmentDriver/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentDriver.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentDriver>> getEquipmentDriversByEquipmentId(
    int id,
  ) async {
    final raw = await _get('EquipmentDriver/GetByEquipmentId?id=$id');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentDriver.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentDriver> getEquipmentDriverById(int id) async {
    final raw = await _get('EquipmentDriver/$id');
    return EquipmentDriver.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentDriver> addEquipmentDriver(EquipmentDriver d) async {
    final raw = await _post(
      'EquipmentDriver/add',
      body: _stripNullsDeep(d.toJson()),
    );
    return EquipmentDriver.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentDriver> updateEquipmentDriver(
    EquipmentDriver d,
  ) async {
    final raw = await _put(
      'EquipmentDriver/update',
      body: _stripNullsDeep(d.toJson()),
    );
    return EquipmentDriver.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipmentDriver(int id) async {
    await _delete('EquipmentDriver/delete/$id');
    return true;
  }

  // ==== Convenience for static uploads (folders confirmed) ====
  static const equipImagesFolder = 'equipimageFiles';
  static const driverDocsFolder = 'driverdocFiles';

  // Driver files
  static Future<List<EquipmentDriverFile>> getEquipmentDriverFiles() async {
    final raw = await _get('EquipmentDriverFile/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentDriverFile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentDriverFile>> advanceSearchEquipmentDriverFiles(
    String query,
  ) async {
    final raw = await _post(
      'EquipmentDriverFile/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentDriverFile.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentDriverFile> getEquipmentDriverFileById(int id) async {
    final raw = await _get('EquipmentDriverFile/$id');
    return EquipmentDriverFile.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<EquipmentDriverFile> addEquipmentDriverFile(
    EquipmentDriverFile file,
  ) async {
    final raw = await _post(
      'EquipmentDriverFile/add',
      body: _stripNullsDeep(file.toJson()),
    );
    return EquipmentDriverFile.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<EquipmentDriverFile> updateEquipmentDriverFile(
    EquipmentDriverFile file,
  ) async {
    final raw = await _put(
      'EquipmentDriverFile/update',
      body: _stripNullsDeep(file.toJson()),
    );
    return EquipmentDriverFile.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<bool> deleteEquipmentDriverFile(int id) async {
    await _delete('EquipmentDriverFile/delete/$id');
    return true;
  }

  // Images
  static Future<List<EquipmentImage>> getEquipmentImages() async {
    final raw = await _get('EquipmentImage/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentImage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentImage>> getEquipmentImagesByEquipmentId(
    int equipmentId,
  ) async {
    final raw = await _get(
      'EquipmentImage/GetByEquipmentId?id=${Uri.encodeQueryComponent(equipmentId.toString())}',
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentImage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentImage> getEquipmentImageById(int id) async {
    final raw = await _get('EquipmentImage/$id');
    return EquipmentImage.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentImage> addEquipmentImage(EquipmentImage image) async {
    final raw = await _post(
      'EquipmentImage/add',
      body: _stripNullsDeep(image.toJson()),
    );
    return EquipmentImage.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentImage> updateEquipmentImage(
    EquipmentImage image,
  ) async {
    final raw = await _put(
      'EquipmentImage/update',
      body: _stripNullsDeep(image.toJson()),
    );
    return EquipmentImage.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipmentImage(int id) async {
    await _delete('EquipmentImage/delete/$id');
    return true;
  }

  // Lists
  static Future<List<EquipmentListModel>> getEquipmentLists() async {
    final raw = await _get('EquipmentList/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentListModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentListModel> getEquipmentListById(int id) async {
    final raw = await _get('EquipmentList/$id');
    return EquipmentListModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<EquipmentListModel> addEquipmentList(
    EquipmentListModel m,
  ) async {
    final raw = await _post(
      'EquipmentList/add',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentListModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<EquipmentListModel> updateEquipmentList(
    EquipmentListModel m,
  ) async {
    final raw = await _put(
      'EquipmentList/update',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentListModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<bool> deleteEquipmentList(int id) async {
    await _delete('EquipmentList/delete/$id');
    return true;
  }

  // Locations
  static Future<List<EquipmentLocation>> getEquipmentLocations() async {
    final raw = await _get('EquipmentLocation/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentLocation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentLocation> getEquipmentLocationById(int id) async {
    final raw = await _get('EquipmentLocation/$id');
    return EquipmentLocation.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentLocation> addEquipmentLocation(
    EquipmentLocation m,
  ) async {
    final raw = await _post(
      'EquipmentLocation/add',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentLocation.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentLocation> updateEquipmentLocation(
    EquipmentLocation m,
  ) async {
    final raw = await _put(
      'EquipmentLocation/update',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentLocation.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipmentLocation(int id) async {
    await _delete('EquipmentLocation/delete/$id');
    return true;
  }

  // Rates
  static Future<List<EquipmentRate>> getEquipmentRates() async {
    final raw = await _get('EquipmentRate/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentRate.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentRate> getEquipmentRateById(int id) async {
    final raw = await _get('EquipmentRate/$id');
    return EquipmentRate.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentRate> addEquipmentRate(EquipmentRate m) async {
    final raw = await _post(
      'EquipmentRate/add',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentRate.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentRate> updateEquipmentRate(EquipmentRate m) async {
    final raw = await _put(
      'EquipmentRate/update',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentRate.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipmentRate(int id) async {
    await _delete('EquipmentRate/delete/$id');
    return true;
  }

  // Terms
  static Future<List<EquipmentTerm>> getEquipmentTerms() async {
    final raw = await _get('EquipmentTerm/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentTerm.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentTerm>> getEquipmentTermsByEquipmentId(
    int equipmentId,
  ) async {
    final raw = await _get(
      'EquipmentTerm/GetByEquipmentId?id=${Uri.encodeQueryComponent(equipmentId.toString())}',
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentTerm.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<EquipmentTerm>> advanceSearchEquipmentTerms(
    String query,
  ) async {
    final raw = await _post(
      'EquipmentTerm/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => EquipmentTerm.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<EquipmentTerm> getEquipmentTermById(int id) async {
    final raw = await _get('EquipmentTerm/$id');
    return EquipmentTerm.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentTerm> addEquipmentTerm(EquipmentTerm m) async {
    final raw = await _post(
      'EquipmentTerm/add',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentTerm.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<EquipmentTerm> updateEquipmentTerm(EquipmentTerm m) async {
    final raw = await _put(
      'EquipmentTerm/update',
      body: _stripNullsDeep(m.toJson()),
    );
    return EquipmentTerm.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteEquipmentTerm(int id) async {
    await _delete('EquipmentTerm/delete/$id');
    return true;
  }

  // -------- FACTORY --------
  static Future<List<FactoryModel>> getFactories() async {
    final raw = await _get('Factory/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => FactoryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<FactoryModel> getFactoryById(int id) async {
    final raw = await _get('Factory/$id');
    return FactoryModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<FactoryModel> addFactory(FactoryModel m) async {
    final raw = await _post('Factory/add', body: _stripNullsDeep(m.toJson()));
    return FactoryModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<FactoryModel> updateFactory(FactoryModel m) async {
    final raw = await _put('Factory/update', body: _stripNullsDeep(m.toJson()));
    return FactoryModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteFactory(int id) async {
    await _delete('Factory/delete/$id');
    return true;
  }

  // -------- MANAGE FILES --------
  static Future<ManageFileResponse> uploadFile(ManageFileRequest req) async {
    final raw = await _post(
      'ManageFiles/UploadFile',
      body: _stripNullsDeep(req.toJson()),
    );
    return ManageFileResponse.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<ManageFileResponse> manageFile(ManageFileRequest req) async {
    final raw = await _post(
      'ManageFiles/ManageFile',
      body: _stripNullsDeep(req.toJson()),
    );
    return ManageFileResponse.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<ManageFileResponse> saveUploadFile(
    ManageFileRequest req,
  ) async {
    final raw = await _post(
      'ManageFiles/SaveUploadFile',
      body: _stripNullsDeep(req.toJson()),
    );
    return ManageFileResponse.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<ManageFileResponse> uploadFileAll(ManageFileRequest req) async {
    final raw = await _post(
      'ManageFiles/UploadFileAll',
      body: _stripNullsDeep(req.toJson()),
    );
    return ManageFileResponse.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  // -------- NATIONALITY --------
  static Future<List<Nationality>> getNationalities() async {
    final raw = await _get('Nationality/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => Nationality.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<Nationality> getNationalityById(int id) async {
    final raw = await _get('Nationality/$id');
    return Nationality.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Nationality> addNationality(Nationality n) async {
    final raw = await _post(
      'Nationality/add',
      body: _stripNullsDeep(n.toJson()),
    );
    return Nationality.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<Nationality> updateNationality(Nationality n) async {
    final raw = await _put(
      'Nationality/update',
      body: _stripNullsDeep(n.toJson()),
    );
    return Nationality.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteNationality(int id) async {
    await _delete('Nationality/delete/$id');
    return true;
  }

  // ========= ORGANIZATION (summary-level) =========
  static Future<ApiEnvelope> addOrganizationEnvelope(
    Map<String, dynamic> body,
  ) async {
    final raw = await _post('Organization/add', body: _stripNullsDeep(body));
    debugPrint('[Api.addOrganizationEnvelope] raw -> $raw');
    return ApiEnvelope.fromAny(raw);
  }

  static Future<ApiEnvelope> updateOrganizationEnvelope(
    Map<String, dynamic> body,
  ) async {
    final raw = await _put('Organization/update', body: _stripNullsDeep(body));
    debugPrint('[Api.updateOrganizationEnvelope] raw -> $raw');
    return ApiEnvelope.fromAny(raw);
  }

  static Future<OrganizationSummary> getOrganizationById(int id) async {
    final raw = await _get('Organization/$id');
    debugPrint('[Api.getOrganizationById/$id] raw -> $raw');
    if (raw is Map) {
      return OrganizationSummary.fromJson(Map<String, dynamic>.from(raw));
    }
    if (raw is List && raw.isNotEmpty && raw.first is Map) {
      return OrganizationSummary.fromJson(Map<String, dynamic>.from(raw.first));
    }
    // last resort: treat as envelope root
    return OrganizationSummary.fromJson({'data': raw});
  }

  static Future<OrganizationSummary> addOrganization(
    Map<String, dynamic> body,
  ) async {
    final raw = await _post('Organization/add', body: _stripNullsDeep(body));
    debugPrint('[Api.addOrganization] raw -> $raw');

    if (raw is Map && (raw['modelId'] != null || raw['id'] != null)) {
      final id = int.tryParse('${raw['modelId'] ?? raw['id']}');
      if (id != null && id > 0) {
        // fetch the created entity so we get populated fields
        return await getOrganizationById(id);
      }
    }

    // some backends do return the entity directly
    return OrganizationSummary.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<OrganizationSummary> updateOrganization(
    Map<String, dynamic> body,
  ) async {
    final raw = await _put('Organization/update', body: _stripNullsDeep(body));
    debugPrint('[Api.updateOrganization] raw -> $raw');

    // handle envelope
    if (raw is Map && (raw['modelId'] != null || raw['id'] != null)) {
      final id =
          int.tryParse('${raw['modelId'] ?? raw['id']}') ??
          int.tryParse('${body['organizationId'] ?? ''}');
      if (id != null && id > 0) {
        return await getOrganizationById(id);
      }
    }

    return OrganizationSummary.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  // -------- ORG FILE --------
  static Future<List<OrganizationFileModel>> getOrganizationFiles() async {
    final raw = await _get('OrganizationFile/all');
    final list = _unwrapList(raw);
    return list
        .whereType<Map>()
        .map(
          (e) => OrganizationFileModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  static Future<List<OrganizationFileModel>> advanceSearchOrganizationFiles(
    String query,
  ) async {
    final raw = await _post(
      'OrganizationFile/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map(
          (e) => OrganizationFileModel.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  static Future<OrganizationFileModel> getOrganizationFileById(int id) async {
    final raw = await _get('OrganizationFile/$id');
    return OrganizationFileModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<OrganizationFileModel> addOrganizationFile(
    OrganizationFileModel f,
  ) async {
    final raw = await _post(
      'OrganizationFile/add',
      body: _stripNullsDeep(f.toJson()),
    );
    return OrganizationFileModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<OrganizationFileModel> updateOrganizationFile(
    OrganizationFileModel f,
  ) async {
    final raw = await _put(
      'OrganizationFile/update',
      body: _stripNullsDeep(f.toJson()),
    );
    return OrganizationFileModel.fromJson(
      _unwrapMap(raw, envelope: ApiEnvelope()),
    );
  }

  static Future<bool> deleteOrganizationFile(int id) async {
    await _delete('OrganizationFile/delete/$id');
    return true;
  }

  // -------- ORG USER --------
  static Future<List<OrganizationUser>> getOrganizationUsers() async {
    final raw = await _get('OrganizationUser/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => OrganizationUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<OrganizationUser>> advanceSearchOrganizationUsers(
    String query,
  ) async {
    final raw = await _post(
      'OrganizationUser/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => OrganizationUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<OrganizationUser> getOrganizationUserById(int id) async {
    final raw = await _get('OrganizationUser/$id');
    return OrganizationUser.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<OrganizationUser> addOrganizationUser(
    OrganizationUser u,
  ) async {
    final raw = await _post(
      'OrganizationUser/add',
      body: _stripNullsDeep(u.toJson()),
    );
    return OrganizationUser.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<OrganizationUser> updateOrganizationUser(
    OrganizationUser u,
  ) async {
    final raw = await _put(
      'OrganizationUser/update',
      body: _stripNullsDeep(u.toJson()),
    );
    return OrganizationUser.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteOrganizationUser(int id) async {
    await _delete('OrganizationUser/delete/$id');
    return true;
  }

  // -------- REQUEST / FILE / TERM --------
  static Future<List<RequestModel>> getRequests() async {
    final raw = await _get(
      'Request/all',
    ); // Note: trailing slash per your backend
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<RequestModel>> advanceSearchRequests(String query) async {
    final raw = await _post('Request/AdvanceSearch', body: {'query': query});
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<RequestModel> getRequestById(int id) async {
    final raw = await _get('Request/$id');
    return RequestModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<AddRequestResult> addRequest(RequestDraft draft) async {
    // Log outgoing body
    _logBig('[API] Request/add → body', draft.toApi());

    // POST
    final raw = await _postJsonRdl('Request/add', draft.toApi());

    // Log raw response (whatever it is: map/string/list)
    _logBig('[API] Request/add ← raw', raw);

    // Parse envelope
    final env = ApiEnvelope.fromAny(raw);

    // Log normalized envelope too (so you can see flag/message/modelId/data)
    _logBig('[API] Request/add ← envelope', env.toJson());

    // ... your existing logic below ...
    Map<String, dynamic>? _asModelMap(dynamic any) {
      if (any == null) return null;
      if (any is Map<String, dynamic>) return any;
      if (any is Map) return Map<String, dynamic>.from(any);
      return null;
    }

    final directMap = _asModelMap(env.data);
    if (directMap != null) {
      return AddRequestResult(
        success: (env.flag ?? true),
        message: env.message ?? 'Success',
        model: RequestModel.fromJson(directMap),
      );
    }

    final id = env.modelId ?? 0;
    if (id > 0) {
      try {
        final got = await _getJson('Request/$id');
        _logBig('[API] Request/$id ← raw', got);

        final gotDirect = _asModelMap(got);
        if (gotDirect != null) {
          return AddRequestResult(
            success: (env.flag ?? true),
            message: env.message ?? 'Success',
            model: RequestModel.fromJson(gotDirect),
          );
        }
        final gotEnv = ApiEnvelope.fromAny(got);
        _logBig('[API] Request/$id ← envelope', gotEnv.toJson());

        final gotData = _asModelMap(gotEnv.data);
        if (gotData != null) {
          return AddRequestResult(
            success: (env.flag ?? true),
            message: env.message ?? 'Success',
            model: RequestModel.fromJson(gotData),
          );
        }
      } catch (e) {
        dev.log('GET Request/$id failed after POST: $e', name: '[API]');
      }
    }

    final ok = (env.flag ?? true);
    if (!ok)
      throw ApiException(env.message ?? 'Request/add failed', statusCode: 0);

    return AddRequestResult(
      success: true,
      message: (env.message?.isNotEmpty ?? false) ? env.message! : 'Success',
      model: null,
    );
  }

  static Future<RequestModel> addRequestFromModel(RequestModel m) async {
    final raw = await _post('Request/add', body: _stripNullsDeep(m.toJson()));
    return RequestModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<RequestModel> updateRequest(RequestModel m) async {
    final raw = await _put('Request/update', body: _stripNullsDeep(m.toJson()));
    return RequestModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteRequest(int id) async {
    await _delete('Request/delete/$id');
    return true;
  }

  static Future<List<RequestFileModel>> getRequestFiles() async {
    final raw = await _get('RequestFile/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestFileModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<RequestFileModel>> advanceSearchRequestFiles(
    String query,
  ) async {
    final raw = await _post(
      'RequestFile/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestFileModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<RequestFileModel> getRequestFileById(int id) async {
    final raw = await _get('RequestFile/$id');
    return RequestFileModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<RequestFileModel> addRequestFile(RequestFileModel f) async {
    final raw = await _post(
      'RequestFile/add',
      body: _stripNullsDeep(f.toJson()),
    );
    return RequestFileModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<RequestFileModel> updateRequestFile(RequestFileModel f) async {
    final raw = await _put(
      'RequestFile/update',
      body: _stripNullsDeep(f.toJson()),
    );
    return RequestFileModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteRequestFile(int id) async {
    await _delete('RequestFile/delete/$id');
    return true;
  }

  static Future<List<RequestTermModel>> getRequestTerms() async {
    final raw = await _get('RequestTerm/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestTermModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<RequestTermModel>> advanceSearchRequestTerms(
    String query,
  ) async {
    final raw = await _post(
      'RequestTerm/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => RequestTermModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<RequestTermModel> getRequestTermById(int id) async {
    final raw = await _get('RequestTerm/$id');
    return RequestTermModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<RequestTermModel> addRequestTerm(RequestTermModel t) async {
    final raw = await _post(
      'RequestTerm/add',
      body: _stripNullsDeep(t.toJson()),
    );
    return RequestTermModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<RequestTermModel> updateRequestTerm(RequestTermModel t) async {
    final raw = await _put(
      'RequestTerm/update',
      body: _stripNullsDeep(t.toJson()),
    );
    return RequestTermModel.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteRequestTerm(int id) async {
    await _delete('RequestTerm/delete/$id');
    return true;
  }

  // ---------- HELPERS ----------

  // Pretty JSON for logs

  static String _prettyJson(Object? v) {
    try {
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return '$v';
    }
  }

  /// dev.log can drop very long lines in some consoles; chunk it.
  static void _logBig(String name, Object? v) {
    final s = _prettyJson(v);
    const max = 1000;
    for (int i = 0; i < s.length; i += max) {
      final part = s.substring(i, (i + max > s.length) ? s.length : i + max);
      dev.log(part, name: name);
    }
  }

  static String _ymdFromMixed(String? ymdStr, {DateTime? fallback}) {
    // Accept "yyyy-MM-dd" or full ISO or null
    // Return "yyyy-MM-dd"
    if (ymdStr != null && ymdStr.isNotEmpty) {
      try {
        final d = DateTime.parse(ymdStr);
        return d.toIso8601String().split('T').first;
      } catch (_) {
        // If already y-m-d-ish, trust it
        if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(ymdStr)) return ymdStr;
      }
    }
    final d = fallback ?? DateTime.now();
    return d.toIso8601String().split('T').first;
  }

  // ---------- UPDATE: vendor/customer confirm via Request/update only ----------

  static Future<List<RequestDriverLocation>>
  advanceSearchRequestDriverLocations(String sql) async {
    final raw = await _postJsonRdl('RequestDriverLocation/AdvanceSearch', {
      "query": sql,
    });
    if (raw is List) {
      return raw
          .map(
            (e) => RequestDriverLocation.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
    }
    return const <RequestDriverLocation>[];
  }

  static Future<bool> updateRequestWithRDLs({
    required RequestModel request,
    required List<RequestDriverLocation>
    rdlsAssigned, // each with equipmentDriverId set
  }) async {
    // 0) Basic safety
    final reqId = request.requestId ?? 0;
    final eqId = request.equipmentId ?? 0;
    if (reqId == 0) {
      dev.log(
        '[API][ERR] updateRequestWithRDLs(): requestId is 0',
        name: 'API',
      );
      return false;
    }
    if (eqId == 0) {
      dev.log(
        '[API][ERR] updateRequestWithRDLs(): equipmentId is 0',
        name: 'API',
      );
      return false;
    }

    // 1) Make sure we have equipment to fill mandatory responsibility IDs
    Equipment? eq = request.equipment;
    if (eq == null) {
      try {
        eq = await getEquipmentById(eqId);
      } catch (_) {}
    }

    final fuelRespId = eq?.fuelResponsibilityId ?? 0;
    final foodRespId = eq?.driverFoodResponsibilityId ?? 0;
    final houseRespId = eq?.driverHousingResponsibilityId ?? 0;
    final transRespId = eq?.driverTransResponsibilityId ?? 0;

    // Root driverNationalityId should not be null: take first RDL’s nationality (fallback request)
    final rootNatId = (rdlsAssigned.isNotEmpty)
        ? rdlsAssigned.first.driverNationalityId
        : (request.driverNationalityId ?? 0);

    // 2) Status + accepts: replicate your .NET mapping for vendor confirm path.
    // If you also need a "customer path", pass different logic from screen.
    int nextStatus = request.statusId ?? 0;
    // Vendor path:
    // 34 -> 35 ; 36 -> 37 ; 35 -> 37 ; keep 37 if already 37
    if (nextStatus == 34) {
      nextStatus = 35;
    } else if (nextStatus == 36) {
      nextStatus = 37;
    } else if (nextStatus == 35) {
      nextStatus = 37;
    }
    bool isVendorAccept = true;
    bool isCustomerAccept = request.isCustomerAccept ?? false;
    if (nextStatus == 37) {
      isVendorAccept = true;
      isCustomerAccept = true;
    }

    // 3) Calculate dates in the exact format
    final requestDate = _ymdFromMixed(
      request.createDateTime.toString(),
      fallback: DateTime.now(),
    );
    final fromDate = _ymdFromMixed(request.fromDate);
    final toDate = _ymdFromMixed(request.toDate);

    // 4) Build the outgoing RDLs array (ensuring requestId/equipmentId are set)
    final rdlsJson = rdlsAssigned.map((u) {
      return {
        "requestDriverLocationId": u.requestDriverLocationId,
        "requestId": reqId, // force
        "equipmentId": eqId, // force
        "equipmentNumber": u.equipmentNumber,
        "driverNationalityId": u.driverNationalityId,
        "equipmentDriverId": u.equipmentDriverId, // chosen in UI
        "otherNotes": u.otherNotes,
        "pickupAddress": u.pickupAddress,
        "pLongitude": u.pLongitude,
        "pLatitude": u.pLatitude,
        "dropoffAddress": u.dropoffAddress,
        "dLongitude": u.dLongitude,
        "dLatitude": u.dLatitude,
      };
    }).toList();

    // 5) Full model per your schema (all fields present)
    final model = <String, dynamic>{
      "requestId": reqId,
      "requestNo": request.requestNo ?? 0,
      "requestDate": requestDate,
      "vendorId": request.vendorId ?? request.vendor?.organizationId ?? 0,
      "customerId": request.customerId ?? request.customer?.organizationId ?? 0,
      "isVendorAccept": isVendorAccept,
      "isCustomerAccept": isCustomerAccept,
      "vendorNotes": "", // fill if you capture notes
      "customerNotes": "", // fill if you capture notes
      "equipmentId": eqId,
      "requestedQuantity": request.requestedQuantity ?? rdlsAssigned.length,
      "requiredDays": request.numberDays ?? 0,
      "fromDate": fromDate,
      "toDate": toDate,
      "statusId": nextStatus,
      "fuelResponsibilityId": fuelRespId, // MUST NOT be null
      "rentPricePerDay": request.rentPricePerDay ?? 0,
      "rentPricePerHour": request.rentPricePerHour ?? 0,
      "isDistancePrice": request.isDistancePrice ?? false,
      "rentPricePerDistance": request.rentPricePerDistance ?? 0,
      "createDateTime": (request.createDateTime ?? DateTime.now())
          .toIso8601String(),
      "modifyDateTime": DateTime.now().toIso8601String(),
      "downPayment": request.downPayment ?? 0,
      "driverNationalityId": rootNatId, // MUST NOT be null
      "driverFoodResponsibilityId": foodRespId, // MUST NOT be null
      "driverHousingResponsibilityId": houseRespId, // MUST NOT be null
      "driverTransResponsibilityId": transRespId, // MUST NOT be null
      "equipmentWeight": request.equipmentWeight ?? 0,
      "driverId": request.driverId ?? 0,
      "totalPrice": request.totalPrice ?? 0,
      "vatPrice": request.vatPrice ?? 0,
      "afterVatPrice": request.afterVatPrice ?? 0,
      "requestDriverLocations": rdlsJson,
    };

    final payload = {model};

    // 6) Log EXACTLY what we’re about to send
    dev.log(
      '[API] Request/update (FULL nested payload)\n'
      'reqId=$reqId, eqId=$eqId, status->${model["statusId"]}\n'
      '${_prettyJson(payload)}',
      name: 'API',
    );

    // 7) Send
    final res = await _put('Request/update', body: model);
    dev.log('[API] Response Request/update: ${_prettyJson(res)}', name: 'API');

    return (res is Map) && (res['flag'] == true);
  }

  // -------- TERM CONDITION (catalog) --------
  static Future<List<TermCondition>> getTermConditions() async {
    final raw = await _get('TermCondition/all');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => TermCondition.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<TermCondition> getTermConditionById(int id) async {
    final raw = await _get('TermCondition/$id');
    return TermCondition.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<TermCondition> addTermCondition(TermCondition t) async {
    final raw = await _post(
      'TermCondition/add',
      body: _stripNullsDeep(t.toJson()),
    );
    return TermCondition.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<TermCondition> updateTermCondition(TermCondition t) async {
    final raw = await _put(
      'TermCondition/update',
      body: _stripNullsDeep(t.toJson()),
    );
    return TermCondition.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<bool> deleteTermCondition(int id) async {
    await _delete('TermCondition/delete/$id');
    return true;
  }

  // -------- USER ACCOUNT --------
  static Future<UserAccount> getUserAccountById(int userId) async {
    final raw = await _get('UserAccount/GetUser/$userId');
    return UserAccount.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }

  static Future<List<UserAccount>> getUserAccounts() async {
    final raw = await _get('UserAccount/GetUsers');
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<UserAccount>> advanceSearchUserAccounts(
    String query,
  ) async {
    final raw = await _post(
      'UserAccount/AdvanceSearch',
      body: {'query': query},
    );
    return _unwrapList(raw)
        .whereType<Map>()
        .map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Backend single “SaveUser” endpoint (create/update).
  /// By default we DO NOT send `password` unless you pass it in the model.
  static Future<UserAccount> saveUserAccount(
    UserAccount user, {
    bool includePassword = false,
  }) async {
    final body = _stripNullsDeep(user.toJson()) as Map<String, dynamic>;
    if (!includePassword) body.remove('password');
    final raw = await _post('UserAccount/SaveUser', body: body);
    return UserAccount.fromJson(_unwrapMap(raw, envelope: ApiEnvelope()));
  }
  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------

  static Future getThreadMessages(int threadId) async {}

  static Future<void> sendThreadMessage(int threadId, String text) async {}

  static Future getChatThreads() async {}

  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------
  //--------------------------------------------------------------------------------------------------------------------------
}

// core/api/api_handler.dart
class AddRequestResult {
  final bool success;
  final String message;
  final RequestModel? model;
  AddRequestResult({required this.success, required this.message, this.model});
}
