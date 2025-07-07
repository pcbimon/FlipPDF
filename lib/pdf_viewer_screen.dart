import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // ตัวแปรสำหรับการเปลี่ยนหน้าอัตโนมัติ
  bool _isAutoPlaying = false;
  Timer? _autoPlayTimer;
  Timer? _countdownTimer;
  final int _autoPlayInterval = 10; // เวลาในการเปลี่ยนหน้าอัตโนมัติ (วินาที)
  double _countdown = 0; // ค่าการนับถอยหลัง (0.0 - 1.0)

  @override
  void initState() {
    super.initState();
    // เปิด wakelock เพื่อไม่ให้หน้าจอดับระหว่างอ่าน PDF
    WakelockPlus.enable();
    // เปิดโหมดเต็มจอ
    _enableFullScreen();
  }

  // เปิดโหมดเต็มจอ
  void _enableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  // คืนค่าการแสดงผล UI กลับสู่สถานะปกติ
  void _disableFullScreen() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
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
        children: [
          _buildAutoPlayButton(),
          const SizedBox(width: 8),
          _buildPageSelectorButton(),
          const SizedBox(width: 8),
          _buildPageCounter(),
        ],
      ),
    );
  }

  /// สร้างปุ่มเลือกหน้าที่ต้องการ
  Widget _buildPageSelectorButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: IconButton(
        icon: const Icon(Icons.list, color: Colors.white),
        tooltip: 'เลือกหน้าที่ต้องการ',
        onPressed: _showPageSelectorDialog,
      ),
    );
  }

  /// แสดง dialog สำหรับเลือกหน้าที่ต้องการ
  void _showPageSelectorDialog() async {
    if (totalPages == null || totalPages == 0) return;
    final TextEditingController controller = TextEditingController();
    int? selectedPage;
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ไปยังหน้าที่...'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'ระบุหมายเลขหน้า (1-${totalPages ?? 0})',
            ),
            autofocus: true,
            onChanged: (value) {
              final page = int.tryParse(value);
              if (page != null && page > 0 && page <= (totalPages ?? 0)) {
                selectedPage = page - 1;
              } else {
                selectedPage = null;
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedPage != null) {
                  final pdfController = await _controller.future;
                  pdfController.setPage(selectedPage!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('ไป'),
            ),
          ],
        );
      },
    );
  }

  /// สร้างปุ่มเล่น/หยุดอัตโนมัติ
  Widget _buildAutoPlayButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // แสดงการนับถอยหลังเป็นวงกลมรอบปุ่ม
          if (_isAutoPlaying)
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                value: _countdown,
                backgroundColor: Colors.grey.withOpacity(0.3),
                color: Colors.blue,
                strokeWidth: 3,
              ),
            ),
          // ปุ่ม play/pause
          IconButton(
            icon: Icon(
              _isAutoPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: _toggleAutoPlay,
            tooltip: _isAutoPlaying ? 'หยุดเล่นอัตโนมัติ' : 'เล่นอัตโนมัติ',
          ),
        ],
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

  // เริ่มการเปลี่ยนหน้าอัตโนมัติ
  void _startAutoPlay() {
    if (_isAutoPlaying || !isReady) return;

    setState(() {
      _isAutoPlaying = true;
      _countdown = 1.0; // เริ่มที่ 100%
    });

    _autoPlayTimer = Timer.periodic(Duration(seconds: _autoPlayInterval), (
      timer,
    ) {
      _goToNextPage();
      setState(() {
        _countdown = 1.0; // รีเซ็ตเป็น 100% หลังจากเปลี่ยนหน้า
      });
    });

    // ตั้งค่า timer สำหรับนับถอยหลัง
    _startCountdownTimer();
  }

  // เริ่มการนับถอยหลัง
  void _startCountdownTimer() {
    // ยกเลิก timer เดิมถ้ามี
    _countdownTimer?.cancel();

    // อัพเดททุก 100 มิลลิวินาที (10 ครั้งต่อวินาที)
    const updateInterval = 100;
    final totalUpdates = _autoPlayInterval * 10; // จำนวนครั้งทั้งหมดในการอัพเดท
    final decrementPerUpdate = 1.0 / totalUpdates; // ค่าที่ลดลงในแต่ละครั้ง

    _countdownTimer = Timer.periodic(Duration(milliseconds: updateInterval), (
      timer,
    ) {
      if (!_isAutoPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdown -= decrementPerUpdate;
        if (_countdown < 0) _countdown = 0;
      });
    });
  }

  // หยุดการเปลี่ยนหน้าอัตโนมัติ
  void _stopAutoPlay() {
    if (!_isAutoPlaying) return;

    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;

    _countdownTimer?.cancel();
    _countdownTimer = null;

    setState(() {
      _isAutoPlaying = false;
      _countdown = 0;
    });
  }

  // สลับระหว่างการเล่นอัตโนมัติและการหยุด
  void _toggleAutoPlay() {
    if (_isAutoPlaying) {
      _stopAutoPlay();
    } else {
      _startAutoPlay();
    }
  }

  // ไปยังหน้าถัดไป
  void _goToNextPage() async {
    if (!isReady) return;

    final controller = await _controller.future;
    final currentPageIndex = currentPage ?? 0;
    final totalPagesCount = totalPages ?? 0;

    if (currentPageIndex < totalPagesCount - 1) {
      controller.setPage(currentPageIndex + 1);
    } else {
      // กลับไปหน้าแรกเมื่อถึงหน้าสุดท้าย
      controller.setPage(0);
    }
  }

  @override
  void dispose() {
    // ปิด wakelock เมื่อปิดหน้าจอ
    WakelockPlus.disable();
    // คืนค่าการแสดงผล UI กลับสู่สถานะปกติ
    _disableFullScreen();
    // หยุดการเปลี่ยนหน้าอัตโนมัติ
    _stopAutoPlay();
    // ยกเลิก timer ทั้งหมด
    _autoPlayTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
