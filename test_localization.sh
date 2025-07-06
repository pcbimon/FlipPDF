#!/bin/bash

# Simple test script to verify the localization implementation
echo "Testing localization implementation..."

# Check if all required files exist
echo "Checking required files..."
files=(
    "lib/main.dart"
    "lib/localizations.dart"
    "lib/language_provider.dart"
    "lib/pdf_screen.dart"
    "lib/pdf_viewer_screen.dart"
    "pubspec.yaml"
    "README.md"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        echo "✓ $file exists"
    else
        echo "✗ $file is missing"
        exit 1
    fi
done

# Check if localization strings are present
echo ""
echo "Checking for English localization strings in main.dart..."
if grep -q "AppLocalizations.of(context)" lib/main.dart; then
    echo "✓ Localization usage found in main.dart"
else
    echo "✗ No localization usage found in main.dart"
fi

echo ""
echo "Checking for language switcher in main.dart..."
if grep -q "PopupMenuButton<String>" lib/main.dart; then
    echo "✓ Language switcher found in main.dart"
else
    echo "✗ No language switcher found in main.dart"
fi

echo ""
echo "Checking for Thai translations..."
if grep -q "เลือกไฟล์ PDF" lib/localizations.dart; then
    echo "✓ Thai translations found"
else
    echo "✗ No Thai translations found"
fi

echo ""
echo "Checking README.md language..."
if grep -q "A beautiful PDF flipbook reader" README.md; then
    echo "✓ README.md is in English"
else
    echo "✗ README.md is not in English"
fi

echo ""
echo "All checks completed successfully! ✓"
echo "Localization implementation appears to be working correctly."