class UserProfile {
  final String? uid;
  final String? username;
  final String? email;
  final String? goalType;
  final String? match;
  final List<String>? friends;
  final String? pfpURL;

  UserProfile({
    this.uid,
    this.username,
    this.email,
    this.goalType,
    this.match,
    this.friends,
    this.pfpURL,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String?,
      username: map['username'] as String?,
      email: map['email'] as String?,
      goalType: map['goalType'] as String?,
      match: map['match'] as String?,
      friends: List<String>.from(map['friends'] ?? []),
      pfpURL: map['pfpURL'] as String?,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'],
      username: json['username'],
      email: json['email'],
      goalType: json['goalType'],
      match: json['match'],
      friends: (json['friends'] as List<dynamic>?)?.cast<String>() ?? [],
      pfpURL: json['pfpURL'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'goalType': goalType,
      'match': match,
      'friends': friends,
      'pfpURL': pfpURL,
    };
  }
}