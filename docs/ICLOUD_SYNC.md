# Turning on iCloud sync

The plan says: no sign-in, data on the phone, synced through the user's own iCloud. The profile model is already shaped for that (every field has a default, no unique constraints, which CloudKit requires). Sync is **off** right now for one reason: iCloud needs a **paid** Apple Developer account ($99/year). A free Personal Team cannot add the iCloud capability.

When you have the paid account:

1. Xcode > project > **AllergyApp** target > **Signing & Capabilities** > **+ Capability** > **iCloud**. Tick **CloudKit** and add a container, e.g. `iCloud.com.yourname.allergycard`.
2. **+ Capability** > **Background Modes**, tick **Remote notifications** (lets changes arrive in the background).
3. In `AllergyApp/AllergyApp/AllergyApp.swift` change

   ```swift
   let config = ModelConfiguration(cloudKitDatabase: .none)
   ```

   to

   ```swift
   let config = ModelConfiguration(cloudKitDatabase: .automatic)
   ```

4. Test on two devices signed into the same iCloud account. The Simulator is unreliable for sync.

Before release, deploy the CloudKit schema to Production in the CloudKit Console, or sync silently fails for App Store users.

Rule for future changes to `AllergyProfile`: only **add** fields, always with a default. Renaming or deleting a field breaks sync for people on older versions.
