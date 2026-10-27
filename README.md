# Khairat (خَيْرات) — Mobile-Based Zakat & Sadaqah Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

An enterprise-grade, privacy-conscious cross-platform mobile application engineered with **Flutter**, **Dart**, and **Cloud Firestore** for organizing charitable giving, tracking Zakat obligations, managing Waqf endowments, and administering aid delivery with verifiable audit trails.

Developed as a **Computer Science Graduation Project** addressing localized charitable distribution and Zakat calculation in Somalia and the Horn of Africa.

---

## 🌟 Key Highlights

* **Role-Based Access Control (RBAC):** Dedicated, secure views for four distinct user archetypes:
  * **Muzakki (Donors):** Quick Giving, Nisab calculations, donation tracking, and impact metrics.
  * **Mustahik (Beneficiaries):** Secure aid requests, application status tracking, and disbursement verification.
  * **Amil (Zakat Collectors/Admins):** Field collection, verification workflow, and transaction logging.
  * **System Administrator:** Executive analytics dashboard, user approvals, Waqf project management, and audit logs.
* **Specialized Somali & Sharia-Compliant Zakat Calculators:**
  * **Livestock Zakat Calculator (حساب زكاة الأنعام):** Specialized Nisab thresholds and bracket calculations for Camels (*Geel*), Cattle (*Lo'*), and Sheep/Goats (*Ari*).
  * **Cash, Gold & Silver Zakat Calculator:** Real-time calculation based on current Nisab values.
* **Waqf & Long-Term Endowment Management:** Multi-stage developmental project funding, milestone tracking, and community impact reports.
* **Orphan Sponsorship Module:** Direct sponsorship management with transparent updates.
* **Enterprise Reporting Engine:** Real-time automated PDF and CSV generation for financial statements and distribution audits.
* **Offline-Resilient Architecture:** Local caching abstractions with automatic Cloud Firestore synchronization and optimistic UI updates.

---

## 🏗️ Architecture & Technical Stack

```
Khairat Mobile Application
├── Presentation Layer (Flutter & Material 3)
│   ├── Screens (Admin Portal, Donor Views, Beneficiary Workflows)
│   ├── Custom UI Components & Animated Cards
│   └── Multi-Theme Design System (Dark & Light Mode)
│
├── Business Logic & State Layer
│   ├── Zakat Computational Engines (Livestock, Cash, Gold)
│   ├── Role Gateways & Safe Navigation Guards
│   └── Cache Managers & Reactive Stream Controllers
│
└── Infrastructure & Data Layer (Firebase)
    ├── Firebase Authentication (JWT & Session Lifecycles)
    ├── Cloud Firestore (Normalized Collections with Composite Indexes)
    ├── Security Rules (Collection-level RBAC)
    └── Cloud Messaging (FCM Push Notifications)
```

### Core Technologies
* **Framework:** Flutter 3.x (Dart 3.x)
* **Backend:** Cloud Firestore, Firebase Authentication, Cloud Messaging
* **State Management:** Reactive streams (`RxDart`), `ChangeNotifier`, Services Layer
* **Persistence & Caching:** `shared_preferences`, Firestore offline persistence
* **Document Generation:** `pdf`, `csv`
* **UI/UX:** Custom Material 3, `lottie` micro-animations, accessible color palette

---

## 📱 Feature Overview

### 1. Sharia-Compliant Zakat Calculators
* **Livestock Nisab Engine:** 
  * Camels: 5 to 150+ with traditional Islamic distribution brackets (Bint Makhad, Bint Labun, Hiqqah, Jaza'ah).
  * Cattle: Tabi' and Musinnah requirements.
  * Sheep & Goats: 40 to 400+ bracket steps.
* **Wealth & Commercial Assets:** Calculates 2.5% on qualifying balances exceeding the gold (85g) or silver (595g) standard after one lunar year (*Hawl*).

### 2. Executive Admin Console
* 4 Real-time metrics: Total Donations, Active Beneficiaries, Funded Campaigns, and System Health.
* Direct approval and verification workflow for aid requests.
* Firestore index optimization and audit logging.

### 3. Waqf & Sustainable Development
* Project-based giving targeting educational infrastructure, clean water wells, and community health centers.
* Stage-by-stage funding transparency with live percentage trackers.

---

## 📂 Project Structure

```
lib/
├── config/              # Firebase messaging and platform configuration
├── data/                # Static models and seed data
├── models/              # Immutable data transfer objects (Donation, Campaign, Waqf, Mustahik, etc.)
├── screens/             # UI Views (Admin Dashboard, Splash, Auth, Waqf, Calculator)
├── services/            # Backend communication, Auth, Analytics, Report Generation
├── utils/               # Constants, Localization, Theme, and Zakat Calculators
│   └── zakat_calculator/
│       ├── cash_zakat_calculator.dart
│       ├── livestock_zakat_calculator.dart
│       └── zakat_calculation_result.dart
├── widgets/             # Reusable UI components (Stats Cards, Animated Buttons)
└── main.dart            # Application bootstrap with safe Firebase initialization
```

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (`^3.12.1` or newer)
* Dart SDK (`^3.12.1` or newer)
* Android Studio / VS Code with Flutter extension
* A configured Firebase Project (Google Services JSON / Plist)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/sabrinmohamed640-crypto/sadaqah-app.git
   cd sadaqah-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the development build:
   ```bash
   flutter run
   ```

---

## 📄 License
This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

**Developed with dedication by Sabrina Mohamed — Computer Science Graduate.**
