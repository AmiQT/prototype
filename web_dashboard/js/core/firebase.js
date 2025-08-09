// Firebase configuration
const firebaseConfig = {
  apiKey: "AIzaSyBEKSg01gWA8Z4Kv0NPCUfH_DCu4D1jO6Q",
  authDomain: "student-talent-profiling-eaede.firebaseapp.com",
  projectId: "student-talent-profiling-eaede",
  storageBucket: "student-talent-profiling-eaede.firebasestorage.app",
  messagingSenderId: "611009879331",
  appId: "1:611009879331:web:4c4382fe7d606e29328096"
};

// Initialize Firebase
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}

// Initialize Firebase services
const auth = firebase.auth();
const db = firebase.firestore();

// Export Firestore functions for compatibility
const { collection, getDocs, addDoc, deleteDoc, doc, query, where, limit, orderBy, updateDoc, getDoc } = firebase.firestore;

export { 
  auth, 
  db, 
  collection, 
  getDocs, 
  addDoc, 
  deleteDoc, 
  doc, 
  query, 
  where, 
  limit, 
  orderBy, 
  updateDoc, 
  getDoc 
};
