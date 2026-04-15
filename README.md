# ImgZen

[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/LinkAndreas/ImgZen/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build and Deploy](https://github.com/LinkAndreas/ImgZen/actions/workflows/deploy.yml/badge.svg)](https://github.com/LinkAndreas/ImgZen/actions/workflows/deploy.yml)
![Swift](https://img.shields.io/badge/swift-F54A2A?style=for-the-badge&logo=swift&logoColor=white)
![Xcode](https://img.shields.io/badge/Xcode-007ACC?style=for-the-badge&logo=Xcode&logoColor=white)

A modern, native image conversion application built with SwiftUI. Convert images between various formats with support for both lossless and lossy compression, batch processing, and an intuitive user interface.

## Features

- 🖼️ **Multiple Format Support** - Convert between PNG, JPEG, TIFF, BMP, HEIC, and WebP formats
- 📦 **Batch Processing** - Convert multiple images at once with progress tracking
- 🎨 **Lossless & Lossy Formats** - Choose between preserving quality or reducing file size
- ⚙️ **Compression Quality Control** - Adjustable compression quality for lossy formats
- 📱 **Native User Experience** - Built with SwiftUI for a modern, responsive interface
- 🔄 **Multiple Input Sources** - Import images from Photos library or file system
- 📤 **Easy Sharing** - Share converted images directly from the app
- 🔒 **Privacy First** - No photo library permissions required, all processing done locally
- 🎯 **Clean Architecture** - Well-structured codebase following domain-driven design principles

## Privacy

ImgZen is designed with privacy as a core principle:

- **No Photo Library Permission Required** - The app uses the modern PHPicker API, which means you only grant access to the specific images you select. The app never has access to your entire photo library.

- **100% Local Processing** - All image conversions happen entirely on your device. Your images are never sent to any server or cloud service.

- **No Data Collection** - The app doesn't collect, store, or transmit any personal data or usage analytics.

Your images stay on your device, under your control, at all times.

## Supported Formats

### Lossless Formats
- **PNG** - Portable Network Graphics
- **TIFF** - Tagged Image File Format
- **BMP** - Bitmap Image File

### Lossy Formats
- **JPEG** - Joint Photographic Experts Group
- **HEIC** - High Efficiency Image Container
- **WebP** - Modern web image format

## Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/yourusername/ImgZen.git
cd ImgZen
```

2. Open the project in Xcode:
```bash
open ImgZen.xcodeproj
```

3. Build and run the project (⌘R) or use Product → Run in Xcode

### Dependencies

The project uses Swift Package Manager for dependencies:
- SDWebImageWebPCoder (for WebP format support)

Dependencies are automatically resolved when opening the project in Xcode.

## Usage

1. **Select Images**
   - Click "Add Images" to import from Photos library or file system
   - Select multiple images for batch conversion

2. **Choose Format**
   - Select your desired output format from the format picker
   - For lossy formats (JPEG, HEIC, WebP), adjust compression quality if needed

3. **Convert**
   - Click the "Convert" button to start the conversion process
   - Monitor progress in real-time

4. **Share**
   - View converted images in the output screen
   - Share individual images or all images at once using the share sheet

## Project Structure

```
ImgZen/
├── Domain/                    # Core business logic
│   ├── ImageConversion/       # Image format definitions and conversion logic
│   └── Services/             # Domain services (conversion, storage, etc.)
├── Infrastructure/           # Infrastructure layer
│   └── Repository/           # Data repositories
├── Presentation/             # Presentation layer
│   └── ImageFormat+*.swift   # Format presentation extensions
├── UI/                       # User interface
│   ├── Components/           # Reusable UI components
│   ├── Screens/              # Main app screens
│   └── WindowManager/        # Window management utilities
├── Extensions/               # SwiftUI extensions
├── Logging/                  # Logging utilities
└── Resources/                # Assets and localization
```

## Architecture

The project follows a clean architecture pattern with clear separation of concerns:

- **Domain Layer**: Core business logic, models, and services
- **Infrastructure Layer**: Data access, repositories, and external dependencies
- **Presentation Layer**: View models and presentation logic
- **UI Layer**: SwiftUI views and components

## Testing

The project includes comprehensive unit tests using Swift Testing framework. Run tests using:

- **Xcode**: Press `⌘U` or select Product → Test
- **Command Line**: `xcodebuild test -scheme ImgZen`

Test coverage includes:
- Domain models and business logic
- Image conversion functionality
- Service layer components
- UI components and presentation logic

See [ImgZenTests/README.md](ImgZenTests/README.md) for detailed test documentation.

## Development

### Git Flow

This project follows Git Flow workflow:
- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/*` - Feature development branches
- `release/*` - Release branches

### Commit Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/) specification:
- `feat:` - New features
- `fix:` - Bug fixes
- `chore:` - Maintenance tasks
- `test:` - Test additions or changes
- `docs:` - Documentation updates

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes following the project's code style
4. Add tests for new functionality
5. Commit your changes using conventional commits
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI and native macOS frameworks
- WebP support powered by [SDWebImageWebPCoder](https://github.com/SDWebImage/SDWebImageWebPCoder)
- Licenses generated using [LicensePlist](https://github.com/mono0926/LicensePlist)

```bash
license-plist --output-path ./Settings.bundle --add-version-numbers
```
---

Made with ❤️ using Swift and SwiftUI

