import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/post_service.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';

class FeedScreen extends StatefulWidget {
  @override
  _FeedScreenState createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  @override
  void initState() {
    super.initState();
    // Load posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PostService>().loadPosts();
    });
  }

  Future<void> _onRefresh() async {
    await context.read<PostService>().loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Consumer<PostService>(
          builder: (context, postService, child) {
            if (postService.isLoading && postService.posts.isEmpty) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (postService.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No posts yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Be the first to share a moment!',
                      style: TextStyle(
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: postService.posts.length,
              itemBuilder: (context, index) {
                final post = postService.posts[index];
                return PostCard(post: post);
              },
            );
          },
        ),
      ),
    );
  }
}