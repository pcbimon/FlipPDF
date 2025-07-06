# PDF Flipbook

[![Build APK](https://github.com/pcbimon/FlipPDF/actions/workflows/build-apk.yml/badge.svg)](https://github.com/pcbimon/FlipPDF/actions/workflows/build-apk.yml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/pcbimon/FlipPDF)](https://github.com/pcbimon/FlipPDF/releases)
[![Flutter](https://img.shields.io/badge/Flutter-3.32.4-blue.svg)](https://flutter.dev/)

A beautiful PDF flipbook reader application with 3D page flip animations and smooth performance.

## 🌟 Features

- **PDF File Selection**: Support for selecting PDF files from device storage
- **3D Flipbook Animation**: Display PDFs with realistic 3D page flip effects
- **Pre-processing**: Convert all PDF pages to widgets before display for smooth performance
- **Page Status Display**: Show current page number and total pages
- **Beautiful UI**: Designed for easy use with an elegant interface
- **Multi-language Support**: English (default) and Thai language options
- **Screen Lock Prevention**: Keeps screen on during reading
- **Quality Settings**: Multiple PDF rendering quality options
- **Cache Management**: Memory and disk cache options for optimal performance

## 🚀 How It Works

1. **File Selection**: User selects a PDF file from device storage
2. **Processing**: 
   - Read the PDF file
   - Convert each page to an image
   - Create widgets for each page
   - Store all widgets in a List<Widget>
3. **Display**: Use PageFlip widget to display as a flipbook

## 🎯 Getting Started

### Prerequisites
- Flutter SDK (>=3.8.1)
- Android Studio or VS Code
- Android device or emulator

### Installation from Source
1. Clone the repository:
   ```bash
   git clone https://github.com/pcbimon/FlipPDF.git
   cd FlipPDF
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## 📱 How to Use

1. Open the app
2. Tap "Select PDF File" button
3. Choose a PDF file from your device
4. Tap "Open PDF Flipbook" button
5. Wait for the system to process the PDF
6. Once completed, it will display as a flipbook
7. Use touch gestures to flip pages
8. Use the language switcher in the top-right to change languages

## 🏗️ Code Structure

### Main Files

- `main.dart`: Main screen and file selection functionality
- `pdf_screen.dart`: PDF flipbook display screen
- `pdf_processor.dart`: PDF processing and widget creation
- `pdf_page.dart`: Widget for displaying individual PDF pages
- `localizations.dart`: Localization system for multi-language support
- `language_provider.dart`: Language state management

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.8           # iOS style icons
  page_flip: ^0.2.1                 # Flipbook effect
  file_picker: ^8.1.3               # File selection
  flutter_pdfview: ^1.3.2           # PDF reading (fallback)
  path_provider: ^2.1.4             # Path management
  pdf: ^3.11.0                      # PDF processing
  pdfx: ^2.6.0                      # Enhanced PDF handling
  crypto: ^3.0.3                    # Cryptographic functions
  wakelock_plus: ^1.2.8             # Screen wake lock
  shared_preferences: ^2.2.2        # Local storage
  provider: ^6.1.1                  # State management
  intl: ^0.19.0                     # Internationalization
```

## ⚠️ Important Notes

- Processing large PDF files may take some time
- The app shows a loading indicator during processing
- All widgets are created and stored in memory before display
- Image resolution is set to 150 DPI for clarity and performance balance
- Language preference is saved locally and persists between app sessions

## 🔧 Future Development

Potential enhancements:
- Zoom in/out functionality
- Text search capabilities
- Bookmark features
- Sharing options
- Brightness adjustment
- Annotation support
- Cloud storage integration

## 🚀 GitHub Actions & Releases

This project uses GitHub Actions for automated building and release creation.

### Creating a New Release
1. Update version in `pubspec.yaml`
2. Create and push a tag in the format `vX.X.X`:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. GitHub Actions will automatically:
   - Build APK for Android (multiple architectures)
   - Build Web version
   - Build Windows executable
   - Create GitHub Release with downloadable files

### Available Workflows
- **Build APK**: Build Android APK only when version tag is created
- **Build Multi-Platform**: Build for all platforms (Android, Web, Windows)

### Downloads
Download the latest version from [GitHub Releases](https://github.com/pcbimon/FlipPDF/releases)

## 🌐 Localization

The app supports multiple languages:
- **English** (default)
- **Thai** (ไทย)

Language can be switched using the language selector in the app bar. The selected language preference is automatically saved and restored when the app is reopened.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

## GitHub Repository
🔗 [https://github.com/pcbimon/FlipPDF](https://github.com/pcbimon/FlipPDF)
