import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

class PostService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<PostModel> _posts = [];
  List<PostModel> get posts => _posts;

  List<PostModel> _userPosts = [];
  List<PostModel> get userPosts => _userPosts;

  // Upload image to Firebase Storage
  Future<String> _uploadImage(File imageFile, String fileName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      final ref = _storage.ref().child('posts/$userId/$fileName');
      
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      
      String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create a new post
  Future<void> createPost(File imageFile) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Generate unique filename
      final uuid = Uuid();
      final fileName = '${uuid.v4()}.jpg';

      // Upload image
      final imageUrl = await _uploadImage(imageFile, fileName);

      // Create post document
      final now = DateTime.now();
      final postData = {
        'user_id': userId,
        'image_url': imageUrl,
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      };

      await _firestore.collection('posts').add(postData);

      // Refresh posts
      await loadPosts();
      await loadUserPosts();
    } catch (e) {
      throw Exception('Failed to create post: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load public feed (all posts)
  Future<void> loadPosts({int limit = 20}) async {
    try {
      Query query = _firestore
          .collection('posts')
          .orderBy('created_at', descending: true)
          .limit(limit);

      QuerySnapshot snapshot = await query.get();
      
      _posts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading posts: $e');
    }
  }

  // Load current user's posts
  Future<void> loadUserPosts() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      Query query = _firestore
          .collection('posts')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true);

      QuerySnapshot snapshot = await query.get();
      
      _userPosts = snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user posts: $e');
    }
  }

  // Load posts for a specific user
  Future<List<PostModel>> loadPostsForUser(String userId) async {
    try {
      Query query = _firestore
          .collection('posts')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true);

      QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => PostModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error loading posts for user: $e');
      return [];
    }
  }

  // Delete a post
  Future<void> deletePost(String postId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // Get the post to check ownership
      DocumentSnapshot postDoc = await _firestore.collection('posts').doc(postId).get();
      if (!postDoc.exists) throw Exception('Post not found');

      Map<String, dynamic> postData = postDoc.data() as Map<String, dynamic>;
      if (postData['user_id'] != userId) {
        throw Exception('You can only delete your own posts');
      }

      // Delete the image from storage
      String imageUrl = postData['image_url'];
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        debugPrint('Error deleting image from storage: $e');
      }

      // Delete the post document
      await _firestore.collection('posts').doc(postId).delete();

      // Refresh posts
      await loadPosts();
      await loadUserPosts();
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Stream posts for real-time updates
  Stream<List<PostModel>> streamPosts({int limit = 20}) {
    return _firestore
        .collection('posts')
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }

  // Stream user posts for real-time updates
  Stream<List<PostModel>> streamUserPosts() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('posts')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }
}