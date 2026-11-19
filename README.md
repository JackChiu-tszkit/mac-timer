# Timer

A lightweight countdown timer for Mac. Open it, start a timer in one click, and get a local sound plus an on-screen alert when time runs out. No account, no network, and no personal data collection.

The app is a native SwiftUI application. It is the Mac counterpart of the Windows timer, with the same countdown behavior and a menu bar item in place of the Windows notification area icon.

## Features

- Set hours, minutes, and seconds. Start, pause, resume, and reset.
- Quick presets: 1, 5, 10, 15, 25, 30, and 60 minutes. Choosing a preset starts it immediately.
- A progress ring and a large digital countdown. The default duration is 25:00.
- Three local alert sounds (Bell, Chime, and Soft), volume, mute, preview, and an optional repeat until the alert is dismissed.
- An in-app Time's Up window when the countdown finishes. A macOS notification is also sent when the system allows it.
- The menu bar item stays available while the window is hidden. The countdown keeps running. The menu can open the window, start or pause, reset, or quit.
- Closing the window quits by default. Settings can change that so closing or minimizing hides the window and leaves the timer in the menu bar.
- Optional always-on-top, a compact floating timer, and light, dark, or system theme.
- Optional launch at login. Settings are stored locally in `~/Library/Application Support/Timer/settings.json`.

## Keyboard

- `Space`: start or pause, unless focus is in a time field.
- `R`: reset, unless focus is in a time field.
- `Esc`: close Settings or dismiss the time-up alert. Return also dismisses the time-up alert.

## Timer accuracy

The countdown does not subtract one second on each UI tick. The engine uses a monotonic clock and derives the remaining time from elapsed time. UI refresh only redraws the display. Time spent paused is not counted. The completion event fires once per run.

System sleep pauses the countdown. The app uses `SuspendingClock`, which does not advance while the Mac is suspended, so the timer continues from the remaining time at the moment sleep began. Sleep time is neither subtracted nor added. `SleepPolicy` documents this behavior, and tests cover the policy.

## Requirements

- macOS 15 or later
- Development: Xcode 16 or later

The built app is a normal Mac application. It does not need a separate runtime install.

## Build, test, and package

On a Mac, from the repository root:

```bash
chmod +x scripts/package.sh
./scripts/package.sh
```

The script runs the tests, builds a Release `Timer.app`, and creates `dist/Timer.dmg`. The disk image contains the app and a shortcut to the Applications folder.

Build and test only:

```bash
xcodebuild -project MacTimer.xcodeproj -scheme Timer -configuration Debug -destination 'platform=macOS' test
```

Open `MacTimer.xcodeproj` in Xcode and press Run to launch the app while developing.

The project is ad-hoc signed so it can build without an Apple Developer team. The first time you open `Timer.app` outside Xcode, macOS may ask you to confirm it in System Settings under Privacy & Security. For a wider distribution, sign and notarize the app with your own Apple Developer account in Xcode.

Launch at login uses `SMAppService`. macOS only enables that after the app has a stable location, typically `/Applications`.

## Release

Pushing a tag named `v*` runs GitHub Actions on a Mac. The workflow tests the app, builds `Timer.app`, and publishes `Timer.dmg` on the GitHub Release for that tag.

## Installation

Open `Timer.dmg`, then drag Timer to Applications. Launch Timer from Applications or Spotlight. The menu bar shows a timer icon. While a countdown is running or paused, the menu bar also shows the remaining time.

Closing the main window quits. The minimize button, or the close button when Settings is set to Hide in Menu Bar, hides the window and leaves the countdown running.

## Project layout

```
MacTimer/
├── MacTimer/                 SwiftUI app, timer engine, sounds, and settings
├── MacTimerTests/            engine, settings, tone, and sleep-policy tests
├── MacTimer.xcodeproj/
├── scripts/package.sh        test, Release build, and DMG
└── README.md
```

## Verification

Checked on 2026-11-19.

GitHub Actions, on Xcode 26.6, ran the test suite and built `Timer.dmg` for release v1.0.0. The suite finished with 26 tests and 0 failures. The disk image is attached to that release.

These items were not manually checked:

- alert sound playback
- the macOS notification banner
- menu bar clicks
- sleep and wake
- launch at login
- installing the disk image on a physical Mac
