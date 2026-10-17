# SkillUp — Cross-Platform Learning & Productivity App

SkillUp is a cross-platform application developed with **Flutter** and **Supabase** to help users organize their daily tasks, discover learning resources, and manage their personal learning activities through a modern and intuitive interface.

## Overview

SkillUp combines productivity and self-learning in one application. Users can create an account, manage their tasks, explore educational resources, save their own learning materials, and access their account settings.

## Features

### Authentication & User Account
- User registration with personal information, including name, phone number, email, and password.
- User login using Supabase Authentication.
- Session management and logout.
- Personalized home screen displaying the user's information.
- Account settings and profile-related information.

### Dashboard
- Personalized welcome section.
- Centralized access to the application's main features.
- Navigation drawer for quick access to application screens.
- Clean interface with a consistent blue visual identity.

### Task Management
- Dedicated task management interface.
- Integration with Supabase for storing user-related task data.
- Task organization and tracking through the application's Tasks section.

*The available task operations depend on the current implementation of `tasks_page.dart`.*

### Learning Hub
- Catalog of learning resources covering topics such as Flutter, Python, SQL, Git, networking, and REST APIs.
- Search and filtering of learning resources.
- Personal resource collection for saving useful learning materials.
- Resource categorization and type selection.
- Progress tracking for personal learning resources.
- Resource information, including title, description, URL, and estimated duration.
- Supabase integration for storing personal resources associated with the authenticated user.

### Settings
- Dedicated settings screen.
- Access to account information.
- Centralized access to user-related application settings.

### User Interface
- Material Design components.
- Responsive layouts using Flutter widgets.
- Cards, navigation drawer, dialogs, and reusable interface components.
- Consistent colors, spacing, and typography.
- Designed for a clear and organized user experience.

## Technologies & Tools

| Category | Technologies |
|---|---|
| Framework | Flutter |
| Programming Language | Dart |
| Backend as a Service | Supabase |
| Authentication | Supabase Auth |
| Database | PostgreSQL |
| Database Access | Supabase Flutter SDK |
| UI | Material Design |
| IDE | Visual Studio Code |
| Version Control | Git and GitHub |
| Target Platforms | Android, iOS, and Flutter-supported platforms |

## Architecture

SkillUp uses Flutter for the client application and Supabase for backend services.

```text
                  SkillUp Application
                          |
                  Flutter / Dart
                          |
             +------------+------------+
             |            |            |
          Dashboard     My Tasks    Learning Hub
             |            |            |
             +------------+------------+
                          |
                    Supabase SDK
                          |
             +------------+------------+
             |                         |
       Supabase Auth              PostgreSQL
       User accounts          Tasks and resources
```

Supabase Authentication manages user identity and sessions, while PostgreSQL stores application data. Database access policies should ensure that authenticated users can access only their own private records.

## Project Structure

The following structure illustrates the main application screens. Adapt the paths if your project uses a different organization.

```text
lahlou_app/
├── lib/
│   ├── main.dart
│   └── screens/
│       ├── login_page.dart
│       ├── register_page.dart
│       ├── home_page.dart
│       ├── tasks_page.dart
│       ├── learning_hub_page.dart
│       └── settings_page.dart
├── assets/
├── pubspec.yaml
├── pubspec.lock
└── README.md
```

## Installation & Setup

### Prerequisites

Install and configure the following tools:

- Flutter SDK
- Dart SDK (included with Flutter)
- Visual Studio Code or Android Studio
- Git
- A Supabase account
- An Android emulator, iOS simulator, or compatible device

### 1. Clone the Repository

```bash
git clone https://github.com/lahlou4chaimaa/FlutterApp.git
cd FlutterApp
```

### 2. Install Dependencies

Run the following command from the project root:

```bash
flutter pub get
```

Check that Flutter is correctly configured:

```bash
flutter doctor
```

### 3. Configure Supabase

Create a project in [Supabase](https://supabase.com/).

In your `main.dart`, initialize Supabase using your project URL and publishable key (or legacy anon key, if applicable):

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_PUBLISHABLE_OR_ANON_KEY',
);
```

Replace the placeholders with your own project credentials.

**Security:** Never commit service-role keys, database passwords, or other privileged credentials to a public repository. Use Row Level Security (RLS) policies for tables containing user-specific data.

### 4. Configure the Database

Create the database tables required by the application's features in the Supabase SQL Editor.

For example, the Learning Hub's personal resources can use a table named `learning_items` with fields such as:

- `id`: unique resource identifier.
- `user_id`: identifier of the owning authenticated user.
- `title`: resource title.
- `description`: optional description.
- `category`: resource category.
- `resource_url`: resource link.
- `resource_type`: resource type.
- `duration_minutes`: estimated learning duration.
- `progress`: learning progress percentage.
- `created_at`: creation timestamp.

The Tasks section also requires a `tasks` table compatible with the fields used in `tasks_page.dart`.

Enable RLS and configure policies that restrict each user to their own records. The database schema and policies must match the application's actual queries.

### 5. Run the Application

Start an emulator or connect a compatible device, then run:

```bash
flutter run
```

To run the application in Chrome, if Flutter Web is configured:

```bash
flutter run -d chrome
```

## Development Workflow

Useful Flutter commands:

```bash
# Install or update dependencies
flutter pub get

# Analyze the source code
flutter analyze

# Run automated tests
flutter test

# Start the application
flutter run
```

## Future Improvements

Potential extensions include:

- Advanced task filtering and prioritization.
- Notifications and deadline reminders.
- Persistent progress tracking for catalog resources.
- Learning goals and personalized study plans.
- Resource bookmarking and completion history.
- Improved profile customization.
- Additional learning categories and external educational resources.

These are potential improvements, not necessarily implemented features.

## Author

**Chaimaa Lahlou**

Computer Science and Network Engineering Student  
EMSI — École Marocaine des Sciences de l'Ingénieur  
Casablanca, Morocco

## License

This project is available for educational and portfolio purposes. Add a `LICENSE` file if you intend to distribute it under a specific open-source license.
