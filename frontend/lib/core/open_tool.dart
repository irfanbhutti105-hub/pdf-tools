import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pdf_tool.dart';
import '../providers/shell_navigation_provider.dart';

void openPdfTool(BuildContext context, PdfTool tool) {
  if (tool.id == 'document-scanner') {
    context.read<ShellNavigationProvider>().requestTab(kScannerTabIndex);
    return;
  }
  Navigator.pushNamed(context, '/tool/${tool.id}');
}
