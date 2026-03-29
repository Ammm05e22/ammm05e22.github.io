# Supabase Starter — iOS SwiftUI

A production-ready iOS starter template with **SwiftUI**, **Supabase Auth**, and **MVVM architecture** targeting **iOS 26**.

## Features

- **Native iOS 26 UI**: Uses standard SwiftUI controls (`Form`, `.borderedProminent` buttons, `.roundedBorder` text fields) that automatically adopt Apple's Liquid Glass styling at the system level — no manual glass effects needed
- **Authentication**: Email/password, Apple Sign-In, Google Sign-In via Supabase Auth
- **Session Persistence**: Automatic session restoration on app launch (Supabase Keychain storage)
- **Profile Management**: Username + avatar stored in Supabase (Postgres + Storage)
- **Onboarding Flow**: New users are routed to profile setup before accessing the main app
- **MVVM Architecture**: Clean separation of Models, ViewModels, Views
- **Router Navigation**: Enum-based routing with `NavigationStack` and `NavigationPath`

## Requirements

- Xcode 26+
- iOS 26+
- A [Supabase](https://supabase.com) project

## Setup

### 1. Supabase Project

1. Create a project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the contents of `supabase-schema.sql`
3. Copy your **Project URL** and **anon key** from **Settings → API**

### 2. Configure the App

Open `SupabaseStarter/Config/Supabase+Config.swift` and replace the placeholders:

```swift
static let url = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
static let anonKey = "YOUR_ANON_KEY"
```

### 3. OAuth Setup (Optional)

**Apple Sign-In:**
1. Enable Apple provider in Supabase Dashboard → Authentication → Providers
2. Add "Sign in with Apple" capability in Xcode → Signing & Capabilities

**Google Sign-In:**
1. Create OAuth credentials in Google Cloud Console
2. Enable Google provider in Supabase Dashboard → Authentication → Providers
3. Add your Google Client ID and Secret

**Redirect URL:**
In Supabase Dashboard → Authentication → URL Configuration, add:
```
supabasestarter://auth-callback
```

### 4. Open in Xcode

**Option A — XcodeGen (recommended):**
```bash
brew install xcodegen
cd SupabaseStarter
xcodegen generate
open SupabaseStarter.xcodeproj
```

**Option B — Swift Package:**
```bash
cd SupabaseStarter
open Package.swift
```
Xcode will resolve the `supabase-swift` dependency automatically.

### 5. Run

Select a simulator or device, then **Cmd+R**.

## Project Structure

```
SupabaseStarter/
├── App/                    # @main entry point, Info.plist
├── Config/                 # Supabase client configuration
├── Models/                 # Data models (Profile)
├── Services/               # AuthService, ProfileService
├── ViewModels/             # AuthViewModel, OnboardingViewModel, ProfileViewModel
├── Views/
│   ├── Auth/               # LoginView, SignUpView
│   ├── Onboarding/         # OnboardingView
│   ├── Main/               # HomeView, ProfileView
│   └── Components/         # OAuthButton, LoadingView
├── Navigation/             # Router + Route enum
└── Assets.xcassets/
```

## Auth Flow

```
App Launch
  → SplashView (checks for saved session)
    → Session found + profile exists → HomeView
    → Session found + no profile    → OnboardingView → HomeView
    → No session                    → LoginView
      → Sign In                     → HomeView
      → Sign Up                     → OnboardingView → HomeView
```

## License

MIT
