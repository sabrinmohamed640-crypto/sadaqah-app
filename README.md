# Sadaqah & Donation Management Mobile App

> A cross-platform mobile application engineered with Flutter & Dart for organizing charitable giving, tracking Sadaqah and Zakat contributions, and monitoring monthly giving goals.

---

## 📌 Problem & Purpose

Individuals seeking to maintain regular charitable habits often lack a dedicated, private, and distraction-free mobile tool to organize their giving, track multiple charitable causes (e.g., food aid, emergency relief, water wells, student scholarships), and reflect on their personal intentions without intrusive advertisements or complex finance platforms.

This mobile application provides an intuitive Flutter interface designed to organize donations with clear categorizations, goal tracking, and private record history.

---

## 📸 Screenshots

Screenshots will be added after capturing the final application UI.

---

## ✨ Features

- **Categorized Giving**: Separate tracking across 7 distinct causes: Zakat, Sadaqah Jariyah, Emergency Relief, Education & Students, Food & Water Aid, Masjid & Community, and General Sadaqah.
- **Monthly Giving Target Tracker**: Visual progress bar comparing current monthly donations against a user-defined giving goal.
- **Cause Breakdown Distribution**: Real-time distribution metrics displaying total giving per charitable category.
- **Chronological History & Filter Toolbar**: Search records by recipient organization or filter instantly across category pills.
- **Detailed Donation Receipts**: Dedicated record modal displaying timestamps, amounts, scheduling frequency, and private reflection notes.
- **Recurring Schedules**: Flexible donation frequency tagging (One-Time, Monthly, or Annual Zakat).
- **Dignified Dark Theme**: Custom emerald and dark slate palette crafted for comfortable night and day usage.

---

## 🛠️ Technology Stack

- **Framework**: Flutter 3.x (Material Design 3)
- **Language**: Dart
- **Architecture**: Clean Service-Repository pattern with reactive `StatefulWidget` hierarchy
- **Formatting**: `intl` package for currency and date formatting
- **Testing**: `flutter_test` unit & widget test suite

---

## 🏗️ Architecture

```text
sadaqah-app/
├── lib/
│   ├── main.dart                      # App entrypoint and bottom navigation shell
│   ├── models/
│   │   └── donation.dart              # Donation model, Category enums & JSON serialization
│   ├── services/
│   │   └── storage_service.dart       # In-memory state management service with demo data
│   ├── theme/
│   │   └── app_theme.dart             # Dark emerald color palette and widget theme data
│   └── screens/
│       ├── dashboard_screen.dart      # Giving metrics, monthly goal & recent feed
│       ├── records_screen.dart        # Searchable, filterable donation history
│       ├── add_donation_screen.dart   # Form with quick-amount selectors & validation
│       └── receipt_dialog.dart        # Detailed receipt modal
├── test/
│   └── widget_test.dart               # Unit and business logic test suite
├── pubspec.yaml                       # Flutter package dependencies
├── .gitignore                         # Flutter & Dart build and cache exclusions
└── README.md                          # Project documentation and setup guide
```

---

## 🚀 How to Run Locally

### 1. Prerequisites
- Flutter SDK (3.0+) and Dart installed and configured on PATH

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
# Run on Windows Desktop
flutter run -d windows

# Run in Chrome Web Browser
flutter run -d chrome

# Run on Connected Mobile Device
flutter run
```

---

## 🧪 Testing & Code Quality

Run Dart static analysis and the Flutter test suite:

```bash
# Run static analysis (0 errors, 0 warnings)
dart analyze

# Run unit & business logic test suite (5 test cases passing)
flutter test
```

---

## 🔮 Planned Future Enhancements

- Annual Zakat calculation helper based on current Nisab threshold values.
- PDF charitable donation tax summary export.
- Offline SQLite persistence via `sqflite` / `isar`.

---

## 💡 What I Learned

1. Composing custom, reusable Material 3 widgets in Flutter with responsive layout constraints.
2. Managing cross-screen state flow and form validation in Dart.
3. Structuring clean data models with typed enums, extension methods, and JSON converters.
4. Designing accessible visual data indicators (progress bars, category metrics, and bottom navigation).

---

## 👩‍💻 Author

**Sabrina Mohamed**
- GitHub: [@sabrinmohamed640-crypto](https://github.com/sabrinmohamed640-crypto)
- LinkedIn: [Sabrina Mohamed](https://www.linkedin.com/in/sabrina-mohamed-16bbb2426/)
