# HealthMate – Personal Health & Wellness Tracker

A Flutter-based mobile application designed to help users record, monitor, and manage their daily health and wellness activities.

## 📱 Project Overview

HealthMate is a personal health and wellness tracking application developed as part of the **CI6330 – Mobile Application Development** coursework at Kingston University.

The application allows users to record daily health information, monitor their progress, view historical records, and track personal wellness goals through a simple and user-friendly interface.

## ✨ Key Features

- **Dashboard:** View daily health statistics and progress.
- **Add Health Records:** Record daily steps, calories burned, and water intake.
- **Edit Records:** Update previously saved health records.
- **Delete Records:** Remove unwanted health entries.
- **Health History:** View previously recorded health information.
- **Search and Filter:** Find records using dates.
- **Analytics:** View health activity summaries and weekly progress.
- **Personal Goals:** Set and manage daily health targets.
- **Local Data Storage:** Save health records locally using SQLite.

## 🛠️ Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Cross-platform application development |
| Dart | Programming language |
| SQLite | Local database |
| Provider | State management |
| fl_chart | Data visualisation |
| Android Studio | Development and testing |
| Visual Studio Code | Code editor |
| Git & GitHub | Version control |

## 🏗️ Project Architecture

The application follows a feature-based structure with separation of responsibilities.

```text
lib/
├── core/
│   ├── constants/
│   ├── database/
│   ├── theme/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── analytics/
│   ├── dashboard/
│   ├── health_records/
│   └── settings/
│
├── app.dart
└── main.dart

test/
├── dashboard_stats_test.dart
├── database_test.dart
├── provider_test.dart
├── record_form_widget_test.dart
└── validators_test.dart
```

### Main Components

- **Models:** Represent health record and application data.
- **Providers:** Manage application state.
- **Repositories:** Handle health record data operations.
- **Database Helper:** Manages SQLite database operations.
- **Screens:** Provide the application's user interface.
- **Widgets:** Reusable UI components.

## 🗄️ Database

HealthMate uses SQLite for local data storage.

The main health records contain:

| Field | Description |
|---|---|
| id | Unique record identifier |
| date | Health record date |
| steps | Daily steps count |
| calories | Calories burned |
| water | Daily water intake in millilitres |

## 🚀 Getting Started

### Prerequisites

Install the following tools:

- Flutter SDK
- Dart SDK
- Android Studio or Visual Studio Code
- Android Emulator or a physical Android device

### Installation

**1. Clone the repository**

```bash
git clone https://github.com/abdullahmhd43/HealthMate-Flutter-App.git
```

**2. Navigate to the project folder**

```bash
cd HealthMate-Flutter-App
```

**3. Install dependencies**

```bash
flutter pub get
```

**4. Run the application**

```bash
flutter run
```

### Build Release APK

To generate a release APK:

```bash
flutter build apk --release
```

The generated APK will be available at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 🧪 Testing

The project includes automated tests covering:

- Dashboard statistics
- Database operations
- Provider functionality
- Record form functionality
- Input validation

Run the tests using:

```bash
flutter test
```

Check code quality using:

```bash
flutter analyze
```

## 👨‍💻 Developer

**Mohamed Abdullah**

BSc (Hons) Software Engineering  
Kingston University – ESOFT Metro Campus  
Sri Lanka

## 🎓 Academic Information

| Detail | Information |
|---|---|
| Module | CI6330 – Mobile Application Development |
| Coursework | Coursework 1 |
| Project | HealthMate – Personal Health & Wellness Tracker |
| Development Framework | Flutter |
| Database | SQLite |

## 📂 Repository

GitHub Repository:

https://github.com/abdullahmhd43/HealthMate-Flutter-App

---

*HealthMate – Track Your Health, Improve Your Life.*
