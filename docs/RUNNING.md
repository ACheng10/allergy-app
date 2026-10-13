# Running the app (for someone who has never used Xcode)

ELI5: Xcode is to Swift what PyCharm plus the Python interpreter is to Python, and the Simulator is a pretend iPhone that runs in a window on your Mac.

## 1. Install Xcode (once)

1. Open the **App Store** on your Mac, search for **Xcode**, install it. It is a very large download, so start it on good Wi-Fi.
2. Open Xcode once. When it asks which platforms to install, tick **iOS**. That download includes the iPhone Simulator.
3. If Xcode says your macOS is too old, update macOS first. This project needs Xcode 16 or newer.

## 2. Get the code

In Terminal:

```
git clone https://github.com/ACheng10/allergy-app.git
cd allergy-app
git checkout claude/ios-v1-scaffold-d3m04w   # only until this branch is merged into main
open AllergyApp/AllergyApp.xcodeproj
```

The last line opens the project in Xcode. (Double-clicking `AllergyApp.xcodeproj` in Finder does the same.)

## 3. Run it in the Simulator

1. At the top of the Xcode window, the middle bar shows **AllergyApp > [a device]**. Click the device part and pick an iPhone, for example **iPhone 16**.
2. Press **Cmd+R** (or the triangle Play button at the top left).
3. The first build takes a minute or two. A pretend iPhone appears and the app opens.
4. Try it: pick **Switzerland**, then **French**, tick **Peanuts**, tap **Done**, then **Show to staff**.

What you should see: everything is in English with a "beta" warning, because there are no translations yet. Screen brightness does not change in the Simulator; it does on a real phone.

To stop the app, press **Cmd+.** (Cmd and full stop).

## 4. If the build fails

Red errors show in the left panel (the triangle-with-exclamation tab, or **Cmd+5**). Copy the error text and paste it into the project thread. This code was written on a machine without Xcode, so a first-run error is possible; CI builds it on a Mac to catch most of them.

## 5. Run it on your own iPhone (optional)

1. Xcode menu > **Settings** > **Accounts** > **+** > **Apple ID**, and sign in. A free Apple ID is enough for this step.
2. In the left file list click the blue **AllergyApp** icon at the top, then the **AllergyApp** target, then the **Signing & Capabilities** tab. Set **Team** to your name (Personal Team).
3. If Xcode complains the bundle identifier is taken, change `com.acheng10.allergycard` to something unique, like `com.yourname.allergycard`.
4. Plug in your iPhone with a cable and tap **Trust** on the phone.
5. On the iPhone: **Settings > Privacy & Security > Developer Mode**, switch it on, and let it restart.
6. Back in Xcode, pick your iPhone in the device menu and press **Cmd+R**.
7. The first time, the iPhone may refuse to open it. Go to **Settings > General > VPN & Device Management**, tap your developer profile, and trust it.

With a free Apple ID, apps you install this way stop opening after 7 days. Press Cmd+R again to refresh. The paid $99/year developer account removes that limit and is needed for TestFlight, iCloud sync and the App Store.

## 6. Changing phrases or languages

Edit the CSVs in `data/`, then in Terminal from the repo folder:

```
python3 tools/build_phrasebook.py
```

Then press Cmd+R in Xcode again. The app only ever reads `AllergyApp/AllergyApp/Resources/phrasebook.json`, which that script writes.

## Handy shortcuts

| Keys | Does |
| --- | --- |
| Cmd+R | Build and run |
| Cmd+. | Stop |
| Cmd+B | Build only (check for errors) |
| Cmd+Shift+K | Clean (try this when something weird happens) |
| Cmd+Shift+O | Open any file by name |
