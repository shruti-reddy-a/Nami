class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl; // Could be a Firebase Storage URL
  final String? emoji; // Used if photoUrl is null
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.emoji,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'emoji': emoji,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['display_name'] ?? '',
      photoUrl: map['photo_url'],
      emoji: map['emoji'],
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at']).toLocal() 
          : DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? emoji,
    bool clearPhoto = false,
  }) {
    return UserProfile(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: clearPhoto ? null : (photoUrl ?? this.photoUrl),
      emoji: emoji ?? this.emoji,
      createdAt: createdAt,
    );
  }
}
