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

  /// ประมวลผล PDF และแปลงเป็น Widget pages
  Future<void> _processPDF() async {
    if (widget.path == null) {
      _setError('ไม่พบไฟล์ PDF');
      return;
    }

    try {
      _setLoadingState();

      // เปลี่ยนมาใช้ processLazyPDF เพื่อประหยัดหน่วยความจำ
      final processedPages = await PdfProcessor.processLazyPDF(
        widget.path!,
        quality: selectedQuality,
        onProgress: _updateProgress,
        context: context,
      );

      if (processedPages.isEmpty) {
        _setError('ไม่สามารถประมวลผล PDF ได้');
        return;
      }

      _setSuccessState(processedPages);
    } catch (e) {
      _setError('เกิดข้อผิดพลาด: ${e.toString()}');
    }
  }

  /// ตั้งค่าสถานะ Loading
  void _setLoadingState() {
    setState(() {
      isLoading = true;
      errorMessage = '';
      processingProgress = 0.0;
    });
  }

  /// อัปเดตความคืบหน้า
  void _updateProgress(double progress) {
    setState(() {
      processingProgress = progress;
    });
  }

  /// ตั้งค่าสถานะ Error
  void _setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
      processingProgress = 0.0;
    });
  }

  /// ตั้งค่าสถานะสำเร็จ
  void _setSuccessState(List<Widget> pages) {
    setState(() {
      pdfPages = pages;
      totalPages = pages.length;
      isLoading = false;
      processingProgress = 1.0;
    });
  }

  /// แสดง Dialog ยืนยันการปิด PDF
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: _buildExitDialog,
    );
    return shouldPop ?? false;
  }

  /// สร้าง Dialog สำหรับยืนยันการปิด
  Widget _buildExitDialog(BuildContext context) {
    return AlertDialog(
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
    );
  }

  /// แสดงตัวเลือก Cache
  void _showCacheOptions() {
    showDialog(context: context, builder: _buildCacheDialog);
  }

  /// สร้าง Dialog สำหรับจัดการ Cache
  Widget _buildCacheDialog(BuildContext context) {
    return AlertDialog(
      title: const Text('ตัวเลือก Cache'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCacheOption(
            icon: Icons.delete_outline,
            title: 'ล้าง Memory Cache',
            onTap: _clearMemoryCache,
          ),
          _buildCacheOption(
            icon: Icons.delete_forever,
            title: 'ล้าง Disk Cache',
            onTap: _clearDiskCache,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ปิด'),
        ),
      ],
    );
  }

  /// สร้างตัวเลือก Cache แต่ละตัว
  Widget _buildCacheOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  /// ล้าง Memory Cache
  void _clearMemoryCache() {
    PdfProcessor.clearCache();
    PageCacheManager.clearMemoryCache();
    Navigator.of(context).pop();
    _showSnackBar('ล้าง Memory Cache แล้ว');
  }

  /// ล้าง Disk Cache
  void _clearDiskCache() async {
    await PdfProcessor.clearDiskCache();
    await PageCacheManager.clearDiskCache();
    if (mounted) {
      Navigator.of(context).pop();
      _showSnackBar('ล้าง Disk Cache แล้ว');
    }
  }

  /// แสดง SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        appBar: _buildAppBar(),
        body: Stack(
          children: [
            _buildBody(),
            if (!isLoading && pdfPages.isNotEmpty) _buildOverlayControls(),
          ],
        ),
      ),
    );
  }

  /// สร้าง AppBar โปร่งใส
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
    );
  }

  /// สร้าง Overlay Controls (ปุ่ม back และตัวเลือกต่างๆ)
  Widget _buildOverlayControls() {
    return Stack(children: [_buildBackButton(), _buildTopRightControls()]);
  }

  /// สร้างปุ่ม Back ที่มุมซ้ายบน
  Widget _buildBackButton() {
    return Positioned(
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
    );
  }

  /// สร้างส่วน Controls ที่มุมขวาบน (ปุ่มตั้งค่าและหมายเลขหน้า)
  Widget _buildTopRightControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSettingsButton(),
          const SizedBox(width: 8),
          _buildPageCounter(),
        ],
      ),
    );
  }

  /// สร้างปุ่มตั้งค่า (เลือกคุณภาพและจัดการ Cache)
  Widget _buildSettingsButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.settings, color: Colors.white),
        onSelected: _handleSettingsSelection,
        itemBuilder: (context) => _buildSettingsMenuItems(),
      ),
    );
  }

  /// จัดการการเลือกตัวเลือกจากเมนูตั้งค่า
  void _handleSettingsSelection(String value) {
    if (value == 'cache') {
      _showCacheOptions();
    } else {
      final quality = PdfQuality.values.firstWhere((q) => q.name == value);
      setState(() {
        selectedQuality = quality;
      });
      _processPDF();
    }
  }

  /// สร้างรายการเมนูตั้งค่า
  List<PopupMenuEntry<String>> _buildSettingsMenuItems() {
    return [
      _buildQualityMenuItem(PdfQuality.low, 'คุณภาพต่ำ (เร็ว)'),
      _buildQualityMenuItem(PdfQuality.medium, 'คุณภาพปานกลาง'),
      _buildQualityMenuItem(PdfQuality.high, 'คุณภาพสูง'),
      _buildQualityMenuItem(PdfQuality.ultra, 'คุณภาพสูงสุด (ช้า)'),
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
    ];
  }

  /// สร้างรายการเมนูสำหรับเลือกคุณภาพ
  PopupMenuItem<String> _buildQualityMenuItem(
    PdfQuality quality,
    String label,
  ) {
    return PopupMenuItem(
      value: quality.name,
      child: Row(
        children: [
          Icon(
            selectedQuality == quality
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  /// สร้างตัวแสดงหมายเลขหน้า
  Widget _buildPageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return _buildLoadingView();
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorView();
    }

    if (pdfPages.isEmpty) {
      return _buildEmptyView();
    }

    return _buildPdfView();
  }

  /// สร้างหน้าจอแสดงสถานะ Loading
  Widget _buildLoadingView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProgressCircle(),
            const SizedBox(height: 24),
            const Text(
              'กำลังประมวลผล PDF...',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            _buildProgressText(),
            const SizedBox(height: 16),
            _buildProgressBar(),
          ],
        ),
      ),
    );
  }

  /// สร้างวงกลมแสดงความคืบหน้า
  Widget _buildProgressCircle() {
    return SizedBox(
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
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
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
    );
  }

  /// สร้างข้อความแสดงความคืบหน้า
  Widget _buildProgressText() {
    return Text(
      processingProgress > 0
          ? 'ประมวลผลแล้ว ${(processingProgress * 100).toInt()}% | กำลังแปลงหน้า PDF...'
          : 'เริ่มต้นการประมวลผล PDF...',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  /// สร้าง Progress Bar
  Widget _buildProgressBar() {
    return Container(
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
    );
  }

  /// สร้างหน้าจอแสดงข้อผิดพลาด
  Widget _buildErrorView() {
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

  /// สร้างหน้าจอเมื่อไม่พบหน้า PDF
  Widget _buildEmptyView() {
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

  /// สร้างหน้าจอแสดง PDF
  Widget _buildPdfView() {
    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: PageFlipWidget(
        key: const Key('pdf_page_flip'),
        backgroundColor: Colors.black,
        lastPage: _buildLastPage(),
        children: pdfPages,
        onPageFlipped: (index) {
          setState(() {
            currentPage = index;
          });
        },
      ),
    );
  }

  /// สร้างหน้าสุดท้าย
  Widget _buildLastPage() {
    return Container(
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
    );
  }

  @override
  void dispose() {
    // ไม่ปิด wakelock ที่นี่ เพราะอาจจะกลับไปหน้าหลักและยังต้องการให้หน้าจอไม่ปิด
    // wakelock จะถูกจัดการโดย lifecycle ของแอพ
    super.dispose();
  }
}
