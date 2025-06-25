import React, { useState, useEffect } from 'react';
import { Post, getCurrentUserPosts, getPublicFeed } from '../../services/postService';
import { useAuth } from '../../contexts/AuthContext';

interface PostListProps {
  showUserPosts?: boolean;
}

const PostList: React.FC<PostListProps> = ({ showUserPosts = false }) => {
  const [posts, setPosts] = useState<Post[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const { currentUser } = useAuth();

  useEffect(() => {
    loadPosts();
  }, [showUserPosts, currentUser]);

  const loadPosts = async () => {
    setLoading(true);
    setError('');

    try {
      let fetchedPosts: Post[];
      
      if (showUserPosts && currentUser) {
        fetchedPosts = await getCurrentUserPosts();
      } else {
        fetchedPosts = await getPublicFeed();
      }
      
      setPosts(fetchedPosts);
    } catch (error: any) {
      setError(`Error loading posts: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center py-8">
        <div className="text-gray-600">Loading posts...</div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
        {error}
      </div>
    );
  }

  if (posts.length === 0) {
    return (
      <div className="text-center py-8 text-gray-600">
        {showUserPosts ? 'You haven\'t created any posts yet.' : 'No posts available.'}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h2 className="text-xl font-bold">
        {showUserPosts ? 'Your Posts' : 'Recent Posts'}
      </h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {posts.map((post) => (
          <div key={post.id} className="bg-white rounded-lg shadow-md overflow-hidden">
            <img
              src={post.imageUrl}
              alt="Post"
              className="w-full h-64 object-cover"
              onError={(e) => {
                const target = e.target as HTMLImageElement;
                target.src = 'https://via.placeholder.com/300x200?text=Image+Not+Found';
              }}
            />
            <div className="p-4">
              <p className="text-sm text-gray-500">
                {post.createdAt?.toDate?.()?.toLocaleDateString() || 'Unknown date'}
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PostList;