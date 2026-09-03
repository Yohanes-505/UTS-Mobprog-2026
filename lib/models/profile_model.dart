enum Gender { male, female }

class ProfileModel {
  final String id;
  final String name;
  final int? age;
  final String? bio;
  final Gender? gender;
  final String? photoUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.age,
    this.bio,
    this.gender,
    this.photoUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
  });

  /// Build a ProfileModel from a Supabase row (Map).
  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      age: map['age'] as int?,
      bio: map['bio'] as String?,
      gender: _genderFromString(map['gender'] as String?),
      photoUrl: map['photo_url'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String)
          : null,
    );
  }

  /// Convert this ProfileModel into a Map for Supabase insert/update.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'bio': bio,
      'gender': gender?.name,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  ProfileModel copyWith({
    String? name,
    int? age,
    String? bio,
    Gender? gender,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) {
    return ProfileModel(
      id: id,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      photoUrl: photoUrl ?? this.photoUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }

  static Gender? _genderFromString(String? value) {
    if (value == null) return null;
    return Gender.values.firstWhere(
      (g) => g.name == value,
      orElse: () => Gender.male,
    );
  }
}