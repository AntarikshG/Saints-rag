import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:math' as math;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'l10n/app_localizations.dart';
import 'articlesquotes_en.dart';

// Mood enum for better type safety
enum DiaryMood {
  peaceful,
  joyful,
  grateful,
  reflective,
  struggling,
  inspired,
}

// Extension for mood display
extension DiaryMoodExtension on DiaryMood {
  String get displayName {
    switch (this) {
      case DiaryMood.peaceful:
        return 'Peaceful';
      case DiaryMood.joyful:
        return 'Joyful';
      case DiaryMood.grateful:
        return 'Grateful';
      case DiaryMood.reflective:
        return 'Reflective';
      case DiaryMood.struggling:
        return 'Struggling';
      case DiaryMood.inspired:
        return 'Inspired';
    }
  }

  IconData get icon {
    switch (this) {
      case DiaryMood.peaceful:
        return Icons.spa;
      case DiaryMood.joyful:
        return Icons.sentiment_very_satisfied;
      case DiaryMood.grateful:
        return Icons.favorite;
      case DiaryMood.reflective:
        return Icons.self_improvement;
      case DiaryMood.struggling:
        return Icons.psychology;
      case DiaryMood.inspired:
        return Icons.stars;
    }
  }

  Color get color {
    switch (this) {
      case DiaryMood.peaceful:
        return Colors.teal;
      case DiaryMood.joyful:
        return Colors.amber;
      case DiaryMood.grateful:
        return Colors.pink;
      case DiaryMood.reflective:
        return Colors.deepPurple;
      case DiaryMood.struggling:
        return Colors.orange;
      case DiaryMood.inspired:
        return Colors.indigo;
    }
  }

  static DiaryMood? fromString(String? value) {
    if (value == null) return null;
    return DiaryMood.values.firstWhere(
      (e) => e.toString() == value,
      orElse: () => DiaryMood.reflective,
    );
  }
}

// Tags for categorization
const List<String> DIARY_TAGS = [
  'Meditation',
  'Prayer',
  'Gratitude',
  'Insights',
  'Challenges',
  'Goals',
  'Dreams',
  'Lessons',
  'Scripture',
  'Service',
];

class SpiritualDiaryPage extends StatefulWidget {
  @override
  _SpiritualDiaryPageState createState() => _SpiritualDiaryPageState();
}

class _SpiritualDiaryPageState extends State<SpiritualDiaryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  Database? _db;
  List<Map<String, dynamic>> _entries = [];
  List<Map<String, dynamic>> _filteredEntries = [];

  // New entry state
  DiaryMood? _selectedMood;
  List<String> _selectedTags = [];
  String? _dailyPrompt;
  String? _promptSaint;
  int? _editingEntryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initDbAndLoadEntries();
    _generateDailyPrompt();
  }

  void _generateDailyPrompt() {
    final random = math.Random();
    final saint = saintsEn[random.nextInt(saintsEn.length)];
    final quote = saint.quotes[random.nextInt(saint.quotes.length)];
    setState(() {
      _dailyPrompt = quote;
      _promptSaint = saint.name;
    });
  }

  Future<void> _initDbAndLoadEntries() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'spiritual_diary.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS diary_entries(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, created_at TEXT, title TEXT, mood TEXT, tags TEXT, updated_at TEXT)'
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Add new columns if upgrading from old version
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE diary_entries ADD COLUMN mood TEXT');
          await db.execute('ALTER TABLE diary_entries ADD COLUMN tags TEXT');
          await db.execute('ALTER TABLE diary_entries ADD COLUMN updated_at TEXT');
        }
      },
      version: 2,
    );
    _db = db;
    await _loadEntries();
    setState(() {
      _loading = false;
    });
  }

  Future<void> _loadEntries() async {
    if (_db == null) return;
    final List<Map<String, dynamic>> entries = await _db!.query(
      'diary_entries',
      orderBy: 'created_at DESC',
    );
    setState(() {
      _entries = entries;
      _applyFilters();
    });
  }

  void _applyFilters() {
    final searchTerm = _searchController.text.toLowerCase();
    setState(() {
      _filteredEntries = _entries.where((entry) {
        final content = (entry['content'] ?? '').toString().toLowerCase();
        final matchesSearch = searchTerm.isEmpty || content.contains(searchTerm);
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _saveEntry() async {
    if (_db == null || _controller.text.trim().isEmpty) return;

    final now = DateTime.now();
    final title = _controller.text.trim().length > 50
        ? _controller.text.trim().substring(0, 50) + '...'
        : _controller.text.trim();

    final entryData = {
      'content': _controller.text.trim(),
      'title': title,
      'mood': _selectedMood?.toString(),
      'tags': _selectedTags.join(','),
      'updated_at': now.toIso8601String(),
    };

    if (_editingEntryId != null) {
      // Update existing entry
      await _db!.update(
        'diary_entries',
        entryData,
        where: 'id = ?',
        whereArgs: [_editingEntryId],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry updated successfully!')),
      );
    } else {
      // Insert new entry
      entryData['created_at'] = now.toIso8601String();
      await _db!.insert('diary_entries', entryData);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry saved successfully!')),
      );
    }

    _controller.clear();
    setState(() {
      _selectedMood = null;
      _selectedTags = [];
      _editingEntryId = null;
    });
    await _loadEntries();
  }

  void _editEntry(Map<String, dynamic> entry) {
    setState(() {
      _editingEntryId = entry['id'];
      _controller.text = entry['content'] ?? '';
      _selectedMood = DiaryMoodExtension.fromString(entry['mood']);
      _selectedTags = entry['tags'] != null && entry['tags'].toString().isNotEmpty
          ? entry['tags'].toString().split(',')
          : [];
      // Switch to Write tab
      _tabController.animateTo(0);
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingEntryId = null;
      _controller.clear();
      _selectedMood = null;
      _selectedTags = [];
    });
  }

  Future<void> _exportDiary() async {
    if (_entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No entries to export')),
      );
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spiritual_diary_export.txt');

      String exportContent = 'Spiritual Diary Export\n';
      exportContent += '=' * 30 + '\n\n';

      for (var entry in _entries.reversed) {
        final date = DateTime.parse(entry['created_at']);
        exportContent += 'Date: ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}\n';

        // Add mood if present
        if (entry['mood'] != null && entry['mood'].toString().isNotEmpty) {
          final mood = DiaryMoodExtension.fromString(entry['mood']);
          exportContent += 'Mood: ${mood?.displayName ?? ''}\n';
        }

        // Add tags if present
        if (entry['tags'] != null && entry['tags'].toString().isNotEmpty) {
          exportContent += 'Tags: ${entry['tags']}\n';
        }

        exportContent += '-' * 40 + '\n';
        exportContent += '${entry['content']}\n\n';
        exportContent += '=' * 40 + '\n\n';
      }

      await file.writeAsString(exportContent);

      // Get share position origin for iOS
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Spiritual Diary Export',
        subject: 'Spiritual Diary',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting diary: $e')),
      );
    }
  }

  Future<void> _deleteEntry(int id) async {
    if (_db == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Entry'),
        content: Text('Are you sure you want to delete this entry?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db!.delete('diary_entries', where: 'id = ?', whereArgs: [id]);
      await _loadEntries();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Entry deleted')),
      );
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final entryDate = DateTime(date.year, date.month, date.day);

    if (entryDate == today) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (entryDate == today.subtract(Duration(days: 1))) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    _searchController.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.spiritualDiary),
        actions: [
          if (_entries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.share),
              onPressed: _exportDiary,
              tooltip: 'Export Diary',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.edit), text: 'Write'),
            Tab(icon: Icon(Icons.library_books), text: 'Entries'),
          ],
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Write Tab
                _buildWriteTab(isDark),
                // Entries Tab
                _buildEntriesTab(isDark),
              ],
            ),
    );
  }

  // Write Tab - Full space for writing
  Widget _buildWriteTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Daily Prompt Card
          if (_dailyPrompt != null && _editingEntryId == null)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.deepPurple.shade800, Colors.indigo.shade900]
                      : [Colors.deepPurple.shade50, Colors.indigo.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.deepPurple.shade700 : Colors.deepPurple.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Daily Reflection Prompt',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.amber.shade200 : Colors.deepPurple.shade700,
                        ),
                      ),
                      Spacer(),
                      IconButton(
                        icon: Icon(Icons.refresh, size: 18),
                        onPressed: _generateDailyPrompt,
                        tooltip: 'New prompt',
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '"$_dailyPrompt"',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '— $_promptSaint',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.deepPurple.shade200 : Colors.deepPurple.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Entry Form
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        _editingEntryId != null ? 'Edit Entry' : 'Write a new entry',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_editingEntryId != null) ...[
                        Spacer(),
                        TextButton.icon(
                          onPressed: _cancelEdit,
                          icon: Icon(Icons.close, size: 18),
                          label: Text('Cancel'),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 16),

                  // Mood Selector
                  Text(
                    'How are you feeling?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DiaryMood.values.map((mood) {
                      final isSelected = _selectedMood == mood;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMood = isSelected ? null : mood;
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? mood.color.withOpacity(0.2) : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? mood.color : Colors.grey.shade400,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(mood.icon, size: 18, color: mood.color),
                              SizedBox(width: 6),
                              Text(
                                mood.displayName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 16),

                  // Tags Selector
                  Text(
                    'Add tags (optional)',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: DIARY_TAGS.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag, style: TextStyle(fontSize: 11)),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        selectedColor: Colors.deepOrange.withOpacity(0.3),
                        checkmarkColor: Colors.deepOrange,
                      );
                    }).toList(),
                  ),

                  SizedBox(height: 16),

                  // Text Field - More space for writing
                  TextField(
                    controller: _controller,
                    maxLines: 10, // Increased from 5 to 10
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Share your thoughts, reflections, and spiritual insights...',
                      hintStyle: TextStyle(fontSize: 14),
                    ),
                  ),
                  SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _saveEntry,
                    icon: Icon(_editingEntryId != null ? Icons.save : Icons.add),
                    label: Text(_editingEntryId != null ? 'Update Entry' : 'Add Entry'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Recent Entries Preview (only show if not editing)
          if (_editingEntryId == null && _entries.isNotEmpty) ...[
            SizedBox(height: 24),
            Row(
              children: [
                Text(
                  'Recent Entries',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                TextButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: Icon(Icons.arrow_forward, size: 16),
                  label: Text('View All'),
                ),
              ],
            ),
            SizedBox(height: 8),
            ..._entries.take(3).map((entry) {
              final mood = DiaryMoodExtension.fromString(entry['mood']);
              return Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: mood != null
                      ? Icon(mood.icon, color: mood.color)
                      : Icon(Icons.note),
                  title: Text(
                    entry['content'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatDate(entry['created_at'])),
                  onTap: () => _showEntryDetails(entry),
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  // Entries Tab - Full space for viewing entries
  Widget _buildEntriesTab(bool isDark) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search entries...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
                      },
                    )
                  : IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                      tooltip: 'Filter',
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) => _applyFilters(),
          ),
        ),

        // Entries List
        Expanded(
          child: _filteredEntries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchController.text.isEmpty ? Icons.book : Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? 'No entries yet'
                            : 'No matching entries',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      Text(
                        _searchController.text.isEmpty
                            ? 'Start writing your spiritual journey'
                            : 'Try a different search term',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = _filteredEntries[index];
                    final mood = DiaryMoodExtension.fromString(entry['mood']);
                    final tags = entry['tags'] != null && entry['tags'].toString().isNotEmpty
                        ? entry['tags'].toString().split(',')
                        : <String>[];

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: mood != null
                              ? mood.color.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showEntryDetails(entry),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (mood != null) ...[
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: mood.color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(mood.icon, size: 18, color: mood.color),
                                    ),
                                    SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      _formatDate(entry['created_at']),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editEntry(entry);
                                      } else if (value == 'delete') {
                                        _deleteEntry(entry['id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (tags.isNotEmpty) ...[
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: tags.map((tag) => Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.deepOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.deepOrange.shade200),
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(fontSize: 10, color: Colors.deepOrange.shade700),
                                    ),
                                  )).toList(),
                                ),
                              ],
                              SizedBox(height: 8),
                              Text(
                                entry['content'],
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showFilterDialog() {
    // TODO: Implement advanced filtering by mood and tags
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Options'),
        content: Text('Advanced filtering coming soon!\n\nYou can currently:\n• Search by text\n• Filter by mood (coming soon)\n• Filter by tags (coming soon)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEntryDetails(Map<String, dynamic> entry) {
    final mood = DiaryMoodExtension.fromString(entry['mood']);
    final tags = entry['tags'] != null && entry['tags'].toString().isNotEmpty
        ? entry['tags'].toString().split(',')
        : <String>[];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: mood?.color.withOpacity(0.2) ?? Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    if (mood != null) ...[
                      Icon(mood.icon, color: mood.color),
                      SizedBox(width: 8),
                      Text(
                        mood.displayName,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ] else
                      Text(
                        'Entry Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(entry['created_at']),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (tags.isNotEmpty) ...[
                        SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tags.map((tag) => Chip(
                            label: Text(tag, style: TextStyle(fontSize: 11)),
                            backgroundColor: Colors.deepOrange.withOpacity(0.1),
                          )).toList(),
                        ),
                      ],
                      SizedBox(height: 16),
                      Text(
                        entry['content'],
                        style: TextStyle(fontSize: 15, height: 1.6),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _editEntry(entry);
                      },
                      icon: Icon(Icons.edit),
                      label: Text('Edit'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
