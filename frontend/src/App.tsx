import React, { useState } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { signOutUser } from './services/authService';
import LoginForm from './components/Auth/LoginForm';
import RegisterForm from './components/Auth/RegisterForm';
import CreatePost from './components/Posts/CreatePost';
import PostList from './components/Posts/PostList';
import './App.css';

const AuthenticatedApp: React.FC = () => {
  const { currentUser, userProfile } = useAuth();
  const [activeTab, setActiveTab] = useState<'feed' | 'create' | 'profile'>('feed');

  const handleSignOut = async () => {
    try {
      await signOutUser();
    } catch (error) {
      console.error('Error signing out:', error);
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      <nav className="bg-white shadow-md p-4">
        <div className="max-w-4xl mx-auto flex justify-between items-center">
          <h1 className="text-2xl font-bold text-blue-600">Bacon13</h1>
          
          <div className="flex space-x-4">
            <button
              onClick={() => setActiveTab('feed')}
              className={`px-4 py-2 rounded ${activeTab === 'feed' ? 'bg-blue-600 text-white' : 'text-blue-600 hover:bg-blue-50'}`}
            >
              Feed
            </button>
            <button
              onClick={() => setActiveTab('create')}
              className={`px-4 py-2 rounded ${activeTab === 'create' ? 'bg-blue-600 text-white' : 'text-blue-600 hover:bg-blue-50'}`}
            >
              Create Post
            </button>
            <button
              onClick={() => setActiveTab('profile')}
              className={`px-4 py-2 rounded ${activeTab === 'profile' ? 'bg-blue-600 text-white' : 'text-blue-600 hover:bg-blue-50'}`}
            >
              My Posts
            </button>
          </div>

          <div className="flex items-center space-x-4">
            <span className="text-sm text-gray-600">
              Welcome, {userProfile?.email || currentUser?.email}
            </span>
            <button
              onClick={handleSignOut}
              className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
            >
              Sign Out
            </button>
          </div>
        </div>
      </nav>

      <main className="max-w-4xl mx-auto p-6">
        {activeTab === 'feed' && <PostList showUserPosts={false} />}
        {activeTab === 'create' && <CreatePost />}
        {activeTab === 'profile' && <PostList showUserPosts={true} />}
      </main>
    </div>
  );
};

const UnauthenticatedApp: React.FC = () => {
  const [isLogin, setIsLogin] = useState(true);

  return (
    <div className="min-h-screen bg-gray-100 flex items-center justify-center">
      <div className="max-w-md w-full">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-blue-600 mb-2">Bacon13</h1>
          <p className="text-gray-600">Share your moments with the world</p>
        </div>

        {isLogin ? <LoginForm /> : <RegisterForm />}

        <div className="text-center mt-4">
          <button
            onClick={() => setIsLogin(!isLogin)}
            className="text-blue-600 hover:text-blue-800"
          >
            {isLogin ? "Don't have an account? Sign up" : "Already have an account? Sign in"}
          </button>
        </div>
      </div>
    </div>
  );
};

const AppContent: React.FC = () => {
  const { currentUser, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-100 flex items-center justify-center">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return currentUser ? <AuthenticatedApp /> : <UnauthenticatedApp />;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <AppContent />
      </Router>
    </AuthProvider>
  );
}

export default App;
