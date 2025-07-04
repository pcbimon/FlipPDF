import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_page.dart';
import 'lazy_pdf_page_widget.dart';

enum PdfQuality { low, medium, high, ultra, auto }

/// จัดการ cache สำหรับหน้า PDF แต่ละหน้า
class PageCacheManager {
  // Memory cache สำหรับเก็บ Widget ของแต่ละหน้า
  static final Map<String, Widget> _pageWidgetCache = {};

  // Memory cache สำหรับเก็บข้อมูลรูปภาพของแต่ละหน้า
  static final Map<String, Uint8List> _pageImageCache = {};

  // ดึง Widget จาก memory cache
  static Widget? getWidgetFromCache(String cacheKey) {
    return _pageWidgetCache[cacheKey];
  }

  // บันทึก Widget ลงใน memory cache
  static void saveWidgetToCache(String cacheKey, Widget widget) {
    _pageWidgetCache[cacheKey] = widget;
  }

  // ดึงข้อมูลรูปภาพจาก memory cache
  static Uint8List? getImageFromCache(String cacheKey) {
    return _pageImageCache[cacheKey];
  }

  // บันทึกข้อมูลรูปภาพลงใน memory cache
  static void saveImageToCache(String cacheKey, Uint8List imageBytes) {
    _pageImageCache[cacheKey] = imageBytes;
  }

  // บันทึกรูปภาพลง disk cache
  static Future<void> saveImageToDiskCache(String cacheKey, Uint8List imageBytes) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final pagesCacheFolder = Directory('${cacheDir.path}/pdf_cache/pages');

      if (!await pagesCacheFolder.exists()) {
        await pagesCacheFolder.create(recursive: true);
      }

      final cacheFile = File('${pagesCacheFolder.path}/$cacheKey.png');
      await cacheFile.writeAsBytes(imageBytes);
    } catch (e) {
      print('Error saving page to disk cache: $e');
    }
  }

  // โหลดรูปภาพจาก disk cache
  static Future<Uint8List?> loadImageFromDiskCache(String cacheKey) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/pdf_cache/pages/$cacheKey.png');

      if (await cacheFile.exists()) {
        return await cacheFile.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error loading page from disk cache: $e');
      return null;
    }
  }

  // ล้าง memory cache ทั้งหมด
  static void clearMemoryCache() {
    _pageWidgetCache.clear();
    _pageImageCache.clear();
  }

  // ล้าง disk cache ทั้งหมด
  static Future<void> clearDiskCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final pagesCacheFolder = Directory('${cacheDir.path}/pdf_cache/pages');

      if (await pagesCacheFolder.exists()) {
        await pagesCacheFolder.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing disk cache: $e');
    }
  }
}

class PdfProcessor {
  static final Map<String, List<Widget>> _cache = {};
  static int _getDPI(PdfQuality quality, {Size? screenSize}) {
    switch (quality) {
      case PdfQuality.low:
        return 72;
      case PdfQuality.medium:
        return 150;
      case PdfQuality.high:
        return 300;
      case PdfQuality.ultra:
        return 600;
      case PdfQuality.auto:
        // คำนวณ DPI อัตโนมัติตามหน้าจอ
        final effectiveScreenSize = screenSize ?? const Size(800, 600);
        final screenWidth = effectiveScreenSize.width;

        if (screenWidth < 400) return 150; // หน้าจอเล็ก
        if (screenWidth < 800) return 200; // หน้าจอกลาง
        return 250; // หน้าจอใหญ่
    }
  }

  static Future<List<Widget>> processPDF(
    String filePath, {
    Function(double)? onProgress,
    PdfQuality quality = PdfQuality.medium,
    bool useCache = true,
    BuildContext? context,
  }) async {
    try {
      // สร้าง cache key
      final file = File(filePath);
      final stat = await file.stat();
      final cacheKey =
          '${filePath}_${stat.modified.millisecondsSinceEpoch}_${stat.size}_${quality.name}';

      // ตรวจสอบ memory cache
      if (useCache && _cache.containsKey(cacheKey)) {
        return _cache[cacheKey]!;
      } // อ่านไฟล์ PDF
      final bytes = await file
          .readAsBytes(); // ดึงข้อมูลหน้าจอก่อนเข้า async function
      final screenSize = _getScreenSize(context);
      final dpi = _getDPI(quality, screenSize: screenSize);

      // ตรวจสอบ disk cache
      final diskCacheImages = await _loadFromDiskCache(cacheKey);
      List<Uint8List> images;

      if (diskCacheImages != null && diskCacheImages.isNotEmpty) {
        images = diskCacheImages;
        // ส่ง progress เป็น 100% เมื่อโหลดจาก cache
        if (onProgress != null) {
          onProgress(1.0);
        }
      } else {
        images = await _convertPDFToImages(
          bytes,
          dpi: dpi,
          onProgress: onProgress,
          screenSize: screenSize, // ส่ง screenSize แทน context
        );
        // บันทึกลง disk cache
        await _saveToDiskCache(cacheKey, images);
      }

      // สร้าง Widget list
      final widgets = <Widget>[];
      for (int i = 0; i < images.length; i++) {
        widgets.add(
          PdfPageWidget(
            pageNumber: i + 1,
            totalPages: images.length,
            child: _buildPageContent(images[i]),
          ),
        );
      }

      // เก็บใน memory cache
      if (useCache) {
        _cache[cacheKey] = widgets;
      }

      return widgets;
    } catch (e) {
      print('Error processing PDF: $e');
      return [];
    }
  }

  static Future<List<Uint8List>> _convertPDFToImages(
    Uint8List pdfBytes, {
    int dpi = 150,
    Function(double)? onProgress,
    Size? screenSize,
  }) async {
    final images = <Uint8List>[];
    PdfDocument? document;

    try {
      // เปิด PDF document
      document = await PdfDocument.openData(pdfBytes);
      final totalPages = document.pagesCount;

      // คำนวณ scale factor จาก DPI
      final scaleFactor = dpi / 72.0;

      // ใช้ screenSize ที่ส่งมา หรือ default values
      final effectiveScreenSize = screenSize ?? const Size(800, 600);
      final screenWidth = effectiveScreenSize.width;
      final screenHeight = effectiveScreenSize.height;

      for (int i = 1; i <= totalPages; i++) {
        try {
          // รับหน้า PDF
          final page = await document.getPage(i); // คำนวณขนาดตาม scale factor
          var originalWidth = (page.width * scaleFactor);
          var originalHeight = (page.height * scaleFactor);

          // คำนวณขนาดที่เหมาะสมตามหน้าจอ
          final maxWidth =
              screenWidth * 2; // ให้ความละเอียดสูงสุด 2 เท่าของหน้าจอ
          final maxHeight = screenHeight * 2;

          final optimalSize = _calculateOptimalSize(
            originalWidth,
            originalHeight,
            maxWidth,
            maxHeight,
          );
          final width = optimalSize.width;
          final height = optimalSize.height;

          // แสดงข้อมูลความละเอียดที่ใช้ (สำหรับ debug)
          print(
            'Page $i: Original ${originalWidth.toInt()}x${originalHeight.toInt()} → Optimized ${width.toInt()}x${height.toInt()}',
          );

          // แปลงเป็นรูปภาพ
          final pageImage = await page.render(width: width, height: height);

          // แปลงเป็น PNG bytes
          final pngBytes = pageImage?.bytes;
          if (pngBytes != null) {
            images.add(pngBytes);
          }

          // ปิดหน้าเพื่อปลดปล่อย memory
          await page.close();

          // ส่งความคืบหน้า
          if (onProgress != null) {
            final progress = i / totalPages;
            onProgress(progress);
          }
        } catch (e) {
          print('Error processing page $i: $e');
        }
      }

      // ส่ง progress สุดท้ายเป็น 100%
      if (onProgress != null) {
        onProgress(1.0);
      }
    } catch (e) {
      print('Error converting PDF to images: $e');
    } finally {
      // ปิด document เพื่อปลดปล่อย memory
      await document?.close();
    }

    return images;
  }

  static Widget _buildPageContent(Uint8List imageBytes) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(8.0),
      child: Image.memory(imageBytes, fit: BoxFit.contain),
    );
  }

  static Future<int> getPDFPageCount(String filePath) async {
    PdfDocument? document;
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // เปิด PDF document
      document = await PdfDocument.openData(bytes);

      // รับจำนวนหน้า
      final pageCount = document.pagesCount;

      return pageCount;
    } catch (e) {
      print('Error getting PDF page count: $e');
      return 0;
    } finally {
      // ปิด document เพื่อปลดปล่อย memory
      await document?.close();
    }
  }

  static Future<List<Uint8List>?> _loadFromDiskCache(String cacheKey) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/pdf_cache/$cacheKey');

      if (!await cacheFolder.exists()) return null;

      final files = await cacheFolder.list().toList();
      files.sort((a, b) => a.path.compareTo(b.path));

      final images = <Uint8List>[];
      for (final file in files) {
        if (file is File && file.path.endsWith('.png')) {
          images.add(await file.readAsBytes());
        }
      }

      return images.isEmpty ? null : images;
    } catch (e) {
      print('Error loading from disk cache: $e');
      return null;
    }
  }

  static Future<void> _saveToDiskCache(
    String cacheKey,
    List<Uint8List> images,
  ) async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/pdf_cache/$cacheKey');

      if (!await cacheFolder.exists()) {
        await cacheFolder.create(recursive: true);
      }

      for (int i = 0; i < images.length; i++) {
        final file = File(
          '${cacheFolder.path}/page_${i.toString().padLeft(3, '0')}.png',
        );
        await file.writeAsBytes(images[i]);
      }
    } catch (e) {
      print('Error saving to disk cache: $e');
    }
  }

  static void clearCache() {
    _cache.clear();
  }

  static Future<void> clearDiskCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      final cacheFolder = Directory('${cacheDir.path}/pdf_cache');

      if (await cacheFolder.exists()) {
        await cacheFolder.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing disk cache: $e');
    }
  }

  // ฟังก์ชันช่วยในการคำนวณขนาดที่เหมาะสมตามหน้าจอ
  static Size _calculateOptimalSize(
    double originalWidth,
    double originalHeight,
    double maxWidth,
    double maxHeight,
  ) {
    // คำนวณ aspect ratio
    final aspectRatio = originalWidth / originalHeight;

    double width = originalWidth;
    double height = originalHeight;

    // ตรวจสอบและปรับขนาดตาม width
    if (width > maxWidth) {
      width = maxWidth;
      height = width / aspectRatio;
    }

    // ตรวจสอบและปรับขนาดตาม height
    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    return Size(width, height);
  }

  // ฟังก์ชันสำหรับรับข้อมูลหน้าจอจาก context (ถ้ามี)
  static Size _getScreenSize([BuildContext? context]) {
    if (context != null) {
      final mediaQuery = MediaQuery.of(context);
      return Size(mediaQuery.size.width, mediaQuery.size.height);
    }

    // ใช้ PlatformDispatcher แทน window (deprecated)
    final view = ui.PlatformDispatcher.instance.views.first;
    final screenSize = view.physicalSize;
    final devicePixelRatio = view.devicePixelRatio;
    return Size(
      screenSize.width / devicePixelRatio,
      screenSize.height / devicePixelRatio,
    );
  }
  
  // เปิดเผย methods ที่ใช้ใน LazyPdfPageWidget
  static Size getScreenSize([BuildContext? context]) {
    return _getScreenSize(context);
  }
  
  static int getDPI(PdfQuality quality, {Size? screenSize}) {
    return _getDPI(quality, screenSize: screenSize);
  }
  
  static Size calculateOptimalSize(
    double originalWidth,
    double originalHeight,
    double maxWidth,
    double maxHeight,
  ) {
    return _calculateOptimalSize(originalWidth, originalHeight, maxWidth, maxHeight);
  }
  
  // ดึง Widget จาก memory cache
  static Widget? getPageFromMemoryCache(String cacheKey) {
    return PageCacheManager.getWidgetFromCache(cacheKey);
  }
  
  // บันทึก Widget ลง memory cache
  static void savePageToMemoryCache(String cacheKey, Widget widget) {
    PageCacheManager.saveWidgetToCache(cacheKey, widget);
  }
  
  // ดึงรูปภาพหน้า PDF จาก disk cache
  static Future<Uint8List?> loadSinglePageFromDiskCache(String cacheKey) async {
    return await PageCacheManager.loadImageFromDiskCache(cacheKey);
  }
  
  // บันทึกรูปภาพหน้า PDF ลง disk cache
  static Future<void> saveSinglePageToDiskCache(String cacheKey, Uint8List imageBytes) async {
    await PageCacheManager.saveImageToDiskCache(cacheKey, imageBytes);
  }

  // แปลงไฟล์ PDF เป็น Lazy Widgets
  static Future<List<Widget>> processLazyPDF(
    String filePath, {
    Function(double)? onProgress,
    PdfQuality quality = PdfQuality.medium,
    BuildContext? context,
  }) async {
    try {
      // ดึงจำนวนหน้าทั้งหมด
      final pageCount = await getPDFPageCount(filePath);
      
      if (pageCount == 0) {
        throw Exception('ไม่สามารถเปิดไฟล์ PDF ได้');
      }
      
      final widgets = <Widget>[];
      
      // สร้าง placeholder widgets ที่จะโหลดข้อมูลแบบ lazy
      for (int i = 0; i < pageCount; i++) {
        widgets.add(
          LazyPdfPageWidget(
            filePath: filePath,
            pageNumber: i + 1,
            totalPages: pageCount,
            quality: quality,
            context: context,
          ),
        );
        
        // รายงานความคืบหน้า
        if (onProgress != null) {
          onProgress((i + 1) / pageCount);
        }
      }
      
      return widgets;
    } catch (e) {
      print('Error processing lazy PDF: $e');
      return [];
    }
  }
}
