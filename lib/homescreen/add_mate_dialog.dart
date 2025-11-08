import 'dart:async';
import 'package:flutter/material.dart';
import 'package:passage/models/user.dart';
import 'package:passage/services/mate_service.dart';
import 'package:passage/services/user_service.dart';

class AddMateDialog extends StatefulWidget {
  const AddMateDialog({super.key});

  @override
  State<AddMateDialog> createState() => _AddMateDialogState();
}

class _AddMateDialogState extends State<AddMateDialog> {
  late final TextEditingController _searchController;
  final UserService _userService = UserService();
  final MateService _mateService = MateService();
  List<User> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Cancel previous debounce timer
    _searchDebounce?.cancel();

    setState(() {
      _searchQuery = query;
      if (query.length < 2) {
        _searchResults = [];
        _isSearching = false;
      }
    });

    if (query.length < 2) {
      return;
    }

    // Debounce search to avoid too many API calls
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _userService.searchUsers(query);
      if (!mounted) return;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMate(User user) async {
    try {
      await _mateService.addMateRequest(user.username);
      if (!mounted) return;

      Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Mate request sent')));
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mate'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by username or email',
                hintText: 'Enter username or email',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else if (_searchResults.isEmpty && _searchQuery.length >= 2)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No users found'),
              )
            else if (_searchResults.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(user.initials)),
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      trailing: ElevatedButton(
                        onPressed: () => _addMate(user),
                        child: const Text('Add'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
