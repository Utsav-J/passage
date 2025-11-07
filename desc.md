# Frontend Summary - Passage EPUB Reader

**Target Audience**: Backend Developers

This document provides a technical overview of the Passage frontend application architecture, data models, storage patterns, and API integration points for backend developers.

---

## 📱 Application Overview

**Passage** is a Flutter-based EPUB reader mobile application with social reading features. The app allows users to:
- Read EPUB books with a modern, customizable interface
- Bookmark pages and highlight text passages
- Track reading progress per book
- Share reading snippets with friends (planned feature)
- Switch between multiple reading themes

**Tech Stack**:
- **Framework**: Flutter 3.9.2+
- **Language**: Dart
- **Key Dependencies**:
  - `flutter_epub_viewer` - EPUB rendering engine
  - `shared_preferences` - Local key-value storage
  - `flutter_screenutil` - Responsive UI scaling
  - `epubx` - EPUB metadata extraction
  - `file_picker` - File selection

---

## 🏗️ App Architecture

### Navigation Structure

```
PassageApp (MaterialApp)
├── HomeScreen (2 tabs)
│   ├── My Books Tab
│   │   └── Grid of book cards + Discover section
│   └── My Mates Tab
│       └── Social feed of shared snippets
└── EpubReaderPage (Reader view)
    ├── Chapter navigation drawer
    ├── Reading controls (search, font size)
    └── EPUB content viewer
```

### Key Screens

#### 1. **Home Screen** (`home_screen.dart`)
- **Primary Tab**: "My Books" - displays user's library in a responsive grid
- **Secondary Tab**: "My Mates" - social feed showing shared reading snippets from friends
- Features:
  - Book cover display (extracted from EPUB or gradient placeholder)
  - Reading progress bar on each book card
  - Theme switcher (4 themes: Light, Dark, AMOLED, Night)
  - FAB for adding books / sharing snippets (UI only)

#### 2. **EPUB Reader Page** (`epub_reader_page.dart`)
- Full-screen paginated EPUB reader
- Navigation drawer with:
  - Chapter table of contents
  - Bookmarks list
  - Highlights list
  - Reading progress indicator
- App bar controls:
  - Font size adjustment (+/-)
  - Bookmark toggle (current page)
  - File picker (open new EPUB)
  - Reader controls modal (search, etc.)
- Text selection menu:
  - Highlight in multiple colors
- Exit confirmation dialog (saves progress)

---

## 💾 Data Models

### Core Models

All models are located in `lib/reader/models/`

#### **Bookmark** (`bookmark.dart`)

```dart
class Bookmark {
  String label;       // Display name (e.g., "Page 42")
  String cfi;         // CFI (Canonical Fragment Identifier) - unique location in EPUB
  int? pageNumber;    // Optional page number
}
```

**JSON Structure**:
```json
{
  "label": "Page 42",
  "cfi": "epubcfi(/6/14[chap05]!/4/2/12,/1:0,/1:42)",
  "pageNumber": 42
}
```

#### **Highlight** (`highlight.dart`)

```dart
class Highlight {
  String cfi;        // Location in EPUB
  Color color;       // Highlight color (stored as int)
  String text;       // Selected text content
}
```

**JSON Structure**:
```json
{
  "cfi": "epubcfi(/6/14[chap05]!/4/2/12,/1:0,/1:42)",
  "color": 4294961979,  // Color.value (ARGB integer)
  "text": "The quick brown fox jumps over the lazy dog"
}
```

### Display Models (UI Only)

These are **not persisted** and used only for UI rendering:

- `_BookData` - Book card display data (title, author, progress, cover image)
- `_MateMessage` - Social feed message (sender, snippet, book, reactions)

---

## 🗄️ Local Storage

The app uses `shared_preferences` (key-value storage) for all data persistence.

### Storage Service: `EpubSettingsService`

Location: `lib/reader/services/epub_settings_service.dart`

#### Global Keys

| Key | Type | Description |
|-----|------|-------------|
| `font_size` | double | Global font size preference (12-28, default: 16) |
| `app_theme_mode` | string | Theme name: "light", "dark", "amoled", "night" |

#### Book-Specific Keys

Format: `book_{bookId}_{suffix}`

**Book ID**: Currently uses asset path (e.g., `assets/books/sample.epub`) as the unique identifier. For backend integration, this should become a stable book UUID/ISBN.

| Suffix | Type | Description |
|--------|------|-------------|
| `bookmarks` | JSON array | List of bookmarks for this book |
| `highlights` | JSON array | List of highlights for this book |
| `last_cfi` | string | Last reading position (CFI string) |
| `max_progress` | double | Furthest reading progress (0.0 - 1.0) |

#### Example Storage Keys

```
// Global
font_size: 18.0
app_theme_mode: "dark"

// Book-specific (bookId = "assets/books/sample.epub")
book_assets/books/sample.epub_bookmarks: "[{\"label\":\"Page 5\",\"cfi\":\"...\"}]"
book_assets/books/sample.epub_highlights: "[{\"cfi\":\"...\",\"color\":4294961979,\"text\":\"...\"}]"
book_assets/books/sample.epub_last_cfi: "epubcfi(/6/14[chap05]!/4/2/12)"
book_assets/books/sample.epub_max_progress: 0.42
```

### Storage Patterns

1. **Read on Init**: Settings loaded when reader opens
2. **Write on Change**: Immediate persistence when user adds bookmark/highlight
3. **Write on Navigate**: Position saved on page turn
4. **Write on Exit**: Final position save in `dispose()` and exit dialog

---

## 🎨 Theme System

### Available Themes

Location: `lib/theme/app_theme.dart`

| Theme | Description | Use Case |
|-------|-------------|----------|
| **Light** | Standard light mode | Indigo color scheme, white background |
| **Dark** | Standard dark mode | Dark grey background (#121212) |
| **AMOLED** | Pure black theme | Battery saving for OLED screens |
| **Night** | Warm sepia theme | Reduced eye strain, reading before sleep |

Theme selection is persisted globally and applies to entire app.

---

## 📚 EPUB Processing

### File Sources

The reader supports two EPUB sources:
1. **Asset Bundle**: Pre-packaged EPUB in `assets/books/` (e.g., sample.epub)
2. **File System**: User-selected EPUB via file picker

### Metadata Extraction

On book load, the app extracts:
- Title (fallback: "Sample EPUB")
- Author(s) (fallback: "Unknown Author")
- Cover image (decoded to PNG bytes for display)
- Chapter list (table of contents)

### CFI (Canonical Fragment Identifier)

**What is CFI?**
CFI is an EPUB standard for identifying precise locations within an EPUB document. Think of it as a "deep link" into the book.

**Example CFI**:
```
epubcfi(/6/14[chap05]!/4/2/12,/1:0,/1:42)
```

**Uses**:
- Bookmarks point to CFI locations
- Highlights reference CFI ranges
- Reading position stored as CFI
- Search results return CFI coordinates

---

## 🔌 Backend Integration Points

### Current State: Offline-First

The app currently operates **entirely offline** using local storage. No network requests are made.

### Recommended Backend API Endpoints

Here are suggested endpoints to sync user data and enable social features:

#### **Authentication**
```
POST /api/auth/login
POST /api/auth/register
POST /api/auth/logout
```

#### **Library Management**
```
GET    /api/books              # User's library
POST   /api/books              # Add book to library
DELETE /api/books/{bookId}     # Remove from library
GET    /api/books/discover     # Curated recommendations
```

#### **Reading Progress**
```
GET  /api/books/{bookId}/progress
PUT  /api/books/{bookId}/progress
```
**Request Body**:
```json
{
  "cfi": "epubcfi(/6/14[chap05]!/4/2/12)",
  "progress": 0.42,
  "lastRead": "2025-11-06T12:30:00Z"
}
```

#### **Bookmarks**
```
GET    /api/books/{bookId}/bookmarks
POST   /api/books/{bookId}/bookmarks
DELETE /api/books/{bookId}/bookmarks/{bookmarkId}
```
**Bookmark Object**:
```json
{
  "id": "uuid",
  "label": "Page 42",
  "cfi": "epubcfi(...)",
  "pageNumber": 42,
  "createdAt": "2025-11-06T12:30:00Z"
}
```

#### **Highlights**
```
GET    /api/books/{bookId}/highlights
POST   /api/books/{bookId}/highlights
DELETE /api/books/{bookId}/highlights/{highlightId}
```
**Highlight Object**:
```json
{
  "id": "uuid",
  "cfi": "epubcfi(...)",
  "text": "The quick brown fox...",
  "color": "#FFFF00",
  "note": "optional user note",
  "createdAt": "2025-11-06T12:30:00Z"
}
```

#### **Social Features** ("My Mates")
```
GET  /api/feed                 # Get social feed
POST /api/snippets             # Share a snippet
POST /api/snippets/{id}/react  # React to shared snippet
GET  /api/friends              # Friend list
POST /api/friends              # Add friend
```
**Snippet Object**:
```json
{
  "id": "uuid",
  "userId": "user-id",
  "userName": "Alex Carter",
  "bookId": "book-id",
  "bookTitle": "Atomic Habits",
  "text": "We are what we repeatedly do...",
  "cfi": "epubcfi(...)",
  "reactions": [
    {"emoji": "🔥", "count": 12},
    {"emoji": "👏", "count": 4}
  ],
  "createdAt": "2025-11-06T12:30:00Z"
}
```

#### **User Settings**
```
GET  /api/users/me/settings
PUT  /api/users/me/settings
```
**Settings Object**:
```json
{
  "fontSize": 18.0,
  "theme": "dark",
  "notifications": true
}
```

---

## 📊 Data Flow Examples

### Adding a Bookmark

```
1. User taps bookmark icon in reader
2. Reader extracts current CFI from EpubController
3. Creates Bookmark object with label and CFI
4. Adds to local _bookmarks list (setState)
5. Calls EpubSettingsService.persistSettings()
6. SharedPreferences stores JSON array
[FUTURE: POST to /api/books/{bookId}/bookmarks]
```

### Opening a Book

```
1. User taps book card on home screen
2. Navigates to EpubReaderPage with assetPath
3. Reader loads EPUB via EpubController
4. Calls EpubSettingsService.restoreSettings(bookId)
5. Loads bookmarks, highlights, last position
6. Displays book at saved CFI
7. Re-applies saved highlights to DOM
[FUTURE: GET from /api/books/{bookId}/progress]
```

### Sharing a Snippet (Planned)

```
[FUTURE FLOW]
1. User highlights text and taps "Share"
2. Creates snippet with CFI, text, bookId
3. POST to /api/snippets
4. Appears in friends' "My Mates" feed
5. Friends can react with emojis
```

---

## 🔐 Security Considerations

### For Backend Implementation

1. **Book Access Control**: Ensure users can only access books they own/purchased
2. **CFI Validation**: Validate CFI strings to prevent injection attacks
3. **Rate Limiting**: Limit bookmark/highlight creation to prevent abuse
4. **Content Filtering**: Moderate shared snippets for inappropriate content
5. **Privacy Controls**: Allow