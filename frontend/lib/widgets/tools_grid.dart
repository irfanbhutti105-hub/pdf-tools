import 'package:flutter/material.dart';

import '../models/pdf_tool.dart';
import 'tool_card.dart';

class ToolsGrid extends StatelessWidget {
  final List<PdfTool> tools;
  final bool isWide;
  final int startIndex;

  const ToolsGrid({
    super.key,
    required this.tools,
    required this.isWide,
    this.startIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = isWide
        ? 4
        : width > 600
            ? 3
            : 2;

    // Taller cells on phones so title + subtitle + icon fit without overflow.
    final childAspectRatio = isWide
        ? 1.08
        : width > 600
            ? 0.88
            : 0.76;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: tools.length,
      itemBuilder: (context, i) => ToolCard(
        tool: tools[i],
        index: startIndex + i,
      ),
    );
  }
}
