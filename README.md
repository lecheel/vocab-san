# Vocab-San: A Dynamic Vocabulary Learning App

**Vocab-San** is a sleek, cross-platform vocabulary learning application built with Flutter. It's designed for serious learners who want to use custom, dynamic vocabulary lists for practice, with a special focus on Japanese.

The app features a modern dark-themed UI, full audio support via Text-to-Speech, configurable practice sessions, and intelligent caching. It's built to be flexible, sourcing its vocabulary packs from a dynamic online manifest file, which can be customized by the user.

 
*(**Action:** You should replace this with an actual screenshot of your app)*

## ✨ Features

-   **Dynamic Vocabulary Packs**: Downloads a list of available vocabulary packs from a remote `manifest.json` file. Users can add new vocabulary without updating the app.
-   **Customizable Source**: Power-users can change the manifest URL in the app's settings to point to their own custom-hosted vocabulary collections.
-   **Offline First**: Once a vocabulary pack is downloaded, all its JSON files and audio are stored locally for instant, offline access.
-   **Audio Playback**: Crystal-clear pronunciation for both Japanese and English words.
    -   **On Desktop (macOS/Windows/Linux):** Powered by the `etalk` TTS engine. If an audio file is missing, it can be generated on-the-fly (requires `etalk` CLI to be installed).
    -   **On Mobile (Android/iOS):** Plays pre-generated audio files included in the downloaded vocabulary packs.
-   **Configurable Auto-Play**: Set up hands-free practice sessions by configuring the number of repetitions for each language and the delay between them.
-   **Modern UI**: A sleek, responsive dark theme inspired by Material Design.
-   **Full Keyboard Control**: Navigate cards, play audio, and manage files without leaving the keyboard.
-   **Cross-Platform**: A single codebase that runs on Android, iOS, Windows, macOS, and Linux.

## 🚀 Getting Started

### 1. User Guide

1.  **Launch the App**: On first launch, the "Packs" tab will be empty.
2.  **Select a Pack**: The app will automatically fetch a list of available vocabulary packs. Tap on a pack from the "Available for Download" list.
3.  **Download**: The app will download the selected pack (a `.zip` file containing a vocabulary `json` and all its `.mp3` audio files) and unzip it.
4.  **Load a List**: The downloaded list will now appear under "Downloaded Lists". Tap it to load the vocabulary.
5.  **Practice**: Navigate to the "Practice" tab to begin studying with flashcards and audio.
6.  **Configure**: Go to the "Playback" and "App Settings" tabs to customize your experience.

### 2. Developer Setup

#### Prerequisites
-   **Flutter SDK**: Ensure you have a recent version of the Flutter SDK installed.
-   **(Optional for Desktop)** **`etalk` CLI**: For on-the-fly audio generation on desktop, the `etalk` command-line tool must be installed and available in your system's `PATH`.

#### Installation
1.  **Clone the repository:**
    ```bash
    git clone https://github.com/lecheel/vocab-san.git
    cd vocab-san
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    # To run on a connected mobile device or emulator
    flutter run

    # To run on macOS desktop
    flutter run -d macos
    ```

## 📦 Vocabulary Pack Specification

To add your own content, you need to create a vocabulary pack and update the manifest file.

### 1. Audio & JSON Structure

Your vocabulary `.json` files must be an array of objects. Each object should contain at least a `word` (Japanese) and `english` key.

**Example `n5_vocab.json`:**
```json
[
    {
        "word": "お決まりでしょうか",
        "romaji": "O kimari deshou ka",
        "english": "Have you decided (on your order)?"
    },
    {
        "word": "少々",
        "romaji": "Shōshō",
        "english": "A little; a moment"
    }
]
```

### 2. Creating the `.zip` Pack

1.  **Generate Audio:** Use a compatible tool (like the `etalk` CLI) to generate the `.mp3` files for every `word` and `english` phrase. The tool must produce filenames in the format `hash_<16_char_sha256_hash>_<lang_code>.mp3`.
    ```bash
    # Example using a compatible CLI
    etalk --inputjson n5_vocab.json --savetag
    ```
    This will produce an `assets` folder containing all the required audio files.

2.  **Create the ZIP:** Create a `.zip` archive containing your `.json` file and all its generated `.mp3` files.
    -   `n5_essentials.zip`
        -   `n5_vocab.json`
        -   `hash_a1b2c3d4e5f6g7h8_ja.mp3`
        -   `hash_..._en.mp3`
        -   ... and so on

### 3. The `manifest.json` File

This is the central index of all your vocabulary packs. The app downloads this file to know what's available. It must be a JSON array of pack objects.

**Example `manifest.json`:**
```json
[
  {
    "id": "n5_essentials",
    "name": "JLPT N5 Essentials",
    "description": "The most common 100 words for the N5 level.",
    "version": "1.0.1",
    "url": "https://your-server.com/packs/n5_essentials.zip"
  },
  {
    "id": "travel_phrases",
    "name": "Travel & Tourism Phrases",
    "description": "Useful phrases for ordering food and shopping.",
    "version": "1.0.0",
    "url": "https://your-server.com/packs/travel_phrases.zip"
  }
]
```
-   **`id`**: A unique, machine-readable identifier. Used for the local directory name.
-   **`name`**: A human-readable title for the pack.
-   **`description`**: A short description shown in the app.
-   **`version`**: The version number of the pack.
-   **`url`**: The direct, public URL to the `.zip` file.

## ⌨️ Keyboard Shortcuts

-   **`Left` / `Right` Arrow**: Previous / Next vocabulary card.
-   **`Up` / `Down` Arrow**: Play Japanese / English audio.
-   **`Space`**: Play Japanese audio.
-   **`Enter` / `Return`**: Play English audio.
-   **`Ctrl+1/2/3/4`**: Switch between tabs.

## 🤝 Contributing

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/lecheel/vocab-san/issues).

---
