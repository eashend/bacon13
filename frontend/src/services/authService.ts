import { 
  createUserWithEmailAndPassword, 
  signInWithEmailAndPassword, 
  signOut, 
  User,
  onAuthStateChanged
} from 'firebase/auth';
import { doc, setDoc, getDoc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { auth, db } from '../firebase/config';

export interface UserProfile {
  id: string;
  email: string;
  createdAt: any;
  updatedAt: any;
  profileImages: string[];
}

// Auth state listener
export const onAuthStateChange = (callback: (user: User | null) => void) => {
  return onAuthStateChanged(auth, callback);
};

// Register new user
export const registerUser = async (email: string, password: string): Promise<User> => {
  const userCredential = await createUserWithEmailAndPassword(auth, email, password);
  const user = userCredential.user;
  
  // Create user profile in Firestore
  await createUserProfile(user.uid, user.email!);
  
  return user;
};

// Sign in user
export const signInUser = async (email: string, password: string): Promise<User> => {
  const userCredential = await signInWithEmailAndPassword(auth, email, password);
  return userCredential.user;
};

// Sign out user
export const signOutUser = async (): Promise<void> => {
  await signOut(auth);
};

// Create user profile in Firestore
export const createUserProfile = async (uid: string, email: string): Promise<void> => {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  
  if (!userSnap.exists()) {
    const userProfile: Omit<UserProfile, 'id'> = {
      email,
      createdAt: serverTimestamp(),
      updatedAt: serverTimestamp(),
      profileImages: []
    };
    
    await setDoc(userRef, userProfile);
  }
};

// Get user profile
export const getUserProfile = async (uid: string): Promise<UserProfile | null> => {
  const userRef = doc(db, 'users', uid);
  const userSnap = await getDoc(userRef);
  
  if (userSnap.exists()) {
    return { id: uid, ...userSnap.data() } as UserProfile;
  }
  
  return null;
};

// Update user profile
export const updateUserProfile = async (uid: string, updates: Partial<UserProfile>): Promise<void> => {
  const userRef = doc(db, 'users', uid);
  await updateDoc(userRef, {
    ...updates,
    updatedAt: serverTimestamp()
  });
};

// Get current user
export const getCurrentUser = (): User | null => {
  return auth.currentUser;
};

// Get ID token for API calls (if needed for Cloud Functions)
export const getIdToken = async (): Promise<string | null> => {
  const user = getCurrentUser();
  if (user) {
    return await user.getIdToken();
  }
  return null;
};