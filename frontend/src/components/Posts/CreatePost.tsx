import React, { useState } from 'react';
import { createPost } from '../../services/postService';
import { useAuth } from '../../contexts/AuthContext';

const CreatePost: React.FC = () => {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');
  const { currentUser } = useAuth();

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        setMessage('Please select an image file');
        return;
      }
      
      // Validate file size (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        setMessage('File size must be less than 5MB');
        return;
      }
      
      setSelectedFile(file);
      setMessage('');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!selectedFile) {
      setMessage('Please select an image');
      return;
    }

    if (!currentUser) {
      setMessage('You must be logged in to create a post');
      return;
    }

    setLoading(true);
    setMessage('');

    try {
      await createPost(selectedFile);
      setMessage('Post created successfully!');
      setSelectedFile(null);
      // Reset file input
      const fileInput = document.getElementById('imageFile') as HTMLInputElement;
      if (fileInput) fileInput.value = '';
    } catch (error: any) {
      setMessage(`Error creating post: ${error.message}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="max-w-md mx-auto bg-white p-6 rounded-lg shadow-md">
      <h2 className="text-xl font-bold mb-4">Create New Post</h2>
      
      {message && (
        <div className={`px-4 py-3 rounded mb-4 ${
          message.includes('Error') ? 'bg-red-100 border border-red-400 text-red-700' : 'bg-green-100 border border-green-400 text-green-700'
        }`}>
          {message}
        </div>
      )}

      <form onSubmit={handleSubmit}>
        <div className="mb-4">
          <label htmlFor="imageFile" className="block text-sm font-medium text-gray-700 mb-2">
            Select Image
          </label>
          <input
            type="file"
            id="imageFile"
            accept="image/*"
            onChange={handleFileSelect}
            className="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
        </div>

        {selectedFile && (
          <div className="mb-4">
            <p className="text-sm text-gray-600">Selected: {selectedFile.name}</p>
            <p className="text-xs text-gray-500">Size: {(selectedFile.size / 1024 / 1024).toFixed(2)} MB</p>
          </div>
        )}

        <button
          type="submit"
          disabled={loading || !selectedFile}
          className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
        >
          {loading ? 'Uploading...' : 'Create Post'}
        </button>
      </form>
    </div>
  );
};

export default CreatePost;