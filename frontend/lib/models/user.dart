// User Model
class User {
  final String id;
  final String email;
  final String? name;
  final String plan;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    this.name,
    required this.plan,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      plan: json['plan'] ?? 'free',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'plan': plan,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Authentication Token Response
class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String userId;
  final String email;
  final String? name;
  final int accessExpiresIn;
  final int refreshExpiresIn;

  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.userId,
    required this.email,
    this.name,
    required this.accessExpiresIn,
    required this.refreshExpiresIn,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'bearer',
      userId: json['user_id'],
      email: json['email'],
      name: json['name'],
      accessExpiresIn: json['access_expires_in'] ?? (24 * 3600),
      refreshExpiresIn: json['refresh_expires_in'] ?? (30 * 24 * 3600),
    );
  }
}

// File History Item
class FileHistoryItem {
  final String id;
  final String toolId;
  final String toolName;
  final String status;
  final String outputName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isExpired;

  FileHistoryItem({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.status,
    required this.outputName,
    this.fileSize,
    required this.createdAt,
    required this.expiresAt,
    required this.isExpired,
  });

  factory FileHistoryItem.fromJson(Map<String, dynamic> json) {
    return FileHistoryItem(
      id: json['id'],
      toolId: json['tool_id'],
      toolName: json['tool_name'],
      status: json['status'],
      outputName: json['output_name'],
      fileSize: json['file_size'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      isExpired: json['is_expired'] ?? false,
    );
  }

  // Time remaining until expiry
  Duration get timeRemaining {
    return expiresAt.difference(DateTime.now());
  }

  // Format time remaining
  String get timeRemainingFormatted {
    final duration = timeRemaining;
    if (duration.isNegative) return 'Expired';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours${hours == 1 ? ' hour' : ' hours'} ${minutes}min left';
    }
    return '${minutes}min left';
  }
}
