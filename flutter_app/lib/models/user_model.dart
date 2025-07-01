import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String? facePhotoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> profileImages;
  final bool hasVerifiedFace;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.facePhotoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.profileImages = const [],
    this.hasVerifiedFace = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      facePhotoUrl: data['face_photo_url'],
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
      profileImages: List<String>.from(data['profile_images'] ?? []),
      hasVerifiedFace: data['has_verified_face'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'username': username,
      'face_photo_url': facePhotoUrl,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
      'profile_images': profileImages,
      'has_verified_face': hasVerifiedFace,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? facePhotoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? profileImages,
    bool? hasVerifiedFace,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      facePhotoUrl: facePhotoUrl ?? this.facePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      profileImages: profileImages ?? this.profileImages,
      hasVerifiedFace: hasVerifiedFace ?? this.hasVerifiedFace,
    );
  }
}