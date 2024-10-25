import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CarParksScreen extends StatefulWidget {
  @override
  _CarParksScreenState createState() => _CarParksScreenState();
}

class _CarParksScreenState extends State<CarParksScreen> {
  List<Map<String, dynamic>> carParks = [];

  Future<void> _fetchCarParks() async {
    try {
      print("Starting to fetch car parks...");

      QuerySnapshot allCarParks =
          await FirebaseFirestore.instance.collection('car_parks').get();

      print("Total Car Parks: ${allCarParks.docs.length}");

      if (allCarParks.docs.isEmpty) {
        print("No documents found in the 'car_parks' collection.");
        return;
      }

      allCarParks.docs.forEach((doc) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          if (data.containsKey('carpark')) {
            Map<String, dynamic>? carparkData =
                data['carpark'] as Map<String, dynamic>?;

            if (carparkData != null && carparkData.containsKey('geohash')) {
              print(
                  "Document ID: ${doc.id}, Geohash: ${carparkData['geohash']}");

              carParks.add({
                'id': doc.id,
                'geohash': carparkData['geohash'],
              });
            } else {
              print(
                  "Document ID: ${doc.id} does not have a 'geohash' field in 'carpark'.");
            }
          } else {
            print("Document ID: ${doc.id} does not have a 'carpark' field.");
          }
        } catch (e) {
          print("Error processing document ID: ${doc.id}. Error: $e");
        }
      });

      setState(() {});
    } on FirebaseException catch (e) {
      print("Firestore Error: ${e.message}");
      if (e.code == 'permission-denied') {
        print(
            "Permission denied: Make sure your Firestore rules allow access.");
      } else if (e.code == 'not-found') {
        print("Collection 'car_parks' not found in Firestore.");
      } else {
        print("Firestore error: ${e.message}");
      }
    } catch (e) {
      print("Unknown error occurred while fetching car parks: $e");
    }
  }

  @override
  void initState() {
    super.initState();

    _fetchCarParks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Car Parks'),
      ),
      body: carParks.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: carParks.length,
              itemBuilder: (context, index) {
                final carPark = carParks[index];
                return ListTile(
                  title: Text('Car Park ID: ${carPark['id']}'),
                  subtitle: Text('Geohash: ${carPark['geohash']}'),
                );
              },
            ),
    );
  }
}
