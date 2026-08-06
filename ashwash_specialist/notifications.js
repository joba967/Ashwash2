const API_BASE_URL = 'https://ashwash-backend.onrender.com';

// Real Firebase Config
const firebaseConfig = {
    apiKey: "AIzaSyCKNb5xzn07zwOnz8i0M3llDEOOrOqJZm4",
    authDomain: "ashwash-b0441.firebaseapp.com",
    projectId: "ashwash-b0441",
    storageBucket: "ashwash-b0441.firebasestorage.app",
    messagingSenderId: "498385268612",
    appId: "1:498385268612:web:ecf2c65fb168fbd0a5f7d1"
};

try {
    firebase.initializeApp(firebaseConfig);
    const messaging = firebase.messaging();

    // Request Permission
    function requestNotificationPermission() {
        console.log('Requesting permission...');
        Notification.requestPermission().then((permission) => {
            if (permission === 'granted') {
                console.log('Notification permission granted.');
                // Get token
                messaging.getToken({ vapidKey: 'YOUR_PUBLIC_VAPID_KEY_HERE' }).then((currentToken) => {
                    if (currentToken) {
                        console.log('FCM Token:', currentToken);
                        sendTokenToServer(currentToken);
                    } else {
                        console.log('No registration token available.');
                    }
                }).catch((err) => {
                    console.log('An error occurred while retrieving token. ', err);
                });
            } else {
                console.log('Unable to get permission to notify.');
            }
        });
    }

    // Send Token to Django Backend
    function sendTokenToServer(token) {
        const specToken = localStorage.getItem('access_token');
        if (!specToken) return;

        fetch(`\${API_BASE_URL}/api/notifications/register-device/`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer \${specToken}`
            },
            body: JSON.stringify({ fcm_token: token, device_type: 'web' })
        })
        .then(res => res.json())
        .then(data => console.log('Device registered on backend'))
        .catch(err => console.error('Error registering device', err));
    }

    // Listen for foreground messages
    messaging.onMessage((payload) => {
        console.log('Message received. ', payload);
        // Show a toast or update UI
        showNotificationToast(payload.notification.title, payload.notification.body);
        fetchUnreadCount();
    });

    function showNotificationToast(title, body) {
        const toastHTML = `
            <div class="toast align-items-center text-white bg-primary border-0" role="alert" aria-live="assertive" aria-atomic="true" id="notifToast">
              <div class="d-flex">
                <div class="toast-body">
                  <strong>\${title}</strong><br>\${body}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Close"></button>
              </div>
            </div>
        `;
        const toastContainer = document.getElementById('toastContainer');
        if (toastContainer) {
            toastContainer.innerHTML += toastHTML;
            const toastEl = new bootstrap.Toast(document.getElementById('notifToast'));
            toastEl.show();
        }
    }

    // Fetch notifications list
    function fetchUnreadCount() {
        const specToken = localStorage.getItem('access_token');
        if (!specToken) return;

        fetch(`\${API_BASE_URL}/api/notifications/count/`, {
            headers: { 'Authorization': `Bearer \${specToken}` }
        })
        .then(res => res.json())
        .then(data => {
            const badge = document.getElementById('notificationBadge');
            if (badge) {
                if (data.unread_count > 0) {
                    badge.textContent = data.unread_count;
                    badge.classList.remove('d-none');
                } else {
                    badge.classList.add('d-none');
                }
            }
        });
    }

    // Initialize on load if logged in
    document.addEventListener('DOMContentLoaded', () => {
        if (localStorage.getItem('access_token')) {
            requestNotificationPermission();
            fetchUnreadCount();
        }
    });

} catch (e) {
    console.error("Firebase not configured correctly. Skipping push notifications initialization.", e);
}
