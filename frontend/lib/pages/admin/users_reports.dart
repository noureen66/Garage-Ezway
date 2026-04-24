import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersReportsPage extends StatefulWidget {
  const UsersReportsPage({super.key});

  @override
  State<UsersReportsPage> createState() => _UsersReportsPageState();
}

class _UsersReportsPageState extends State<UsersReportsPage> {
  List<String> _reports = [];
  List<bool> _checkedStates = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final savedReports = prefs.getStringList('reports') ?? [];
    final savedChecked = prefs.getStringList('reports_checked') ?? [];

    setState(() {
      _reports = savedReports;
      _checkedStates = savedChecked.map((e) => e == 'true').toList();
    });

    if (_checkedStates.length < _reports.length) {
      _checkedStates.addAll(
        List.filled(_reports.length - _checkedStates.length, false),
      );
      await _saveCheckedStates();
    }
  }

  Future<void> _saveCheckedStates() async {
    final prefs = await SharedPreferences.getInstance();
    final stringStates = _checkedStates.map((e) => e.toString()).toList();
    await prefs.setStringList('reports_checked', stringStates);
  }

  Future<void> _clearReports() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reports');
    await prefs.remove('reports_checked');
    setState(() {
      _reports = [];
      _checkedStates = [];
    });
  }

  Future<void> _deleteReport(int index) async {
    setState(() {
      _reports.removeAt(index);
      _checkedStates.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('reports', _reports);
    await _saveCheckedStates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF25303B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF25303B),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Users Reports",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1A2B3C),
                      title: const Text(
                        "Clear All Reports",
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        "Are you sure you want to delete all reports?",
                        style: TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await _clearReports();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _reports.isEmpty
              ? const Center(
                child: Text(
                  "No reports found.",
                  style: TextStyle(color: Colors.white70),
                ),
              )
              : ListView.builder(
                itemCount: _reports.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _checkedStates[index],
                          onChanged: (value) async {
                            setState(() {
                              _checkedStates[index] = value ?? false;
                            });
                            await _saveCheckedStates();
                          },
                          checkColor: Colors.black,
                          activeColor: Colors.tealAccent,
                        ),
                        Expanded(
                          child: Text(
                            _reports[index],
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteReport(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}
