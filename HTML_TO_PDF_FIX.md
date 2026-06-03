# HTML to PDF - Bug Fix

## Issue
The HTML to PDF tool was not working - no API requests were being sent to the backend.

## Root Cause
The `_processFiles()` method was checking for file uploads at the beginning and throwing an error before reaching the HTML URL to PDF logic. The flow was:

1. User enters URL in HTML to PDF screen
2. Clicks "Convert to PDF" button
3. `_processFiles()` tries to build a `files` list from `_pickedFiles`
4. Since no files were selected (it's a URL input), `files` is empty
5. Method throws exception: "Could not read file data. Please try again."
6. Never reaches the `switch` case that handles `html-url-to-pdf`

## Solution
Moved the `html-url-to-pdf` handling to the TOP of `_processFiles()` method, before any file validation logic.

### Code Changes in `lib/screens/tool_screen.dart`:

**Before:**
```dart
Future<void> _processFiles() async {
  List<PlatformFile> files = [];

  if (_tool!.id == 'text-to-pdf') {
    // ... text to pdf logic
  } else {
    files = _pickedFiles.where((f) => f.bytes != null).toList();
  }

  if (files.isEmpty) {
    throw Exception('Could not read file data. Please try again.');
  }
  
  // ... later in switch statement
  case 'html-url-to-pdf':
    response = await PdfApiService.htmlUrlToPdf(_htmlUrl, ...);
    break;
}
```

**After:**
```dart
Future<void> _processFiles() async {
  List<PlatformFile> files = [];

  // Special handling for HTML URL to PDF - no files needed
  if (_tool!.id == 'html-url-to-pdf') {
    if (_htmlUrl.isEmpty) {
      throw Exception('Please enter a valid URL');
    }
    
    onProgress(int sent, int total) {
      setState(() => _uploadProgress = sent / total);
    }
    
    final response = await PdfApiService.htmlUrlToPdf(_htmlUrl,
        onSendProgress: onProgress);
    
    if (response.data != null) {
      setState(() => _resultBytes = response.data);
    }
    return; // Exit early, no file processing needed
  }

  // Handle other tools that need files
  if (_tool!.id == 'text-to-pdf') {
    // ... rest of the method
  }
}
```

## Testing
After this fix:
1. ✅ HTML to PDF screen displays correctly with URL input field
2. ✅ User can enter a URL (e.g., https://example.com)
3. ✅ Clicking "Convert to PDF" sends API request to backend
4. ✅ Backend processes the URL and converts webpage to PDF
5. ✅ Frontend receives and downloads the PDF file

## Backend Requirement
The backend needs `xhtml2pdf` package installed:
```bash
pip install xhtml2pdf
```

If you see an error about xhtml2pdf, run:
```bash
cd backend
pip install -r requirements.txt
```

## Status
✅ **FIXED** - HTML to PDF now works correctly!

The tool will:
- Accept any valid URL (http:// or https://)
- Fetch the webpage content
- Convert it to PDF
- Return the PDF file for download
