import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:transitease/models/models.dart';

class BugReportFormUI extends StatefulWidget {
  final AppUser user;

  BugReportFormUI({required this.user});

  @override
  _BugReportFormUIState createState() => _BugReportFormUIState();
}

class _BugReportFormUIState extends State<BugReportFormUI> {
  final _descriptionController = TextEditingController();
  Severity _selectedSeverity = Severity.low;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitBugReport() async {
    final String bugReportID = DateTime.now().millisecondsSinceEpoch.toString();
    final String description = _descriptionController.text;

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a bug description')),
      );
      return;
    }

    try {
      // Push bug report to Firestore
      await FirebaseFirestore.instance
          .collection('bugreports')
          .doc('reports_$bugReportID')
          .set({
        'user_email': widget.user.userID,
        'severity': _selectedSeverity.toString().split('.').last,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bug report submitted successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      print("Error submitting bug report: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit bug report. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bug Report Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe the bug:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter the bug details here',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Severity:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            DropdownButton<Severity>(
              value: _selectedSeverity,
              items: Severity.values.map((Severity severity) {
                return DropdownMenuItem<Severity>(
                  value: severity,
                  child: Text(severity.toString().split('.').last),
                );
              }).toList(),
              onChanged: (Severity? newValue) {
                setState(() {
                  _selectedSeverity = newValue!;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitBugReport,
              child: Text('Submit Bug Report'),
            ),
          ],
        ),
      ),
    );
  }
}
