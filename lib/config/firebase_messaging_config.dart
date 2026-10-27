/// Firebase Cloud Messaging Configuration & Integration Guide
///
/// This file documents the setup and initialization for Firebase Cloud Messaging (FCM)
/// across Android, iOS, and Web platforms for the Zakat Management System.
///
/// DEPLOYMENT STEPS:
///
/// 1. ANDROID SETUP
///    ────────────────────────────────────────────────────────────────
///
///    a) Ensure google-services.json exists at:
///       android/app/google-services.json
///
///    b) Add to android/app/build.gradle.kts:
///       ```
///       dependencies {
///         implementation 'com.google.firebase:firebase-messaging-ktx'
///       }
///       ```
///
///    c) Update android/build.gradle.kts:
///       ```
///       plugins {
///         id "com.google.gms.google-services" version "4.3.15" apply false
///       }
///       ```
///
///    d) Apply plugin in android/app/build.gradle.kts:
///       ```
///       apply plugin: 'com.google.gms.google-services'
///       ```
///
///    e) Create notification channel in MainActivity.kt:
///       ```kotlin
///       import android.app.NotificationChannel
///       import android.app.NotificationManager
///       import android.os.Build
///
///       override fun onCreate(savedInstanceState: Bundle?) {
///         super.onCreate(savedInstanceState)
///
///         // Create notification channel for Android 8+
///         if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
///           val channel = NotificationChannel(
///             "zakat_notifications",
///             "Zakat Notifications",
///             NotificationManager.IMPORTANCE_HIGH
///           ).apply {
///             description = "Notifications for Zakat donations and approvals"
///           }
///           val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
///           notificationManager.createNotificationChannel(channel)
///         }
///       }
///       ```
///
///    f) Update AndroidManifest.xml:
///       ```xml
///       <!-- Permissions -->
///       <uses-permission android:name="android.permission.INTERNET" />
///       <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
///       ```
///
/// 2. iOS SETUP
///    ────────────────────────────────────────────────────────────────
///
///    a) Ensure GoogleService-Info.plist exists at:
///       ios/Runner/GoogleService-Info.plist
///
///    b) In Xcode:
///       - Open ios/Runner.xcworkspace (NOT .xcodeproj)
///       - Select Runner project
///       - Select Runner target
///       - Go to Capabilities tab
///       - Enable "Push Notifications"
///       - Enable "Remote Notifications" (Background Modes)
///
///    c) Update ios/Podfile:
///       ```ruby
///       target 'Runner' do
///         flutter_root = File.expand_path('..', __FILE__)
///         load File.join(flutter_root, '.ios', 'Flutter', 'podhelper.rb')
///
///         flutter_ios_podfile_setup
///
///         post_install do |installer|
///           installer.pods_project.targets.each do |target|
///             flutter_additional_ios_build_settings(target)
///             target.build_configurations.each do |config|
///               config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
///                 '$(inherited)',
///                 'PERMISSION_NOTIFICATIONS=1',
///               ]
///             end
///           end
///         end
///       end
///       ```
///
///    d) Update ios/Runner/Info.plist:
///       ```xml
///       <key>UIBackgroundModes</key>
///       <array>
///         <string>remote-notification</string>
///       </array>
///       ```
///
/// 3. WEB SETUP
///    ────────────────────────────────────────────────────────────────
///
///    a) Add web/firebase-messaging-sw.js:
///       ```javascript
///       importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js');
///       importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging.js');
///
///       firebase.initializeApp({
///         projectId: 'YOUR_PROJECT_ID',
///         appId: 'YOUR_APP_ID',
///         apiKey: 'YOUR_API_KEY',
///         authDomain: 'YOUR_AUTH_DOMAIN',
///         storageBucket: 'YOUR_STORAGE_BUCKET',
///         messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
///       });
///
///       const messaging = firebase.messaging();
///
///       messaging.onBackgroundMessage((payload) => {
///         console.log('Received background message:', payload);
///         const notificationTitle = payload.notification.title;
///         const notificationOptions = {
///           body: payload.notification.body,
///           icon: '/firebase-logo.png',
///         };
///         self.registration.showNotification(notificationTitle, notificationOptions);
///       });
///       ```
///
///    b) Register service worker in web/index.html:
///       ```html
///       <script>
///         if ('serviceWorker' in navigator) {
///           navigator.serviceWorker.register('/firebase-messaging-sw.js');
///         }
///       </script>
///       ```
///
/// 4. FLUTTER INTEGRATION (Already in Code)
///    ────────────────────────────────────────────────────────────────
///
///    The NotificationService in lib/services/notification_service.dart:
///    - Initializes FCM in the app
///    - Handles foreground messages
///    - Handles background messages
///    - Manages local and remote notifications
///
///    Usage in main.dart:
///    ```dart
///    final notificationService = NotificationService();
///    await notificationService.initialize();
///    ```
///
/// 5. DEPLOY TO FIREBASE
///    ────────────────────────────────────────────────────────────────
///
///    a) Deploy Firestore Rules:
///       ```bash
///       firebase deploy --only firestore:rules
///       ```
///
///    b) Deploy Cloud Functions (if using server-side messaging):
///       ```bash
///       firebase deploy --only functions
///       ```
///
/// 6. TEST FCM
///    ────────────────────────────────────────────────────────────────
///
///    a) In Firebase Console:
///       - Go to Cloud Messaging
///       - Select "Send your first message"
///       - Compose test message
///       - Send to test device
///
///    b) Monitor in Flutter:
///       - Check device logs: `flutter logs`
///       - Verify notifications appear
///       - Check unread count in NotificationService stream
///
/// 7. HANDLING NOTIFICATION PERMISSIONS
///    ────────────────────────────────────────────────────────────────
///
///    The NotificationService.initialize() method already:
///    - Requests iOS push notification permission
///    - Displays permission prompt to users
///    - Handles permission denials gracefully
///
/// 8. TROUBLESHOOTING
///    ────────────────────────────────────────────────────────────────
///
///    Issue: No notifications received on Android
///    Solution:
///    - Check AndroidManifest.xml has POST_NOTIFICATIONS permission
///    - Verify notification channel is created
///    - Check Firebase Console for sending status
///    - Ensure app has notification permission enabled in system settings
///
///    Issue: Background messages not received
///    Solution:
///    - Verify onBackgroundMessage handler is registered
///    - Check app is in background when sending test message
///    - Monitor device logs for message receipt
///
///    Issue: iOS notifications not appearing
///    Solution:
///    - Verify Push Notifications capability is enabled in Xcode
///    - Check GoogleService-Info.plist is properly configured
///    - Ensure Remote Notifications is enabled in Background Modes
///    - Check iOS device notification settings
///
/// 9. PRODUCTION CHECKLIST
///    ────────────────────────────────────────────────────────────────
///
///    Before deploying to production:
///    ✓ Firebase project created with FCM enabled
///    ✓ google-services.json added (Android)
///    ✓ GoogleService-Info.plist added (iOS)
///    ✓ Notification permissions properly requested
///    ✓ Test message successfully received on all platforms
///    ✓ Firestore rules deployed
///    ✓ Notification Service initialized in main()
///    ✓ Error handling and logging in place
///    ✓ User privacy and opt-out mechanisms implemented
///
library;
