import 'package:flutter/material.dart';

class PdfPageWidget extends StatelessWidget {
  final Widget child;
  final int pageNumber;
  final int totalPages;

  const PdfPageWidget({
    super.key,
    required this.child,
    required this.pageNumber,
    required this.totalPages,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(12.0), child: child),
    );
  }
}
