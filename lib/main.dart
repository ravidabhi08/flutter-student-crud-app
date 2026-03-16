import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/student.dart';
import 'services/favorite_service.dart';
import 'services/local_db.dart';
import 'widgets/student_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  var firebaseConfigured = true;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    firebaseConfigured = false;
  }

  runApp(MyApp(firebaseConfigured: firebaseConfigured));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.firebaseConfigured = true});

  final bool firebaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CRUD App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: HomePage(firebaseConfigured: firebaseConfigured),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.firebaseConfigured});

  final bool firebaseConfigured;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  final _db = LocalDatabase.instance;
  final _favorites = FavoriteService.instance;

  bool _isLoading = true;
  String _searchQuery = '';
  List<Student> _students = [];
  Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final students = await _db.getStudents(query: _searchQuery);

      Set<int> favorites = {};
      if (widget.firebaseConfigured) {
        favorites = await _favorites.loadFavorites();
      }

      setState(() {
        _favoriteIds = favorites;
        _students =
            students
                .map((student) => student.copyWith(isFavorite: favorites.contains(student.id)))
                .toList();
      });
    } catch (e) {
      // Firebase is optional for local CRUD operations.
      debugPrint('Error loading data: $e');
      final students = await _db.getStudents(query: _searchQuery);
      setState(() {
        _students =
            students
                .map((student) => student.copyWith(isFavorite: _favoriteIds.contains(student.id)))
                .toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query == _searchQuery) return;
    _searchQuery = query;
    _loadData();
  }

  Future<void> _showAddStudent() async {
    final student = await StudentDialog.show(context, title: 'Add record');
    if (student == null) return;

    await _db.insertStudent(student);
    await _loadData();
  }

  Future<void> _showEditStudent(Student student) async {
    final updated = await StudentDialog.show(context, title: 'Edit record', initial: student);
    if (updated == null) return;

    await _db.updateStudent(updated);

    setState(() {
      _students =
          _students.map((s) {
            if (s.id == updated.id) {
              return updated.copyWith(isFavorite: s.isFavorite);
            }
            return s;
          }).toList();
    });

    // If this record is marked as favorite, keep the Firebase copy in sync.
    if (student.id != null && _favoriteIds.contains(student.id)) {
      await _favorites.setFavorite(updated, true);
    }

    await _loadData();
  }

  Future<void> _deleteStudent(Student student) async {
    final confirmed = await showDialog<bool?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete record'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (student.id != null) {
      await _db.deleteStudent(student.id!);
      setState(() {
        _students.removeWhere((s) => s.id == student.id);
      });
      // Remove from favorites if it existed
      if (_favoriteIds.contains(student.id)) {
        await _favorites.setFavorite(student, false);
      }
      await _loadData();
    }
  }

  Future<void> _toggleFavorite(Student student) async {
    final newValue = !(student.isFavorite);

    if (student.id == null) return;

    setState(() {
      _students =
          _students.map((s) {
            if (s.id == student.id) {
              return s.copyWith(isFavorite: newValue);
            }
            return s;
          }).toList();
      if (newValue) {
        _favoriteIds.add(student.id!);
      } else {
        _favoriteIds.remove(student.id!);
      }
    });

    if (!widget.firebaseConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase is not configured. Favorites are stored locally only.'),
        ),
      );
      return;
    }

    try {
      await _favorites.setFavorite(student, newValue);
    } catch (e) {
      debugPrint('Failed to update favorite: $e');
      // Revert the local state
      setState(() {
        _students =
            _students.map((s) {
              if (s.id == student.id) {
                return s.copyWith(isFavorite: !newValue);
              }
              return s;
            }).toList();
        if (!newValue) {
          _favoriteIds.add(student.id!);
        } else {
          _favoriteIds.remove(student.id!);
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update favorite: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reload', onPressed: _loadData),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, address or id',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _students.isEmpty
              ? Center(
                child: Text(
                  _searchQuery.isNotEmpty
                      ? 'No records found matching "$_searchQuery".'
                      : 'No records found.',
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: _students.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final student = _students[index];
                  return Card(
                    child: ListTile(
                      leading: IconButton(
                        icon: Icon(
                          student.isFavorite ? Icons.star : Icons.star_border,
                          color: student.isFavorite ? Colors.amber : null,
                        ),
                        onPressed: () => _toggleFavorite(student),
                        tooltip: student.isFavorite ? 'Remove favorite' : 'Mark favorite',
                      ),
                      title: Text(student.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${student.id ?? '-'}'),
                          Text('Age: ${student.age}'),
                          Text(student.address),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            tooltip: 'Edit',
                            onPressed: () => _showEditStudent(student),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            tooltip: 'Delete',
                            onPressed: () => _deleteStudent(student),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudent,
        tooltip: 'Add record',
        child: const Icon(Icons.add),
      ),
    );
  }
}
