import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'l10n/app_localizations.dart';

class SpiritualDiaryPage extends StatefulWidget {
  @override
  _SpiritualDiaryPageState createState() => _SpiritualDiaryPageState();
}

class _SpiritualDiaryPageState extends State<SpiritualDiaryPage> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  Database? _db;
  List<Map<String, dynamic>> _entries = [];

  @override
  void initState() {
    super.initState();
    _initDbAndLoadEntries();
  }

  Future<void> _initDbAndLoadEntries() async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'spiritual_diary.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE IF NOT EXISTS diary_entries(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT, created_at TEXT, title TEXT)'
        );
      },
      version: 1,
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
    });
  }

  Future<void> _saveEntry() async {
    if (_db == null || _controller.text.trim().isEmpty) return;

    final now = DateTime.now();
    final title = _controller.text.trim().length > 50
        ? _controller.text.trim().substring(0, 50) + '...'
        : _controller.text.trim();

    await _db!.insert('diary_entries', {
      'content': _controller.text.trim(),
      'created_at': now.toIso8601String(),
      'title': title,
    });

    _controller.clear();
    await _loadEntries();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entry saved successfully!')),
    );
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
    _controller.dispose();
    _db?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
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
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // New entry section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Write a new entry',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _controller,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Share your thoughts, reflections, and spiritual insights...',
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _saveEntry,
                        icon: Icon(Icons.add),
                        label: Text('Add Entry'),
                      ),
                    ],
                  ),
                ),
                // Entries list
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No entries yet',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start writing your spiritual journey',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDate(entry['created_at']),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, size: 20),
                                          onPressed: () => _deleteEntry(entry['id']),
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      entry['content'],
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
