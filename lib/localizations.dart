import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('th'),
  ];

  static Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'PDF Flipbook',
      'selectPDFFile': 'Select PDF File',
      'selectPDFToView': 'Select a PDF file to view as a Flipbook',
      'screenWillStayOn': 'Screen will stay on during use',
      'selectPDFButton': 'Select PDF File',
      'selectedFile': 'Selected file: {fileName}',
      'openPDFFlipbook': 'Open PDF Flipbook',
      'errorOccurred': 'An error occurred: {error}',
      'pdfNotFound': 'PDF file not found',
      'cannotProcessPDF': 'Cannot process PDF file',
      'processing': 'Processing...',
      'lowQuality': 'Low Quality (Fast)',
      'mediumQuality': 'Medium Quality',
      'highQuality': 'High Quality',
      'cacheOptions': 'Cache Options',
      'clearMemoryCache': 'Clear Memory Cache',
      'clearDiskCache': 'Clear Disk Cache',
      'memoryCacheCleared': 'Memory cache cleared',
      'diskCacheCleared': 'Disk cache cleared',
      'close': 'Close',
      'back': 'Back',
      'pdfFileNotExist': 'PDF file does not exist in the system',
      'pageError': 'Error occurred on page {page}: {error}',
      'confirmExit': 'Do you want to exit PDF viewer?',
      'yes': 'Yes',
      'no': 'No',
      'language': 'Language',
      'english': 'English',
      'thai': 'ไทย',
    },
    'th': {
      'appTitle': 'PDF Flipbook',
      'selectPDFFile': 'เลือกไฟล์ PDF',
      'selectPDFToView': 'เลือกไฟล์ PDF เพื่อเปิดดูในรูปแบบ Flipbook',
      'screenWillStayOn': 'หน้าจอจะไม่ปิดระหว่างใช้งาน',
      'selectPDFButton': 'เลือกไฟล์ PDF',
      'selectedFile': 'ไฟล์ที่เลือก: {fileName}',
      'openPDFFlipbook': 'เปิด PDF Flipbook',
      'errorOccurred': 'เกิดข้อผิดพลาด: {error}',
      'pdfNotFound': 'ไม่พบไฟล์ PDF',
      'cannotProcessPDF': 'ไม่สามารถประมวลผล PDF ได้',
      'processing': 'กำลังประมวลผล...',
      'lowQuality': 'คุณภาพต่ำ (เร็ว)',
      'mediumQuality': 'คุณภาพปานกลาง',
      'highQuality': 'คุณภาพสูง',
      'cacheOptions': 'ตัวเลือก Cache',
      'clearMemoryCache': 'ล้าง Memory Cache',
      'clearDiskCache': 'ล้าง Disk Cache',
      'memoryCacheCleared': 'ล้าง Memory Cache แล้ว',
      'diskCacheCleared': 'ล้าง Disk Cache แล้ว',
      'close': 'ปิด',
      'back': 'กลับ',
      'pdfFileNotExist': 'ไฟล์ PDF ไม่มีอยู่ในระบบ',
      'pageError': 'เกิดข้อผิดพลาดที่หน้า {page}: {error}',
      'confirmExit': 'คุณต้องการออกจากโปรแกรมดู PDF หรือไม่?',
      'yes': 'ใช่',
      'no': 'ไม่ใช่',
      'language': 'ภาษา',
      'english': 'English',
      'thai': 'ไทย',
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get selectPDFFile => _localizedValues[locale.languageCode]!['selectPDFFile']!;
  String get selectPDFToView => _localizedValues[locale.languageCode]!['selectPDFToView']!;
  String get screenWillStayOn => _localizedValues[locale.languageCode]!['screenWillStayOn']!;
  String get selectPDFButton => _localizedValues[locale.languageCode]!['selectPDFButton']!;
  String get openPDFFlipbook => _localizedValues[locale.languageCode]!['openPDFFlipbook']!;
  String get pdfNotFound => _localizedValues[locale.languageCode]!['pdfNotFound']!;
  String get cannotProcessPDF => _localizedValues[locale.languageCode]!['cannotProcessPDF']!;
  String get processing => _localizedValues[locale.languageCode]!['processing']!;
  String get lowQuality => _localizedValues[locale.languageCode]!['lowQuality']!;
  String get mediumQuality => _localizedValues[locale.languageCode]!['mediumQuality']!;
  String get highQuality => _localizedValues[locale.languageCode]!['highQuality']!;
  String get cacheOptions => _localizedValues[locale.languageCode]!['cacheOptions']!;
  String get clearMemoryCache => _localizedValues[locale.languageCode]!['clearMemoryCache']!;
  String get clearDiskCache => _localizedValues[locale.languageCode]!['clearDiskCache']!;
  String get memoryCacheCleared => _localizedValues[locale.languageCode]!['memoryCacheCleared']!;
  String get diskCacheCleared => _localizedValues[locale.languageCode]!['diskCacheCleared']!;
  String get close => _localizedValues[locale.languageCode]!['close']!;
  String get back => _localizedValues[locale.languageCode]!['back']!;
  String get pdfFileNotExist => _localizedValues[locale.languageCode]!['pdfFileNotExist']!;
  String get confirmExit => _localizedValues[locale.languageCode]!['confirmExit']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;
  String get language => _localizedValues[locale.languageCode]!['language']!;
  String get english => _localizedValues[locale.languageCode]!['english']!;
  String get thai => _localizedValues[locale.languageCode]!['thai']!;

  String selectedFile(String fileName) {
    return _localizedValues[locale.languageCode]!['selectedFile']!
        .replaceAll('{fileName}', fileName);
  }

  String errorOccurred(String error) {
    return _localizedValues[locale.languageCode]!['errorOccurred']!
        .replaceAll('{error}', error);
  }

  String pageError(int page, String error) {
    return _localizedValues[locale.languageCode]!['pageError']!
        .replaceAll('{page}', page.toString())
        .replaceAll('{error}', error);
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'th'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}