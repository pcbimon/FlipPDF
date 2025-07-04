import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PDFViewerScreen extends StatefulWidget {
  final String? path;

  const PDFViewerScreen({super.key, this.path});
  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  int? totalPages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // เปิด wakelock เพื่อไม่ให้หน้าจอดับระหว่างอ่าน PDF
    WakelockPlus.enable();
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
          children: [_buildBody(), if (isReady) _buildOverlayControls()],
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
      title: const Text('ปิด PDF Viewer'),
      content: const Text('คุณต้องการปิด PDF Viewer หรือไม่?'),
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

  Widget _buildBody() {
    if (widget.path == null || widget.path!.isEmpty) {
      return _buildErrorView('ไม่พบไฟล์ PDF');
    }

    final file = File(widget.path!);
    if (!file.existsSync()) {
      return _buildErrorView('ไฟล์ PDF ไม่มีอยู่ในระบบ');
    }

    if (errorMessage.isNotEmpty) {
      return _buildErrorView(errorMessage);
    }

    return _buildPDFView();
  }

  Widget _buildPDFView() {
    return PDFView(
      filePath: widget.path!,
      enableSwipe: true,
      swipeHorizontal: true,
      autoSpacing: true,
      pageFling: true,
      pageSnap: true,
      defaultPage: currentPage ?? 0,
      fitPolicy: FitPolicy.BOTH,
      preventLinkNavigation: false,
      onRender: (pages) {
        setState(() {
          totalPages = pages;
          isReady = true;
        });
      },
      onError: (error) {
        setState(() {
          errorMessage = error.toString();
        });
        print('PDF Error: $error');
      },
      onPageError: (page, error) {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดที่หน้า $page: $error';
        });
        print('PDF Page Error: $error');
      },
      onViewCreated: (PDFViewController pdfViewController) {
        _controller.complete(pdfViewController);
      },
      onLinkHandler: (String? uri) {
        print('Link tapped: $uri');
      },
      onPageChanged: (int? page, int? total) {
        print('Page changed: $page/$total');
        setState(() {
          currentPage = page;
        });
      },
    );
  }

  /// สร้างหน้าจอแสดงข้อผิดพลาด
  Widget _buildErrorView(String message) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              child: const Text('กลับ'),
            ),
          ],
        ),
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
          color: Colors.black.withOpacity(0.5),
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

  /// สร้างส่วน Controls ที่มุมขวาบน (หมายเลขหน้า)
  Widget _buildTopRightControls() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_buildPageCounter()],
      ),
    );
  }

  /// สร้างตัวแสดงหมายเลขหน้า
  Widget _buildPageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        '${(currentPage ?? 0) + 1}/${totalPages ?? 0}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  void dispose() {
    // ปิด wakelock เมื่อปิดหน้าจอ
    WakelockPlus.disable();
    super.dispose();
  }
}
