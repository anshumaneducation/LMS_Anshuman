# LMS — Firebase Project Migration Guide

This guide walks through moving the Flutter LMS app from its current Firebase
project to a new one, and redeploying it to GitHub Pages.

---

## 1. Clone the repository

Don't just download a ZIP — clone it so you keep git history and can push
changes back later.

```bash
git clone https://github.com/<your-username>/<repo-name>.git
cd <repo-name>
```

## 2. Create the new Firebase project

Before touching any config files, set up the destination project:

1. Go to [console.firebase.google.com](https://console.firebase.google.com) and create a new project.
2. Enable the same products the old project used — typically:
   - **Authentication** (enable the same sign-in providers, e.g. Email/Password, Google)
   - **Firestore Database** (or Realtime Database, whichever the app uses)
   - **Storage**
3. Note the new project's **Project ID** — you'll need it shortly.

> If the old project has Firestore/Storage security rules or indexes you rely
> on, copy them now (Console → Firestore/Storage → Rules) — a fresh project
> starts with default rules, which usually deny all reads/writes.

## 3. Remove the old Firebase configuration

Delete these files so nothing points at the old project:

```
.firebaserc
firebase.json
lib/firebase_options.dart
```

(If your app also has platform-specific config files — `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` — delete those too, since `flutterfire configure` regenerates them.)

## 4. Confirm the Firebase CLI is installed

```bash
firebase --version
```

If it's not installed:

```bash
npm install -g firebase-tools
```

## 5. Log in to Firebase

Use the Google account that has access to the **new** Firebase project.

```bash
firebase login
```

If you're switching accounts, run `firebase logout` first.

## 6. Install the FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

Make sure `flutterfire` is on your PATH. If the terminal can't find it after
this step, add Dart's global bin folder to your PATH:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

## 7. Connect the app to the new Firebase project

This is the step that actually rewires the app — it regenerates
`firebase_options.dart` and the platform config files against the new project.

```bash
flutterfire configure
```

- Select the **new** Firebase project when prompted.
- Select the platforms your app targets (web, android, ios, etc.).
- This recreates `lib/firebase_options.dart` and `.firebaserc` automatically.

## 8. Update dependencies and test locally

```bash
flutter pub get
flutter run -d chrome
```

Confirm login, Firestore reads/writes, and file uploads/downloads all work
against the new project before deploying. Also re-check your Storage CORS
config on the new bucket if you serve files directly via `fetch`/XHR (see
below).

## 9. Push to a new GitHub repository

```bash
git remote remove origin
git remote add origin https://github.com/<your-username>/<new-repo-name>.git
git push -u origin main
```

(Use a **public** repo if you're on GitHub Free — GitHub Pages for private
repos requires GitHub Pro/Team/Enterprise.)

## 10. Enable GitHub Pages via Actions

In the new repo:

1. Go to **Settings → Pages**.
2. Under **Build and deployment → Source**, select **GitHub Actions**.
3. Confirm your workflow file (`.github/workflows/...yml`) has the correct
   `--base-href "/<new-repo-name>/"` in the `flutter build web` step —
   this must match the new repo name exactly, including case.
4. Push to `main` (or run the workflow manually) to trigger the first deploy.

## 11. Update Storage security rules and CORS

- In the new project's Firebase Console, set Storage rules to match the old
  project's access policy (public read, authenticated read, etc.).
- If your app fetches Storage files with a raw `fetch()`/XHR call (rather
  than the SDK's `getDownloadURL()`), configure bucket CORS for the new
  bucket:

  ```bash
  gsutil cors set cors.json gs://<new-bucket-name>
  ```

---

### Quick checklist

- [ ] Cloned repo
- [ ] New Firebase project created, same services enabled
- [ ] Old config files deleted
- [ ] `firebase login` with correct account
- [ ] `flutterfire configure` run against new project
- [ ] App tested locally against new project
- [ ] Pushed to new GitHub repo
- [ ] GitHub Pages set to "GitHub Actions" source
- [ ] `base-href` in workflow matches new repo name
- [ ] Storage rules + CORS configured on new bucket