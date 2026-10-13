# 📱 Cross-Platform Mobile Application (Flutter & Supabase)

An intelligent cross-platform mobile application developed using **Flutter** and **Supabase**. The application integrates user authentication for sign-up and sign-in, along with structured navigation, a user profile page, and a dashboard.

## 🚀 Features

### 🔐 User Authentication
- **User Registration (Sign Up):** Create an account using a full name, phone number, email address, and password.
- **User Login (Sign In):** Authenticate registered users through Supabase Auth.
- **Backend Integration:** Use Supabase to manage authentication and connect to a PostgreSQL database.

### 🎨 User Interface (UI/UX)
- Modern interface following **Material Design** guidelines.
- Side navigation menu (`Drawer`) for quick access to:
  - Home
  - Profile
  - Settings
  - Logout
- Personalized images and visual assets.
- Structured navigation between application screens.

### 📱 Cross-Platform Compatibility
- Designed for Android and iOS.
- Built with Flutter for a consistent user experience across supported platforms.

## 🛠️ Technologies & Tools

- **Framework:** Flutter
- **Programming Language:** Dart
- **Backend & Database:** Supabase, PostgreSQL
- **Authentication:** Supabase Auth
- **Development Tools:** Visual Studio Code, Android Studio
- **Version Control:** Git and GitHub

## 📂 Project Structure

```text
lib/
│
├── main.dart             # Application entry point and Supabase initialization
├── login_page.dart       # User login screen
├── register_page.dart    # User registration screen
└── home_page.dart        # Home screen with navigation drawer and dashboard
```

## ⚙️ Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
cd YOUR-REPOSITORY
```

Replace `YOUR-USERNAME` and `YOUR-REPOSITORY` with your GitHub username and repository name.

### 2. Install Dependencies

Make sure Flutter is installed and configured on your machine, then run:

```bash
flutter pub get
```

### 3. Configure Supabase

Create a project on [Supabase](https://supabase.com/).

In `main.dart`, configure the Supabase connection using your project URL and publishable key (or legacy anon key, if applicable):

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
```

Replace the placeholders with your actual Supabase credentials. Do not commit secret keys or service-role credentials to a public repository.

### 4. Run the Application

Connect an Android or iOS device, or start an emulator, and execute:

```bash
flutter run
```

## 👤 Author

**Chaimaa Lahlou**

Computer Science and Network Engineering Student  
EMSI — École Marocaine des Sciences de l'Ingénieur, Casablanca, Morocco

This project was developed as part of a practical exploration of cross-platform mobile application development, user authentication, database integration, and mobile UI/UX design.

---

*If you find this project useful, feel free to explore the repository and its implementation.*
