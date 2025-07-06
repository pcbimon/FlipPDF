import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flippdf/localizations.dart';

void main() {
  group('AppLocalizations Tests', () {
    test('English localizations are complete', () {
      final localizations = AppLocalizations(const Locale('en'));
      
      // Test core functionality strings
      expect(localizations.appTitle, equals('PDF Flipbook'));
      expect(localizations.selectPDFFile, equals('Select PDF File'));
      expect(localizations.selectPDFToView, isNotEmpty);
      expect(localizations.selectPDFButton, isNotEmpty);
      expect(localizations.openPDFFlipbook, isNotEmpty);
      
      // Test error messages
      expect(localizations.pdfNotFound, isNotEmpty);
      expect(localizations.cannotProcessPDF, isNotEmpty);
      
      // Test UI elements
      expect(localizations.processing, isNotEmpty);
      expect(localizations.close, isNotEmpty);
      expect(localizations.back, isNotEmpty);
      expect(localizations.yes, isNotEmpty);
      expect(localizations.no, isNotEmpty);
      
      // Test language options
      expect(localizations.language, isNotEmpty);
      expect(localizations.english, isNotEmpty);
      expect(localizations.thai, isNotEmpty);
    });

    test('Thai localizations are complete', () {
      final localizations = AppLocalizations(const Locale('th'));
      
      // Test core functionality strings
      expect(localizations.appTitle, equals('PDF Flipbook'));
      expect(localizations.selectPDFFile, equals('เลือกไฟล์ PDF'));
      expect(localizations.selectPDFToView, isNotEmpty);
      expect(localizations.selectPDFButton, isNotEmpty);
      expect(localizations.openPDFFlipbook, isNotEmpty);
      
      // Test error messages
      expect(localizations.pdfNotFound, isNotEmpty);
      expect(localizations.cannotProcessPDF, isNotEmpty);
      
      // Test UI elements
      expect(localizations.processing, isNotEmpty);
      expect(localizations.close, equals('ปิด'));
      expect(localizations.back, equals('กลับ'));
      expect(localizations.yes, equals('ใช่'));
      expect(localizations.no, equals('ไม่ใช่'));
      
      // Test language options
      expect(localizations.language, equals('ภาษา'));
      expect(localizations.english, equals('English'));
      expect(localizations.thai, equals('ไทย'));
    });

    test('Parameterized strings work correctly', () {
      final englishLocalizations = AppLocalizations(const Locale('en'));
      final thaiLocalizations = AppLocalizations(const Locale('th'));
      
      // Test selectedFile method
      expect(englishLocalizations.selectedFile('test.pdf'), 
             equals('Selected file: test.pdf'));
      expect(thaiLocalizations.selectedFile('test.pdf'), 
             equals('ไฟล์ที่เลือก: test.pdf'));
      
      // Test errorOccurred method
      expect(englishLocalizations.errorOccurred('File not found'), 
             equals('An error occurred: File not found'));
      expect(thaiLocalizations.errorOccurred('File not found'), 
             equals('เกิดข้อผิดพลาด: File not found'));
      
      // Test pageError method
      expect(englishLocalizations.pageError(5, 'Corrupted page'), 
             equals('Error occurred on page 5: Corrupted page'));
      expect(thaiLocalizations.pageError(5, 'Corrupted page'), 
             equals('เกิดข้อผิดพลาดที่หน้า 5: Corrupted page'));
    });

    test('Supported locales are correct', () {
      expect(AppLocalizations.supportedLocales, 
             containsAll([const Locale('en'), const Locale('th')]));
    });

    test('LocalizationsDelegate supports correct locales', () {
      const delegate = AppLocalizationsDelegate();
      
      expect(delegate.isSupported(const Locale('en')), isTrue);
      expect(delegate.isSupported(const Locale('th')), isTrue);
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.isSupported(const Locale('de')), isFalse);
    });
  });
}