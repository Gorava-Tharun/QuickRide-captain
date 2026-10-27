# QuickRide Captain App (`quickride_captain`)

<p align="center">
  <img src="../screenshots/captain_splash_home.png" alt="QuickRide Captain App" width="450" style="border-radius: 8px;" />
</p>

The official driver-partner client for the **QuickRide** on-demand ride-booking ecosystem, built with Flutter, Firebase, and Google Maps.

---

## 🌟 Key Features
- **Captain Onboarding & Document Upload:** Upload Driving Licence (DL), Vehicle Registration (RC), and Aadhaar card for KYC verification.
- **Duty Toggle (Online/Offline):** Seamless toggle synchronizing availability in Cloud Firestore in real time.
- **Real-Time Ride Dispatch Modal:** Pop-up alerts with pickup address, destination, estimated fare, and passenger distance.
- **Turn-by-Turn Route Navigation:** Google Maps polyline directions to passenger pickup and destination.
- **OTP Start Ride Verification:** Secure ride start requiring the passenger's 4-digit code.
- **In-App Messaging:** Communicate directly with the passenger via live chat.
- **Daily & Weekly Earnings Tracker:** Detailed breakdown of total trips, earnings, and passenger ratings.

---

## 📱 Tech Stack
- **Framework:** Flutter 3.x (Dart 3.x)
- **State Management:** Provider
- **Mapping:** `google_maps_flutter`, Geolocator, Google Directions API
- **Backend:** Firebase Authentication, Cloud Firestore, Firebase Cloud Storage

---

## 🚀 Getting Started

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Firebase & Google Maps
- Ensure `android/app/google-services.json` is present.
- Ensure your Google Maps API key is configured in `android/app/src/main/AndroidManifest.xml`.

### 3. Run the App
```bash
flutter run
```

---

## 🧪 Automated Tests
Run the 126 automated unit and widget tests:
```bash
flutter test
```
