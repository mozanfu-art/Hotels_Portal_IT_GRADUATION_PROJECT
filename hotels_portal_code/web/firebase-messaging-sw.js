importScripts(
  "https://www.gstatic.com/firebasejs/12.3.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/12.3.0/firebase-messaging-compat.js"
);

const firebaseConfig = {
  apiKey: "AIzaSyC6DEy1phl6z-0owQ8u0RygFtvherJFvjA",
  authDomain: "graduation-project-5f333.firebaseapp.com",
  databaseURL: "https://graduation-project-5f333-default-rtdb.firebaseio.com",
  projectId: "graduation-project-5f333",
  storageBucket: "graduation-project-5f333.firebasestorage.app",
  messagingSenderId: "863262733039",
  appId: "1:863262733039:web:3e598ca2d5c9bee2a7e11a",
  measurementId: "G-78FJYRKBKF",
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

// Optional background logging
messaging.onBackgroundMessage((message) => {
  console.log("onBackgroundMessage", message);
});
