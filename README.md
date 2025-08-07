# Dasy CSAT - iOS Educational App

A comprehensive iOS application for CSAT (College Scholastic Ability Test) exam preparation, featuring interactive PDF viewing, annotation tools, and OMR marking capabilities.

## Features

- 📚 **CSAT Exam Materials**: Access to official CSAT exam papers and practice tests
- ✏️ **Interactive Annotations**: Draw and annotate directly on PDF documents
- 🎯 **OMR Marking**: Digital answer sheet marking with automatic grading
- 🔍 **Advanced Filtering**: Filter by subject, category, year, and grade level
- 📱 **iPad Optimized**: Designed specifically for iPad with Apple Pencil support
- 💾 **Local Storage**: All annotations and data stored locally on device

## Technical Stack

- **Language**: Swift 5.0
- **Framework**: UIKit, PDFKit, PencilKit
- **Architecture**: MVVM with Coordinator pattern
- **Networking**: URLSession with async/await
- **Storage**: Local file system for PDF caching
- **Target**: iOS 13.0+ (iPad optimized)

## Project Structure

```
dasy-csat-ios/
├── App/                    # App delegate, scene delegate, Info.plist
├── Coordinators/          # Navigation coordination
├── Services/              # API, PDF, and grading services
├── ViewControllers/       # Main view controllers
├── Views/                 # Custom UI components
├── Extensions/            # Swift extensions
└── Resources/             # Assets, storyboards, launch screen
```

## Legal Documents

- [Privacy Policy](https://yeboc-tech.github.io/dasy-csat-ios/policies/privacy-policy.html)
- [Terms of Service](https://yeboc-tech.github.io/dasy-csat-ios/policies/terms-of-service.html)

## Content Sources

This app uses publicly available CSAT materials from KICE (한국교육과정평가원) for educational purposes. All content is used in accordance with educational fair use principles.

## Development

### Requirements
- Xcode 14.0+
- iOS 13.0+
- iPad device or simulator for testing

### Setup
1. Clone the repository
2. Open `dasy-csat-ios.xcodeproj` in Xcode
3. Select your development team
4. Build and run on iPad simulator or device

### API Configuration
The app connects to a production API at `https://api.dasy-csat.y3c.kr` for educational content delivery.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contact

- Email: yeboc.tech@gmail.com
- GitHub: [@your-username](https://github.com/your-username)

## App Store

Available on the App Store: [Dasy CSAT](https://apps.apple.com/app/dasy-csat/id[your-app-id])
