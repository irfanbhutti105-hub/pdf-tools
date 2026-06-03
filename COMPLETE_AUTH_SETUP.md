# Complete Authentication Setup - FINAL STEPS

## ✅ What's Been Created

### Backend Files:
1. ✅ `backend/auth.py` - JWT authentication utilities
2. ✅ `backend/routes_auth.py` - Auth API endpoints
3. ✅ `backend/routes_history.py` - File history API
4. ✅ `backend/database.py` - Database connection
5. ✅ `backend/.env` - Environment variables
6. ✅ `backend/main.py` - Updated with auth routes

### Frontend Files:
1. ✅ `frontend/lib/models/user.dart` - User models
2. ✅ `frontend/lib/services/auth_service.dart` - Authentication service
3. ✅ `frontend/lib/services/history_service.dart` - File history service
4. ✅ `frontend/lib/screens/login_screen.dart` - Login UI
5. ✅ `frontend/lib/screens/register_screen.dart` - Register UI

---

## 📋 REMAINING STEPS TO COMPLETE

### 1. Install Flutter Packages

Add to `frontend/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  # ... existing packages ...
  
  # NEW PACKAGES TO ADD:
  shared_preferences: ^2.2.2
  jwt_decoder: ^2.0.1
```

Then run:
```bash
cd frontend
flutter pub get
```

### 2. Install Backend Packages

```bash
cd backend
pip install pyjwt python-dotenv
```

### 3. Setup PostgreSQL Database

```bash
# Create database
createdb pdf_tools

# Run schema
psql -d pdf_tools -f schema.sql
```

**OR** use existing database and just run the schema.

### 4. Update Frontend main.dart

Replace the entire `frontend/lib/main.dart` with:

```dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        brightness: Brightness.dark,
      ),
      home: const AuthCheck(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Wait a bit for splash effect
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Always go to home (guests can use app too)
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

### 5. Add Login/History Buttons to HomeScreen

Update `frontend/lib/screens/home_screen.dart` AppBar:

```dart
AppBar(
  title: Text('PDF Tools'),
  actions: [
    // History Button (only show if authenticated)
    FutureBuilder<bool>(
      future: AuthService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'File History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
          );
        }
        return const SizedBox.shrink();
      },
    ),
    // Login/Logout Button
    FutureBuilder<bool>(
      future: AuthService.isAuthenticated(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return PopupMenuButton(
            icon: const Icon(Icons.account_circle),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'history',
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('File History'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              } else if (value == 'history') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HistoryScreen(),
                  ),
                );
              }
            },
          );
        } else {
          return TextButton.icon(
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Login', style: TextStyle(color: Colors.white)),
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
          );
        }
      },
    ),
  ],
)
```

### 6. Create History Screen

Create `frontend/lib/screens/history_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/history_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<FileHistoryItem>? _items;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await HistoryService.getHistory();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(FileHistoryItem item) async {
    try {
      await HistoryService.downloadFromHistory(item.id, item.outputName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteFile(FileHistoryItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Delete ${item.outputName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await HistoryService.deleteFromHistory(item.id);
        _loadHistory();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('File History', style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                      const SizedBox(height: 16),
                      Text(_error!, style: GoogleFonts.poppins()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _items == null || _items!.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No files yet',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Processed files will appear here\nfor 24 hours',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items!.length,
                      itemBuilder: (context, index) {
                        final item = _items![index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: item.isExpired
                                  ? Colors.grey
                                  : Colors.purple.shade100,
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: item.isExpired
                                    ? Colors.white
                                    : Colors.purple.shade700,
                              ),
                            ),
                            title: Text(
                              item.outputName,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.toolName, style: GoogleFonts.poppins(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  item.timeRemainingFormatted,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: item.isExpired ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!item.isExpired)
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    onPressed: () => _downloadFile(item),
                                  ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteFile(item),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
```

---

## 🚀 Testing the Complete System

### 1. Start Backend:
```bash
cd backend
python main.py
```

### 2. Start Frontend:
```bash
cd frontend
flutter run -d chrome  # or windows
```

### 3. Test Flow:

1. **Guest User:**
   - Open app
   - Use any tool
   - Files NOT saved

2. **Register:**
   - Click "Login" in top right
   - Click "Register"
   - Create account
   - Automatically logged in

3. **Use Tools:**
   - Process any PDF
   - File saved to history

4. **View History:**
   - Click history icon
   - See all files (24 hours)
   - Download or delete files

5. **Logout:**
   - Click account icon
   - Select "Logout"

---

## ✅ DONE!

Your complete authentication system is ready with:
- Login/Register
- JWT authentication
- 24-hour file history
- Guest mode support
- File download from history
- Automatic cleanup

Run the app and test it!
