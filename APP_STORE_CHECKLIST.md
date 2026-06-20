# iOS App Store Submission Checklist

A practical, end-to-end checklist for getting a standard iOS app approved on the
Apple App Store. Work through each section in order. Items marked **(Required)**
are hard gates — your submission will be rejected without them.

---

## 1. Apple Developer Account & Setup

- [ ] **(Required)** Enroll in the [Apple Developer Program](https://developer.apple.com/programs/) ($99/year).
- [ ] Complete enrollment as the correct entity type (Individual vs. Organization). Organizations need a D-U-N-S number.
- [ ] Accept the latest **Paid Apps** / **Free Apps** agreements in App Store Connect (apps cannot be submitted until all agreements are signed).
- [ ] Fill in **tax, banking, and contact** information if you plan to sell apps or in-app purchases.
- [ ] Add team members with appropriate roles if working with others.

## 2. Signing, Identifiers & Capabilities

- [ ] **(Required)** Register a unique **Bundle ID** (e.g. `com.yourcompany.appname`) in the Developer portal.
- [ ] **(Required)** Create a **Distribution certificate** and an **App Store provisioning profile** (Xcode-managed signing handles this automatically).
- [ ] Enable only the **capabilities you actually use** (Push Notifications, Sign in with Apple, iCloud, etc.) — unused entitlements can trigger review questions.
- [ ] Verify the Bundle ID in Xcode matches the one registered in App Store Connect.

## 3. App Store Connect Record

- [ ] **(Required)** Create the app record in [App Store Connect](https://appstoreconnect.apple.com/).
- [ ] **(Required)** Set the **app name** (≤ 30 chars), **subtitle** (≤ 30 chars), and **primary/secondary category**.
- [ ] **(Required)** Write the **description**, **keywords** (≤ 100 chars), and **promotional text**.
- [ ] **(Required)** Provide a **support URL** and (recommended) a **marketing URL**.
- [ ] **(Required)** Set the **price tier** (or Free) and availability by region.
- [ ] Complete the **Age Rating** questionnaire accurately.
- [ ] **(Required as of 2024)** Complete the **App Privacy ("Nutrition Label")** section — declare every data type collected and how it's used.
- [ ] Provide a **Privacy Policy URL** **(Required)** — must be publicly reachable.

## 4. App Metadata & Assets

- [ ] **(Required)** App icon: **1024×1024 px**, no alpha channel, no transparency, no rounded corners (Apple adds them).
- [ ] **(Required)** Screenshots for required device sizes:
  - 6.9" / 6.7" iPhone (current required large size)
  - 6.5" iPhone (if still required for your build target)
  - 13" iPad (only if the app supports iPad)
- [ ] Screenshots show **real in-app content** — no placeholder/lorem-ipsum, no device frames that misrepresent the UI.
- [ ] (Optional but recommended) **App Preview** video (15–30s).
- [ ] Localize metadata and screenshots for each supported language.

## 5. Build & Technical Requirements

- [ ] **(Required)** Built with the **current required Xcode / iOS SDK** (Apple periodically raises the minimum — check the latest requirement before submitting).
- [ ] **(Required)** Set a sensible **Deployment Target** (minimum iOS version) and test on it.
- [ ] **(Required)** Increment **version** (`CFBundleShortVersionString`) and **build number** (`CFBundleVersion`) — build numbers must be unique per upload.
- [ ] Archive a **Release** configuration build (not Debug).
- [ ] **(Required)** Add **usage-description strings** in `Info.plist` for every sensitive resource accessed (camera, photos, location, contacts, microphone, tracking, etc.). Missing strings cause crashes and rejection.
  - `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSLocationWhenInUseUsageDescription`, `NSUserTrackingUsageDescription`, etc.
- [ ] If you track users across apps/websites, implement **App Tracking Transparency** (`ATTrackingManager`) and request permission.
- [ ] Support all targeted **device orientations and screen sizes**; verify on the latest devices and a small device.
- [ ] Verify **Dark Mode** and **Dynamic Type** behave reasonably.
- [ ] Test on a **physical device**, not only the simulator.
- [ ] Remove debug logging, test endpoints, and any hard-coded secrets/keys from the release build.
- [ ] Upload the build via **Xcode Organizer** or **Transporter**; confirm it appears in App Store Connect.

## 6. App Review Guidelines Compliance

- [ ] **No crashes or obvious bugs** — the #1 rejection reason. Run a full smoke test of every flow.
- [ ] App provides **real, lasting value** and isn't a thin wrapper around a website or a duplicate of existing apps.
- [ ] All features are **fully functional** at review time (no "coming soon" / non-working buttons).
- [ ] **Account deletion**: if the app supports account creation, it must offer **in-app account deletion** (Required).
- [ ] **Sign in with Apple**: if you offer any third-party/social login, you must also offer Sign in with Apple (with limited exceptions).
- [ ] **In-App Purchases**: digital goods/subscriptions must use Apple's IAP. Configure IAP products and submit them with the build. Don't link out to external purchase flows where prohibited.
- [ ] **Subscriptions**: clearly disclose price, billing period, and auto-renewal terms; link to Terms of Use (EULA) and Privacy Policy.
- [ ] **Permissions**: only request permissions you use, and explain why in the prompt.
- [ ] **User-generated content**: provide content filtering, a way to report/block, and moderation if applicable.
- [ ] **Login required to browse?** Avoid forcing sign-up before showing value unless the core feature genuinely requires an account.
- [ ] Don't use **private APIs** or non-public frameworks.
- [ ] Respect **intellectual property** — no unauthorized trademarks, logos, or content.

## 7. Pre-Submission (App Store Connect)

- [ ] Select the uploaded **build** for the version.
- [ ] **(Required)** Provide **App Review notes**: explain non-obvious features and how to reach them.
- [ ] **(Required if login exists)** Provide a working **demo account** (username/password) or a way for the reviewer to bypass login.
- [ ] Provide **contact info** for the review team.
- [ ] **Export Compliance**: answer encryption questions (most apps using HTTPS only can declare exemption).
- [ ] **Content Rights**: confirm you have rights to all content shown.
- [ ] **Advertising Identifier (IDFA)**: declare correctly if you use it.
- [ ] Choose release option: **manual release**, **auto-release on approval**, or **scheduled / phased release**.

## 8. Recommended Before You Submit

- [ ] Beta test via **TestFlight** with real users; fix reported issues.
- [ ] Run Xcode's **Accessibility Inspector** and basic VoiceOver checks.
- [ ] Confirm the app **handles no-network / poor-network** gracefully.
- [ ] Verify **deep links / universal links** (if used) work from a cold start.
- [ ] Check **memory and battery** behavior under normal use.
- [ ] Re-read the official [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) — they change frequently.

## 9. After Submission

- [ ] Monitor status in App Store Connect (Waiting for Review → In Review → Approved / Rejected).
- [ ] If **rejected**, read the **Resolution Center** message, fix the specific issue, and reply or resubmit. You can request a call or appeal if you disagree.
- [ ] After approval, **release** (if manual) and monitor crash reports / reviews.
- [ ] Plan for ongoing compliance — Apple raises SDK minimums and policy requirements over time.

---

### Quick "most common rejection reasons" sanity check
1. Crashes / bugs on the reviewer's device.
2. Missing or inaccurate **privacy** info (nutrition label, privacy policy, usage strings).
3. Broken or incomplete features at review time.
4. No working **demo account** for login-gated apps.
5. Missing **in-app account deletion**.
6. Using external payment for digital goods instead of **IAP**.
7. Misleading metadata or screenshots.

> Always verify specifics against Apple's current official documentation before
> submitting — exact SDK versions, required screenshot sizes, and policy details
> change over time.
