// Placeholder Firebase Messaging service worker.
// If you plan to use FCM on web, replace with your Firebase config and messaging handling.
// This file must be at the root of the domain (under /web for Flutter during dev serve).

self.addEventListener('install', (event) => {
  // Skip waiting to activate immediately.
  self.skipWaiting();
});

self.addEventListener('push', (event) => {
  // Basic fallback to display the payload if present.
  try {
    const data = event.data ? event.data.json() : {};
    const title = data.notification?.title || data.title || 'Notification';
    const body = data.notification?.body || data.body || '';
    event.waitUntil(
      self.registration.showNotification(title, { body })
    );
  } catch (e) {
    // ignore
  }
});
