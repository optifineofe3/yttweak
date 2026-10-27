# YouTube Plus

A flexible, lightweight enhancer for YouTube on iOS.

## Features

- **Ad Blocking & Background Playback:**
  - Complete ad blocking in player and home feed (banners, sponsored cards, promotional shelves)
  - Background playback for audio and video
  - Automatic suppression of Premium promos and popups

- **Interface Customization:**
  - Navigation bar: remove Cast, Notifications, Search, Voice Search, hide YouTube logo, sticky navbar
  - Tab bar: remove labels, indicators, hide Shorts, Subscriptions, Upload, or Library/You tabs; restore Explore tab
  - Tab Manager: long press on the first tab to quickly toggle the Library/You tab
  - Player controls: hide Autoplay switch, Subtitles button, Next/Previous buttons, fullscreen actions, watermarks, paid promotion badges

- **Shorts Management:**
  - Dedicated Shorts-only mode (double-finger long press to exit)
  - Auto-skip Shorts when finished
  - Hide Shorts shelf in home feed
  - Shorts progress bar/scrubber
  - Fine-grained control over Shorts UI: hide like, dislike, comments, remix, share, avatars, audio track, channel name, and description buttons

- **Player & Playback Enhancements:**
  - Hold-to-speed gesture with customizable speeds (up to 5.0×)
  - Default playback rate setting
  - Preferred video quality for Wi-Fi and Cellular
  - Estimated video end time displayed directly in player bar
  - Portrait fullscreen support
  - Auto-fullscreen and exit fullscreen on video completion

- **Utility & Content Features:**
  - Native iOS share sheet integration
  - Timestamped link copying
  - Avatar downloader: long press avatar to copy or save full-resolution profile photo
  - Post & Comment manager: long press to copy text or export as image
  - Album art fix for regions with restricted CDNs
  - Sideloading compatibility patches (keychain and AppGroup fix)

## Building with GitHub Actions

1. Place your decrypted YouTube IPA inside the repository at `ipa/YouTube.ipa`.
2. Push your changes to GitHub.
3. In your repository on GitHub, navigate to **Actions** -> **Build YouTube Plus**.
4. Click **Run workflow**:
   - Choose any optional tweaks to integrate (YouPiP, YTUHD, YouQuality, Return YouTube Dislikes, DontEatMyContent).
   - Enter your desired version, app name, and bundle ID.
   - Click **Run workflow**.
5. Once the build completes, download your ready-to-install IPA from the **Releases** section.
