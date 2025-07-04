import 'dart:async';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'pdf_processor.dart';

class PDFScreen extends StatefulWidget {
  final String? path;

  const PDFScreen({super.key, this.path});
  @override
  State<PDFScreen> createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  List<Widget> pdfPages = [];
  bool isLoading = true;
  String errorMessage = '';
  int totalPages = 0;
  int currentPage = 0;
  double processingProgress = 0.0; // เพิ่มตัวแปรสำหรับความคืบหน้า
  PdfQuality selectedQuality = PdfQuality.medium; // เพิ่มตัวแปรสำหรับคุณภาพ

  @override
  void initState() {
    super.initState();
    // ตรวจสอบให้แน่ใจว่า wakelock เปิดอยู่เมื่อเข้าหน้า PDF
    WakelockPlus.enable();
    _processPDF();
  }

  Future<void> _processPDF() async {
    if (widget.path == null) {
      setState(() {
        errorMessage = 'ไม่พบไฟล์ PDF';
        isLoading = false;
      });
      return;
    }

    try {
      setState(
        () {
          isLoading = true;
          errorMessage = '';
          processingProgress = 0.0;
        },
      ); // ประมวลผล PDF และสร้าง Widget list พร้อมกับ callback สำหรับความคืบหน้า
      final processedPages = await PdfProcessor.processPDF(
        widget.path!,
        quality: selectedQuality,
        onProgress: (progress) {
          setState(() {
            processingProgress = progress;
          });
        },
      );

      if (processedPages.isEmpty) {
        setState(() {
          errorMessage = 'ไม่สามารถประมวลผล PDF ได้';
          isLoading = false;
          processingProgress = 0.0;
        });
        return;
      }

      setState(() {
        pdfPages = processedPages;
        totalPages = processedPages.length;
        isLoading = false;
        processingProgress = 1.0; // 100% เสร็จสิ้น
      });
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาด: ${e.toString()}';
        isLoading = false;
        processingProgress = 0.0;
      });
    }
  }

  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ปิด PDF Flipbook'),
        content: const Text('คุณต้องการปิด PDF Flipbook หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  void _showCacheOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตัวเลือก Cache'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('ล้าง Memory Cache'),
              onTap: () {
                PdfProcessor.clearCache();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ล้าง Memory Cache แล้ว')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever),
              title: const Text('ล้าง Disk Cache'),
              onTap: () async {
                await PdfProcessor.clearDiskCache();
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ล้าง Disk Cache แล้ว')),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
        ),
        body: Stack(
          children: [
            _buildBody(),
            // แสดง overlay controls
            if (!isLoading && pdfPages.isNotEmpty) ...[
              // ปุ่ม back ที่มุมซ้ายบน
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ), // แสดงหมายเลขหน้าที่มุมขวาบน
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ปุ่มเลือกคุณภาพ
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onSelected: (value) {
                          if (value == 'cache') {
                            _showCacheOptions();
                          } else {
                            final quality = PdfQuality.values.firstWhere(
                              (q) => q.name == value,
                            );
                            setState(() {
                              selectedQuality = quality;
                            });
                            _processPDF(); // ประมวลผลใหม่ด้วยคุณภาพใหม่
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: PdfQuality.low.name,
                            child: Row(
                              children: [
                                Icon(
                                  selectedQuality == PdfQuality.low
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                const SizedBox(width: 8),
                                const Text('คุณภาพต่ำ (เร็ว)'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PdfQuality.medium.name,
                            child: Row(
                              children: [
                                Icon(
                                  selectedQuality == PdfQuality.medium
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                const SizedBox(width: 8),
                                const Text('คุณภาพปานกลาง'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PdfQuality.high.name,
                            child: Row(
                              children: [
                                Icon(
                                  selectedQuality == PdfQuality.high
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                const SizedBox(width: 8),
                                const Text('คุณภาพสูง'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: PdfQuality.ultra.name,
                            child: Row(
                              children: [
                                Icon(
                                  selectedQuality == PdfQuality.ultra
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                ),
                                const SizedBox(width: 8),
                                const Text('คุณภาพสูงสุด (ช้า)'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'cache',
                            child: Row(
                              children: [
                                Icon(Icons.storage),
                                SizedBox(width: 8),
                                Text('จัดการ Cache'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // หมายเลขหน้า
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        '${currentPage + 1}/$totalPages',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Progress Circle แสดงความคืบหน้า
              SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: processingProgress,
                        strokeWidth: 8,
                        backgroundColor: Colors.grey[700],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                    Text(
                      '${(processingProgress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'กำลังประมวลผล PDF...',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                processingProgress > 0
                    ? 'ประมวลผลแล้ว ${(processingProgress * 100).toInt()}% | กำลังแปลงหน้า PDF...'
                    : 'เริ่มต้นการประมวลผล PDF...',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Progress Bar เพิ่มเติม
              Container(
                width: 200,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: processingProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _processPDF,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (pdfPages.isEmpty) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'ไม่พบหน้า PDF',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: PageFlipWidget(
        key: const Key('pdf_page_flip'),
        backgroundColor: Colors.black,
        lastPage: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'จบเอกสาร',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'หวัดดีและขอบคุณ',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        children: pdfPages,
        onPageFlipped: (index) {
          setState(() {
            currentPage = index;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // ไม่ปิด wakelock ที่นี่ เพราะอาจจะกลับไปหน้าหลักและยังต้องการให้หน้าจอไม่ปิด
    // wakelock จะถูกจัดการโดย lifecycle ของแอพ
    super.dispose();
  }
}
