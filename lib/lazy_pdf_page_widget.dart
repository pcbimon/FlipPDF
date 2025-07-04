import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'pdf_processor.dart';
import 'pdf_page.dart';

// Global document cache เพื่อแบ่งปันการใช้งาน document เดียวกัน
class PdfDocumentCache {
  static final Map<String, PdfDocument> _documents = {};
  static final Map<String, Uint8List> _documentData = {};
  
  // โหลด document จาก path หรือเรียกใช้จาก cache ถ้ามี
  static Future<PdfDocument> getDocument(String filePath) async {
    if (_documents.containsKey(filePath)) {
      return _documents[filePath]!;
    }
    
    // ถ้ามีข้อมูลไฟล์แล้ว ใช้ข้อมูลนั้นเปิด document
    if (_documentData.containsKey(filePath)) {
      final document = await PdfDocument.openData(_documentData[filePath]!);
      _documents[filePath] = document;
      return document;
    }
    
    // อ่านไฟล์และเก็บข้อมูลไว้
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    _documentData[filePath] = bytes;
    
    // เปิด document และเก็บไว้ใน cache
    final document = await PdfDocument.openData(bytes);
    _documents[filePath] = document;
    return document;
  }
  
  // ล้าง cache ทั้งหมด
  static Future<void> clearCache() async {
    for (final document in _documents.values) {
      await document.close();
    }
    _documents.clear();
    _documentData.clear();
  }
}

class LazyPdfPageWidget extends StatefulWidget {
  final String filePath;
  final int pageNumber;
  final int totalPages;
  final PdfQuality quality;
  final BuildContext? context;

  const LazyPdfPageWidget({
    super.key,
    required this.filePath,
    required this.pageNumber,
    required this.totalPages,
    required this.quality,
    this.context,
  });

  @override
  State<LazyPdfPageWidget> createState() => _LazyPdfPageWidgetState();
}

class _LazyPdfPageWidgetState extends State<LazyPdfPageWidget>
    with AutomaticKeepAliveClientMixin {
  bool _isLoaded = false;
  bool _isLoading = false;
  Widget? _pageContent;

  // ใช้ keepAlive เพื่อรักษาสถานะเมื่อหน้านี้ถูกสร้างแล้ว
  @override
  bool get wantKeepAlive => _isLoaded;

  @override
  void initState() {
    super.initState();
    // เช็คว่ามีใน memory cache หรือไม่
    _checkMemoryCache();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // โหลดหน้าเมื่อวิดเจ็ตถูกแสดง
    _loadPageIfNeeded();
  }

  void _checkMemoryCache() {
    final cacheKey = _generateCacheKey();
    final cachedPage = PdfProcessor.getPageFromMemoryCache(cacheKey);
    if (cachedPage != null) {
      setState(() {
        _pageContent = cachedPage;
        _isLoaded = true;
      });
    }
  }

  String _generateCacheKey() {
    // สร้าง cache key จากชื่อไฟล์เท่านั้น ไม่ใช่ path เต็ม
    final fileName = widget.filePath.split('/').last.split('\\').last;
    return '${fileName}_page_${widget.pageNumber}_${widget.quality.name}';
  }

  Future<void> _loadPageIfNeeded() async {
    if (_isLoaded || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cacheKey = _generateCacheKey();

      // ตรวจสอบจาก disk cache ก่อน
      final diskCachedPage = await PdfProcessor.loadSinglePageFromDiskCache(
        cacheKey,
      );

      if (diskCachedPage != null) {
        if (mounted) {
          setState(() {
            _pageContent = _buildPageContent(diskCachedPage);
            _isLoaded = true;
            _isLoading = false;
          });
        }

        // บันทึกลง memory cache ด้วย
        PdfProcessor.savePageToMemoryCache(cacheKey, _pageContent!);
        return;
      }

      // ใช้ document จาก cache
      final document = await PdfDocumentCache.getDocument(widget.filePath);
      final page = await document.getPage(widget.pageNumber);

      // คำนวณขนาดและ DPI
      final screenSize = PdfProcessor.getScreenSize(widget.context);
      final dpi = PdfProcessor.getDPI(widget.quality, screenSize: screenSize);
      final scaleFactor = dpi / 72.0;

      final width = page.width * scaleFactor;
      final height = page.height * scaleFactor;

      // Render หน้า PDF
      final pageImage = await page.render(width: width, height: height);

      // ปิดเฉพาะหน้า แต่ไม่ปิด document เพราะจะใช้ร่วมกัน
      await page.close();

      if (pageImage == null || !mounted) {
        throw Exception('Failed to render page');
      }

      final renderedWidget = _buildPageContent(pageImage.bytes);

      setState(() {
        _pageContent = renderedWidget;
        _isLoaded = true;
        _isLoading = false;
      });

      // บันทึกลง cache
      PdfProcessor.savePageToMemoryCache(cacheKey, renderedWidget);
      await PdfProcessor.saveSinglePageToDiskCache(cacheKey, pageImage.bytes);
    } catch (e) {
      print('Error loading page ${widget.pageNumber}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPageContent(Uint8List imageBytes) {
    return PdfPageWidget(
      pageNumber: widget.pageNumber,
      totalPages: widget.totalPages,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: Image.memory(imageBytes, fit: BoxFit.contain),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!_isLoaded) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'กำลังโหลดหน้า ${widget.pageNumber}/${widget.totalPages}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return _pageContent ??
        Container(
          color: Colors.black,
          child: const Center(
            child: Text(
              'ไม่สามารถโหลดหน้านี้ได้',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
  }
}
