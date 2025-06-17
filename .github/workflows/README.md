# GitHub Actions Workflows

This directory contains GitHub Actions workflows for automated building and releasing of the PDF Flipbook application.

## Workflows

### 1. Build APK (`build-apk.yml`)
- **Trigger**: When a version tag is pushed (format: `vX.X.X`)
- **Purpose**: Build Android APK and create a GitHub release
- **Outputs**: 
  - Single APK file attached to GitHub release
  - APK artifact for download

### 2. Build Multi-Platform (`build-multi-platform.yml`)
- **Trigger**: 
  - When a version tag is pushed (format: `vX.X.X`)
  - Manual trigger via GitHub Actions UI
- **Purpose**: Build for multiple platforms and create comprehensive release
- **Outputs**:
  - Android APKs (multiple architectures)
  - Web build (ZIP file)
  - Windows build (ZIP file)
  - Comprehensive GitHub release with all platforms

## How to Use

### Creating a Release

1. **Update Version**: Make sure your `pubspec.yaml` has the correct version
2. **Create and Push Tag**:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. **Wait for Build**: GitHub Actions will automatically:
   - Build the applications
   - Run tests
   - Create a GitHub release
   - Upload build artifacts

### Tag Format
- Use semantic versioning: `vMAJOR.MINOR.PATCH`
- Examples: `v1.0.0`, `v1.2.3`, `v2.0.0`

### Manual Trigger
For the multi-platform workflow, you can also trigger builds manually:
1. Go to GitHub Actions tab
2. Select "Build Multi-Platform" workflow
3. Click "Run workflow"
4. Choose the branch and click "Run workflow"

## Build Requirements

### Android
- Java 17
- Flutter 3.24.0 (stable)
- Builds split APKs for different architectures:
  - arm64-v8a (64-bit ARM)
  - armeabi-v7a (32-bit ARM)
  - x86_64 (64-bit x86)

### Web
- Flutter 3.24.0 (stable)
- Base href configured for GitHub Pages deployment
- Outputs web build as ZIP file

### Windows
- Windows runner
- Flutter 3.24.0 (stable)
- Creates ZIP file with Windows executable

## Artifacts Retention
- All artifacts are kept for 30 days
- Release assets are permanent until manually deleted

## Permissions Required
The workflows require:
- `contents: write` (for creating releases)
- `actions: write` (for uploading artifacts)

These are automatically provided by `GITHUB_TOKEN`.

## Troubleshooting

### Build Failures
1. Check the GitHub Actions logs
2. Ensure all dependencies are properly specified in `pubspec.yaml`
3. Verify Flutter and Dart versions compatibility

### Missing APK Files
- The multi-platform workflow builds split APKs
- If a specific architecture APK is missing, check the build logs
- Some devices may not be compatible with certain architectures

### Web Build Issues
- Ensure web-specific configurations are correct
- Check for web-incompatible dependencies
- Verify base href configuration

## Example Usage

```bash
# Create and push a new version tag
git tag v1.0.0
git push origin v1.0.0

# This will trigger the workflows and create:
# - GitHub release with description
# - Android APK files
# - Web build ZIP
# - Windows build ZIP
```

## Release Notes Template
The workflows automatically generate release notes with:
- Feature highlights
- Installation instructions for each platform
- Usage instructions
- Download links for all builds
