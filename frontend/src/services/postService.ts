import { 
  collection, 
  addDoc, 
  getDocs, 
  query, 
  where, 
  orderBy, 
  limit,
  serverTimestamp 
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { db, storage } from '../firebase/config';
import { getCurrentUser } from './authService';

export interface Post {
  id: string;
  userId: string;
  imageUrl: string;
  createdAt: any;
  updatedAt: any;
}

// Upload image to Firebase Storage
export const uploadImage = async (file: File): Promise<string> => {
  const user = getCurrentUser();
  if (!user) throw new Error('User not authenticated');
  
  const fileName = `${Date.now()}_${file.name}`;
  const imageRef = ref(storage, `posts/${user.uid}/${fileName}`);
  
  const snapshot = await uploadBytes(imageRef, file);
  const downloadURL = await getDownloadURL(snapshot.ref);
  
  return downloadURL;
};

// Create new post
export const createPost = async (imageFile: File): Promise<Post> => {
  const user = getCurrentUser();
  if (!user) throw new Error('User not authenticated');
  
  // Upload image first
  const imageUrl = await uploadImage(imageFile);
  
  // Create post document
  const postData = {
    userId: user.uid,
    imageUrl,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp()
  };
  
  const docRef = await addDoc(collection(db, 'posts'), postData);
  
  return {
    id: docRef.id,
    ...postData
  } as Post;
};

// Get user's posts
export const getUserPosts = async (userId: string): Promise<Post[]> => {
  const q = query(
    collection(db, 'posts'),
    where('userId', '==', userId),
    orderBy('createdAt', 'desc')
  );
  
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  })) as Post[];
};

// Get public feed (latest posts)
export const getPublicFeed = async (limitCount: number = 20): Promise<Post[]> => {
  const q = query(
    collection(db, 'posts'),
    orderBy('createdAt', 'desc'),
    limit(limitCount)
  );
  
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data()
  })) as Post[];
};

// Get current user's posts
export const getCurrentUserPosts = async (): Promise<Post[]> => {
  const user = getCurrentUser();
  if (!user) throw new Error('User not authenticated');
  
  return getUserPosts(user.uid);
};