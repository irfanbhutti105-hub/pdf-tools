# Installing Poppler on Windows

## What is Poppler?
Poppler is a PDF rendering library required for several PDF operations including:
- PDF to Images (JPG conversion)
- PDF to Excel (table extraction)
- Some other PDF manipulation tools

## Installation Steps

### Option 1: Using Chocolatey (Easiest)

If you have Chocolatey installed:
```bash
choco install poppler
```

### Option 2: Manual Installation

#### Step 1: Download Poppler
1. Go to: https://github.com/oschwartz10612/poppler-windows/releases
2. Download the latest `Release-XX.XX.X-0.zip` file
3. Extract the ZIP file to a permanent location, e.g., `C:\Program Files\poppler`

#### Step 2: Add Poppler to System PATH

1. **Extract the ZIP** to `C:\poppler` (or your preferred location)
2. **Open System Environment Variables:**
   - Press `Win + R`
   - Type `sysdm.cpl` and press Enter
   - Go to the "Advanced" tab
   - Click "Environment Variables"

3. **Add to PATH:**
   - Under "System variables", find and select `Path`
   - Click "Edit"
   - Click "New"
   - Add: `C:\poppler\Library\bin` (adjust path if you extracted elsewhere)
   - Click "OK" on all dialogs

4. **Restart your terminal/IDE** to apply the changes

#### Step 3: Verify Installation

Open a new command prompt and run:
```bash
pdftoppm -h
```

If installed correctly, you should see the help text for pdftoppm.

---

## Restart Backend Server

After installing Poppler, restart your backend server:

```bash
cd backend
python main.py
```

---

## Which Tools Need Poppler?

The following tools in your app require Poppler:

1. ✅ **PDF to JPG** - Converts PDF pages to images
2. ✅ **PDF to Excel** - Uses `tabula-py` which depends on Poppler
3. ⚠️ Some other conversion tools may also benefit from Poppler

---

## Troubleshooting

### "poppler not found" error persists:

1. **Verify PATH is set correctly:**
   ```bash
   echo %PATH%
   ```
   Should include your Poppler bin directory

2. **Try absolute path in code:**
   If PATH doesn't work, you can modify the backend code to use absolute path to Poppler

3. **Restart everything:**
   - Close all terminal windows
   - Close your IDE
   - Reopen and try again

### Alternative: Use WSL or Linux

If you have WSL installed, Poppler installation is simpler:
```bash
sudo apt-get update
sudo apt-get install poppler-utils
```

---

## For Other Operating Systems

### macOS:
```bash
brew install poppler
```

### Linux (Ubuntu/Debian):
```bash
sudo apt-get install poppler-utils
```

### Linux (Fedora):
```bash
sudo dnf install poppler-utils
```

---

**After installation, restart your backend server and try the PDF to Images tool again!**
