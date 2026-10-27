# 🔍 Firestore Connection Audit & Troubleshooting Guide

## System Status Overview

Your Waqf Projects system uses the following architecture:

```
WaqfProjectsScreen
    ↓
StreamBuilder (listening to getAllProjectsStream)
    ↓
WaqfProjectService.getAllProjectsStream()
    ↓
Firestore Collection: 'projects' (with sub-collection: 'stages')
    ↓
Firebase Authentication (current user must be signed in)
```

---

## 🔧 Step-by-Step Audit

### 1️⃣ COLLECTION NAME VERIFICATION ✅ **CONFIRMED**

**Collection Path:** `projects`
- **Location:** `lib/services/waqf_project_service.dart` (line 11)
- **Constant:** `static const String _projectsCollection = 'projects';`
- **Sub-collection:** `projects/{projectId}/stages/{stageId}`

**Action Required:** 
- Open your Firebase Console
- Navigate to Firestore Database
- **Verify that your collection is named exactly `'projects'` (lowercase, no spaces)**
- If your collection has a different name (e.g., 'Projects', 'Waqf_Projects'), you must rename it to `'projects'` or update the constant in the service

---

### 2️⃣ AUTHENTICATION CONTEXT CHECK 🔑

**Current Implementation:**
```dart
// In firestore.rules:
match /projects/{projectId} {
  allow read: if isSignedIn();  // ← REQUIRES USER AUTHENTICATION
  allow create, update, delete: if isAdmin();
}
```

**Common Issues:**
- ❌ User is not signed in
- ❌ User session expired
- ❌ Wrong Firebase project in app config

**Debug Steps:**
1. **Check Console Logs** - Open Flutter console and look for:
   - `📱 Auth User: [email]` should NOT be "NOT SIGNED IN"
   - `🔐 Admin: true/false` should be visible
   - If you see "NOT SIGNED IN", navigate to login screen first

2. **Verify User Document** - In Firebase Console:
   - Go to Firestore → Collection `users`
   - Look for a document with your user ID (should match your email)
   - Check that `role` field exists and is set to `'muzakki'` or `'admin'`

3. **Test Code** - Add this to check authentication:
```dart
final user = FirebaseAuth.instance.currentUser;
print('🔐 Current user: ${user?.email}');
print('🔐 User ID: ${user?.uid}');
```

---

### 3️⃣ SERVICE INITIALIZATION CHECK ✅ **CONFIRMED**

**Both screens correctly initialize the service:**

**WaqfProjectsScreen** (line 18):
```dart
final WaqfProjectService _projectService = WaqfProjectService();
```

**AdminWaqfManager** (line 18):
```dart
final WaqfProjectService _projectService = WaqfProjectService();
```

**Both screens use it correctly:**
```dart
stream: _projectService.getAllProjectsStream(),
```

✅ Service is initialized and used correctly.

---

### 4️⃣ VISUAL DEBUGGING - CONNECTION STATUS IN UI ✅ **IMPLEMENTED**

**New Debug Utility:** `lib/utils/firestore_debug.dart`

The diagnostic widget automatically appears in:
- **Loading state** - Shows connection status while waiting
- **Error state** - Shows detailed error type
- **Empty state** - Shows if connection is active but no data

**What You'll See:**

```
┌─────────────────────────────────────┐
│ DEBUG: WaqfProjectsScreen           │
├─────────────────────────────────────┤
│ Auth Status      ✅ Signed In (uid) │
│ Admin Role       ⚠️ Not Admin       │
│ Connection       ⏳ Waiting...      │
│ Error Type       🔒 Permission...  │
│ Data Received    ✅ Snapshot ok    │
│                                     │
│ Collection: projects | Sub: stages  │
└─────────────────────────────────────┘
```

**Legend:**
- ✅ = OK / Connected
- ❌ = Failed / Not signed in
- ⚠️ = Warning / Missing admin
- 🔒 = Permission denied
- 📭 = Collection not found
- 🔑 = Not authenticated
- ⏳ = Still loading

---

### 5️⃣ FIRESTORE RULES AUDIT ✅ **CONFIGURED**

**Current Rules Configuration:**
```
match /projects/{projectId} {
  allow read: if isSignedIn();           // ✅ User can read
  allow create, update, delete: if isAdmin(); // ✅ Only admin can write

  match /stages/{stageId} {
    allow read: if isSignedIn();         // ✅ User can read stages
    allow create, update, delete: if isAdmin(); // ✅ Only admin can write
  }
}
```

**Status:** ✅ Rules correctly configured for signed-in users to read

**Potential Issues:**
- If you see "Permission Denied" error, check:
  1. User is actually signed in
  2. `isSignedIn()` function exists and returns `true`
  3. Your Firestore rules are deployed (check Firebase Console > Rules tab)

---

### 6️⃣ DONATION FLOW SYNC CHECK ✅ **IMPLEMENTED**

**ProjectID Passing - WaqfProjectsScreen → DonationDetailsScreen:**

```dart
// Line 464 - WaqfProjectsScreen
DonationDetailsScreen(
  serviceName: project.titleEn,
  waqfProjectId: project.id,  // ← ProjectID is passed ✅
),
```

**DonationDetailsScreen Update Logic:**

```dart
// In donation_details_screen.dart - After transaction submitted:
if (widget.waqfProjectId != null && widget.waqfProjectId!.isNotEmpty) {
  await FirebaseFirestore.instance
      .collection('projects')
      .doc(widget.waqfProjectId)
      .update({
        'raised': FieldValue.increment(amount), // ← Updates project
        'updatedAt': FieldValue.serverTimestamp(),
      });
  print('✅ Updated Waqf project raised amount by \$amount');
}
```

**Verification:**
1. ✅ ProjectID is passed to DonationDetailsScreen
2. ✅ DonationDetailsScreen receives it (constructor updated)
3. ✅ On donation submit, Firestore project's `raised` field is incremented
4. ✅ Success flow checks if milestone reached

---

## 🚨 Troubleshooting Checklist

### Issue: "No projects available yet" (but data exists in Firestore)

**Probable Causes (in order of likelihood):**

1. **User Not Authenticated** ← Most Common
   - ✅ Check console for "NOT SIGNED IN" message
   - ✅ Implement login flow before accessing Waqf screen
   - ✅ Verify user document exists in `/users/{uid}` collection

2. **Permission Denied Error**
   - ✅ Firestore rules have `allow read: if isSignedIn();`
   - ✅ Check that `isSignedIn()` helper function is defined
   - ✅ Verify no typos in security rules

3. **Collection Name Mismatch**
   - ✅ Check Firebase Console collection name vs code (must be `'projects'`)
   - ✅ Case-sensitive! `'Projects'` ≠ `'projects'`
   - ✅ No spaces allowed

4. **Empty Firestore Database**
   - ✅ Go to Firebase Console → Firestore → collections
   - ✅ Verify `'projects'` collection exists with documents
   - ✅ Use admin panel to create test project if empty

5. **Firestore Emulator Enabled**
   - ✅ Check if Android/iOS is pointing to localhost emulator
   - ✅ Run `firebase emulators:start` in terminal to start emulator
   - ✅ Or disable emulator in your app initialization

### Issue: "Permission Denied" in Console

**Solution:**
1. Check Firebase Console → Firestore → Rules tab
2. Ensure rules file is **deployed** (shows "Rules are not published" if not)
3. Click "Publish" button to deploy rules
4. Verify `allow read: if isSignedIn();` exists

### Issue: "Error: [cloud_firestore/cancelled]"

**Solution:**
1. User closed the app or navigated away
2. Increase query timeout in code:
```dart
Stream<List<WaqfProject>> getAllProjectsStream() {
  return _db
      .collection(_projectsCollection)
      .withConverter<WaqfProject>(
        fromFirestore: (doc, _) => WaqfProject.fromFirestore(doc),
        toFirestore: (project, _) => project.toFirestore(),
      )
      .snapshots()
      .timeout(const Duration(seconds: 30)); // Add timeout handling
}
```

### Issue: Donation Amount Not Updating in Firestore

**Checklist:**
1. ✅ Confirm `waqfProjectId` is not null/empty in DonationDetailsScreen
2. ✅ Check Firestore rules allow 'admin' to update 'projects' collection
3. ✅ Verify donation amount is > 0
4. ✅ Check console logs for "Updated Waqf project raised amount" message

---

## 📊 Diagnostic Output Interpretation

### Console Logs to Look For:

**Healthy Connection:**
```
📡 [WaqfProjectService] Starting getAllProjectsStream...
   Collection: projects
📥 [WaqfProjectService] Received snapshot with 3 documents
   ✅ Parsed project: abc123 - Educational Waqf
   ✅ Parsed project: def456 - Water Well Waqf
   ✅ Parsed project: ghi789 - Quran Printing Waqf
📊 [WaqfProjectService] Total projects parsed: 3
```

**Permission Error:**
```
🔴 [WaqfProjectService] Stream error: 
[cloud_firestore/permission-denied] 
The caller does not have permission to execute the specified operation.
```

**No Data Error:**
```
📥 [WaqfProjectService] Received snapshot with 0 documents
📊 [WaqfProjectService] Total projects parsed: 0
```

**Authentication Error:**
```
🔴 [WaqfProjectService] Stream error: 
[cloud_firestore/unauthenticated] 
The request is not authenticated.
```

---

## 🎯 Next Steps

1. **Run Flutter App** and observe console output
2. **Check Debug Widget** displayed on screen (orange border)
3. **Compare Status** with the healthy/error patterns above
4. **Apply Solution** based on matching pattern
5. **Verify Fix** by checking console logs for "✅" messages

---

## 🔗 Reference Map

| File | Purpose | Collection |
|------|---------|-----------|
| `waqf_project_service.dart` | Data access layer | `projects` |
| `waqf_projects_screen.dart` | User-facing UI | Uses service |
| `admin_waqf_manager.dart` | Admin management UI | Uses service |
| `donation_details_screen.dart` | Donation submission | Updates `projects/{id}` |
| `firestore.rules` | Security rules | Defines read/write access |
| `firestore_debug.dart` | Debugging utility | Logs + UI widget |

---

## 📞 Support Info

**If issues persist:**
1. Export console logs (right-click console → Save as)
2. Take screenshot of debug widget
3. Share:
   - Console log output
   - Debug widget screenshot
   - Firestore collection structure (if possible)
