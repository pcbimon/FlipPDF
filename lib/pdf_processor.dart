import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'pdf_page.dart';

enum PdfQuality { low, medium, high, ultra }

class PdfProcessor {
  static final Map<String, List<Widget>> _cache = {};

  static int _getDPI(PdfQuality quality) {
    switch (quality) {
      case PdfQuality.low:
        return 72;
      case PdfQuality.medium:
        return 150;
      case PdfQuality.high:
        return 300;
      case PdfQuality.ultra:
        return 600;
    }
  }

  static Future<List<Widget>> processPDF(
    String filePath, {
    Function(double)? onProgress,
    PdfQuality quality = PdfQuality.medium,
    bool useCache = true,
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
      }

      // อ่านไฟล์ PDF
      final bytes = await file.readAsBytes();

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
        final dpi = _getDPI(quality);
        images = await _convertPDFToImages(
          bytes,
          dpi: dpi,
          onProgress: onProgress,
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
  }) async {
    final images = <Uint8List>[];

    try {
      // ใช้วิธีประมาณจำนวนหน้าที่ไม่ต้องแปลงจริง
      int totalPages = 0;
      int currentPage = 0;

      // แปลง PDF แต่ละหน้าเป็น image ในครั้งเดียว
      await for (final page in Printing.raster(pdfBytes, dpi: dpi.toDouble())) {
        final image = await page.toPng();
        images.add(image);

        currentPage++;

        // คำนวณ totalPages จากหน้าแรก (ประมาณการ)
        if (totalPages == 0) {
          // ใช้ขนาดไฟล์เป็นตัวประมาณ
          totalPages = (pdfBytes.length / 50000).ceil().clamp(1, 1000);
        }

        // ส่งความคืบหน้ากลับไป
        if (onProgress != null) {
          final progress = (currentPage / totalPages.clamp(currentPage, 1000))
              .clamp(0.0, 1.0);
          onProgress(progress);
        }
      }

      // ส่ง progress สุดท้ายเป็น 100%
      if (onProgress != null) {
        onProgress(1.0);
      }
    } catch (e) {
      print('Error converting PDF to images: $e');
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
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      // ใช้วิธีที่มีประสิทธิภาพกว่าในการนับหน้า
      int pageCount = 0;
      await for (final _ in Printing.raster(bytes, dpi: 72)) {
        pageCount++;
      }

      return pageCount;
    } catch (e) {
      print('Error getting PDF page count: $e');
      return 0;
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
}
