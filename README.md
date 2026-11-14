# HealthMate – Your Daily Health Companion

**CI6330 Coursework 1**

An offline personal health and wellness tracker built with Flutter, Material 3, SQLite (`sqflite`) and Provider.

## 1. Requirements

- Flutter **3.27 or newer** (stable channel)
- Dart 3.6+
- Android Studio and Android SDK for Android development
- Xcode for iOS development (macOS only)

## 2. First-Time Setup

This project contains the full Dart source code, including `lib/`, `test/`, `pubspec.yaml` and other project files.

If the native platform folders (`android/` and `ios/`) are missing, generate them once inside the extracted project directory:

```bash
cd HealthMate

flutter create --project-name healthmate --platforms=android,ios .
```

This generates the native platform files for the project. It is intended for projects where these folders are missing.

**Important:** If your project already contains the `android/` and `ios/` folders, you do not need to run this command again.

To generate additional platforms, you can include options such as `windows`, `macos` or `linux` where supported.

## 3. App Icon Generation

The launcher icon source files are located in:

```text
assets/images/
```

Available icon files:

- `app_icon.png`
- `app_icon_foreground.png`
- `app_icon_background.png`

After the native platform folders are available and dependencies are installed, generate the launcher icons:

```bash
dart run flutter_launcher_icons
```

## 4. Install Dependencies

Run the following command from the project root directory:

```bash
flutter pub get
```

## 5. Run the Application

Connect an Android emulator or physical device, then run:

```bash
flutter run
```

## 6. Run Code Analysis and Tests

Check the project for potential issues:

```bash
flutter analyze
```

Run the automated tests:

```bash
flutter test
```

The database tests use `sqflite_common_ffi` with an in-memory database, allowing them to run on your computer without an Android emulator.

On Linux, the SQLite development library may be required:

```bash
sudo apt install libsqlite3-dev
```

## 7. Application Features

### Dashboard

- Splash screen followed by a five-tab application.
- Add Record button.
- Daily steps, calories and water tracking.
- Goal progress rings.
- Seven-day steps chart.
- Recent health records.
- Empty state when no records exist.
- Automatic dashboard refresh after adding, editing or deleting records.

### Add / Edit Health Records

- Date picker.
- Numeric input fields.
- Required-field validation.
- Whole-number validation.
- Non-negative and maximum-value validation.
- Duplicate-date protection.

### History

- Displays records in newest-first order.
- Search records by date.
- Supported search formats:
  - `2026-11`
  - `2026-11-06`
  - `06/11/2026`
- Single-date picker.
- Date-range filtering.
- Edit and delete records.
- Delete confirmation.
- Individual record details screen.

### Analytics

- Daily summary with date browsing.
- Weekly charts for steps, water and calories.
- Goal reference lines in charts.
- Monthly totals with month navigation.
- Statistics including:
  - Average steps.
  - Average water intake.
  - Total calories.
  - Best activity day.

### Health Levels

Low, Moderate, Good and Excellent indicators show how daily health values compare with configured goals.

### Calories from Steps

- Estimates calories while entering step counts.
- Uses profile height and weight when available.
- Estimated calories can still be edited manually.

### Profile

- Age.
- Gender.
- Height.
- Weight.
- BMI calculation and category.
- Recommended step, water and calorie goals.
- Apply recommended goals with one tap.

### Weight Tracker

- Record weight by date.
- View weight trend charts.
- Track weight changes since the first recorded entry.
- The newest weight updates the profile and BMI.

### Water Quick-Add

Quickly add water intake from the Home screen:

- +150 ml
- +250 ml
- +500 ml

### Today's Summary

Accessible from the Home dashboard card.

Displays:

- Steps walked.
- Distance travelled.
- Calories burned.
- Activity levels.
- Daily water target.
- Water already consumed.
- Remaining water intake in millilitres and glasses.
- Whether water intake is ahead of or behind the expected schedule.
- Approximate water intake required per hour.

The water quick-add buttons also save directly to today's record.

### Additional Health Features

Additional health data, reminders, streaks, achievements and automatic step counting are covered by development stages 2–4.

Refer to `ANDROID_SETUP.md` for the Android permissions and Gradle configuration required for these features.

### Settings

- Daily step goal.
- Daily water goal.
- Daily calorie goal.
- Light theme.
- Dark theme.
- System theme.
- Sample-data controls.
- Application information.

### Sample Data

- Fourteen sample records are inserted once, only when the database is empty.
- Sample records represent the fourteen days before today.
- Today's date is never populated with a sample record.
- Sample records are labelled as `Sample`.
- Users can clear or re-add sample records through Settings.
- Clearing samples never deletes personal records.
- Editing a sample or adding steps or water to it converts it into a personal record.
- Sample records do not count towards streaks or achievements.

## 8. Database

**Database file:** `healthmate.db`

**Schema version:** 3

The database is created on the first application launch and reused on subsequent launches.

### Health Records Table

```sql
CREATE TABLE health_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  steps INTEGER NOT NULL,
  calories INTEGER NOT NULL,
  water INTEGER NOT NULL
);
```

- `date` uses ISO format (`yyyy-MM-dd`).
- Each date can have only one health record.
- Water intake is stored in millilitres.

### Database Schema Upgrades

- Version 2 adds the `weight_logs` table.
- Version 3 adds `sleep_logs`, `workout_logs` and `mood_logs`.
- The existing `health_records` table remains unchanged.
- Existing data is preserved during database upgrades.

### Weight Logs Table

```sql
CREATE TABLE weight_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  weight_kg REAL NOT NULL
);
```

### Database Implementation

All health-record queries are parameterised and handled through:

```text
lib/features/health_records/repositories/health_record_repository.dart
```

Database creation and schema upgrades are managed by:

```text
lib/core/database/database_helper.dart
```

Schema upgrades are implemented in:

```text
DatabaseHelper._onUpgrade
```

Goals and theme preferences are stored using `shared_preferences`.

## 9. Application Architecture

HealthMate follows the MVVM architecture pattern using Provider for state management.

### Project Structure

```text
lib/
  main.dart
  app.dart

  core/
    constants/
    database/
    theme/
    utils/
    shared_widgets/

  features/
    dashboard/
      DashboardStats (model)
      DashboardProvider
      splash
      shell
      dashboard screen

    health_records/
      model
      repository
      sample-data service
      HealthRecordsProvider
      form screen
      history screen
      detail screen

    analytics/
      analytics screen
      weekly bar chart

    summary/
      DailySummary (model)
      Today's summary screen
      water glass
      Home card

    settings/
      UserGoals
      SettingsProvider
      settings screen

test/
  database tests
  validator tests
  dashboard statistics tests
  provider tests
  widget tests
  daily summary tests
```

### Architecture Workflow

```text
       User Interface
             |
             v
          Provider
             |
             v
         Repository
             |
             v
           SQLite
```

- **Model:** Represents application data.
- **View:** Displays the user interface.
- **Provider:** Manages application state and updates the UI.
- **Repository:** Handles health-record data operations.
- **SQLite:** Stores health records locally.

Widgets access `HealthRecordsProvider`, `DashboardProvider` and `SettingsProvider`.

Providers communicate with the repository, and the repository handles SQLite health-record operations.

## 10. Automatic Step Counting

The automatic step-counting implementation includes the following behaviour:

- Steps walked while the application is closed are counted when the next sensor reading arrives, provided the previous reading was from yesterday or today.
- If there is a gap of more than one day, counting restarts from the next sensor reading.
- Phone reboots are handled by carrying today's accumulated step count forward.
- Writes to today's record, including sensor steps and water quick-add actions, are queued.
- Queued updates always start from the row stored in SQLite to prevent one update from overwriting another.

## 11. iOS Configuration

For iOS motion permission, add the following entries inside the `<dict>` element in:

```text
ios/Runner/Info.plist
```

```xml
<key>NSMotionUsageDescription</key>
<string>HealthMate counts your steps with the phone's motion sensor.</string>
```

Notifications and motion permissions are requested when the corresponding features are enabled.

## 12. Technologies Used

| Technology | Purpose |
|---|---|
| Flutter | Mobile application framework |
| Dart | Programming language |
| Material 3 | User interface design |
| SQLite | Offline database |
| sqflite | SQLite integration |
| Provider | State management |
| shared_preferences | Local settings storage |
| fl_chart | Charts and analytics |
| sqflite_common_ffi | Database testing |

## 13. Project Information

| Item | Details |
|---|---|
| Project | HealthMate – Your Daily Health Companion |
| Module | CI6330 – Coursework 1 |
| Platform | Android and iOS |
| Application Type | Offline Personal Health & Wellness Tracker |
| Architecture | MVVM with Provider |
| Database | SQLite |

---

**HealthMate – Your Daily Health Companion.**
