import 'dart:async';
import 'package:flutter/material.dart';
import 'package:page_flip/page_flip.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'pdf_processor.dart';
import 'lazy_pdf_page_widget.dart';
import 'localizations.dart';

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
  double processingProgress = 0.0; // Variable for processing progress
  PdfQuality selectedQuality = PdfQuality.medium; // Variable for quality setting

  @override
  void initState() {
    super.initState();
    // Ensure wakelock is enabled when entering PDF screen
    WakelockPlus.enable();
    _processPDF();
  }

  /// Process PDF and convert to Widget pages
  Future<void> _processPDF() async {
    if (widget.path == null) {
      final localizations = AppLocalizations.of(context);
      _setError(localizations?.pdfNotFound ?? 'PDF file not found');
      return;
    }

    try {
      _setLoadingState();

      // Use processLazyPDF to save memory
      final processedPages = await PdfProcessor.processLazyPDF(
        widget.path!,
        quality: selectedQuality,
        onProgress: _updateProgress,
        context: context,
      );

      if (processedPages.isEmpty) {
        final localizations = AppLocalizations.of(context);
        _setError(localizations?.cannotProcessPDF ?? 'Cannot process PDF file');
        return;
      }

      _setSuccessState(processedPages);
    } catch (e) {
      final localizations = AppLocalizations.of(context);
      _setError(localizations?.errorOccurred(e.toString()) ?? 'An error occurred: ${e.toString()}');
    }
  }

  /// Set Loading state
  void _setLoadingState() {
    setState(() {
      isLoading = true;
      errorMessage = '';
      processingProgress = 0.0;
    });
  }

  /// Update progress
  void _updateProgress(double progress) {
    setState(() {
      processingProgress = progress;
    });
  }

  /// Set Error state
  void _setError(String message) {
    setState(() {
      errorMessage = message;
      isLoading = false;
      processingProgress = 0.0;
    });
  }

  /// Set Success state
  void _setSuccessState(List<Widget> pages) {
    setState(() {
      pdfPages = pages;
      totalPages = pages.length;
      isLoading = false;
      processingProgress = 1.0;
    });
  }

  /// Show Dialog to confirm PDF closure
  Future<bool> _onWillPop() async {
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: _buildExitDialog,
    );
    return shouldPop ?? false;
  }

  /// Create Dialog for closure confirmation
  Widget _buildExitDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: const Text('PDF Flipbook'),
      content: Text(localizations.confirmExit),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(localizations.no),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(localizations.yes),
        ),
      ],
    );
  }

  /// Show Cache options
  void _showCacheOptions() {
    showDialog(context: context, builder: _buildCacheDialog);
  }

  /// Create Dialog for Cache management
  Widget _buildCacheDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(localizations.cacheOptions),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCacheOption(
            icon: Icons.delete_outline,
            title: localizations.clearMemoryCache,
            onTap: _clearMemoryCache,
          ),
          _buildCacheOption(
            icon: Icons.delete_forever,
            title: localizations.clearDiskCache,
            onTap: _clearDiskCache,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(localizations.close),
        ),
      ],
    );
  }

  /// Create each Cache option
  Widget _buildCacheOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
  }

  /// Clear Memory Cache
  void _clearMemoryCache() {
    PdfProcessor.clearCache();
    PageCacheManager.clearMemoryCache();
    PdfDocumentCache.clearCache();
    Navigator.of(context).pop();
    final localizations = AppLocalizations.of(context);
    _showSnackBar(localizations?.memoryCacheCleared ?? 'Memory cache cleared');
  }

  /// Clear Disk Cache
  void _clearDiskCache() async {
    await PdfProcessor.clearDiskCache();
    await PageCacheManager.clearDiskCache();
    if (mounted) {
      Navigator.of(context).pop();
      final localizations = AppLocalizations.of(context);
      _showSnackBar(localizations?.diskCacheCleared ?? 'Disk cache cleared');
    }
  }

  /// Show SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  /// Create transparent AppBar
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

  /// Create Overlay Controls (back button and options)
  Widget _buildOverlayControls() {
    return Stack(children: [_buildBackButton(), _buildTopRightControls()]);
  }

  /// Create Back button at top left
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

  /// Create Controls section at top right (settings button and page counter)
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

  /// Create settings button (quality selection and Cache management)
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

  /// Handle settings menu selection
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

  /// Create settings menu items
  List<PopupMenuEntry<String>> _buildSettingsMenuItems() {
    final localizations = AppLocalizations.of(context)!;
    return [
      _buildQualityMenuItem(PdfQuality.low, localizations.lowQuality),
      _buildQualityMenuItem(PdfQuality.medium, localizations.mediumQuality),
      _buildQualityMenuItem(PdfQuality.high, localizations.highQuality),
      _buildQualityMenuItem(PdfQuality.ultra, localizations.ultraQuality),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'cache',
        child: Row(
          children: [
            const Icon(Icons.storage),
            const SizedBox(width: 8),
            Text(localizations.cacheOptions),
          ],
        ),
      ),
    ];
  }

  /// Create menu item for quality selection
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

  /// Create page number display
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

  /// Create loading status screen
  Widget _buildLoadingView() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildProgressCircle(),
            const SizedBox(height: 24),
            Text(
              localizations.processing,
              style: const TextStyle(fontSize: 18, color: Colors.white),
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

  /// Create progress circle
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

  /// Create progress text
  Widget _buildProgressText() {
    return Text(
      processingProgress > 0
          ? 'Processing ${(processingProgress * 100).toInt()}% | Converting PDF pages...'
          : 'Starting PDF processing...',
      style: const TextStyle(fontSize: 14, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  /// Create Progress Bar
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

  /// Create error display screen
  Widget _buildErrorView() {
    final localizations = AppLocalizations.of(context)!;
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
              child: Text(localizations.tryAgain),
            ),
          ],
        ),
      ),
    );
  }

  /// Create screen when no PDF pages found
  Widget _buildEmptyView() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black,
      child: Center(
        child: Text(
          localizations.noPagesFound,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  /// Create PDF display screen
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

  /// Create last page
  Widget _buildLastPage() {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              localizations.endOfDocument,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.thankYou,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clear document cache when closing screen
    PdfDocumentCache.clearCache();
    // Don't disable wakelock here as we might return to main screen and still want screen to stay on
    // wakelock will be managed by app lifecycle
    super.dispose();
  }
}
