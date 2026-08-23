# Drip Drop Admin iOS Target

Use this folder as the starting point for the separate admin app target.

Recommended Xcode setup:

1. Open `DripDrop.xcodeproj`.
2. Add a new iOS App target named `DripDropAdmin`.
3. Set the display name to `Drip Drop Admin`.
4. Set the bundle identifier to `Espineli-LLC.DripDrop.Admin`.
5. Add the three files in this folder to the new target only:
   - `DripDropAdminApp.swift`
   - `AdminRootView.swift`
   - `AdminDashboardView.swift`
6. Add the existing shared source files/models/services needed by the admin target, but do not add `DripDropApp.swift`.
7. Link the same package products as the main app:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
   - `FirebaseStorage`
   - `FirebaseFunctions`
   - `StripePaymentSheet`
   - `StripePayments`
   - `CoreXLSX`
8. Use the existing app resources/Firebase plist setup unless you want a separate Firebase app registration later.

Important: the admin target must have a different bundle identifier from the production app so both apps install side by side on the same device.
