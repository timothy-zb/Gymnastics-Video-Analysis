import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '/edit_athlete.dart';
import '/videos.dart';

class ViewAthletesScreen extends StatefulWidget {
  @override
  _ViewAthletesScreenState createState() => _ViewAthletesScreenState();
}

class _ViewAthletesScreenState extends State<ViewAthletesScreen> {
  late TextEditingController _searchController;
  late Query _query;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _query = FirebaseFirestore.instance.collection('athletes');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchAthletes(String searchText) {
    setState(() {
      if (searchText.trim().isEmpty) {
        _query = FirebaseFirestore.instance.collection('athletes');
      } else {
        _query = FirebaseFirestore.instance
            .collection('athletes')
            .where('athleteName', isGreaterThanOrEqualTo: searchText)
            .where('athleteName', isLessThan: searchText + 'z');
      }
    });
  }

  Future<void> deleteAthlete(String docId) async {
    try {
      final athleteRef =
          FirebaseFirestore.instance.collection('athletes').doc(docId);
      final videosSnapshot = await athleteRef.collection('videos').get();

      // Delete each video document and corresponding files
      for (var videoDoc in videosSnapshot.docs) {
        final videoData = videoDoc.data();
        final videoUrl = videoData['videoUrl'];
        final outputVideoUrl = videoData['outputVideoUrl'];

        // Delete the video document
        await videoDoc.reference.delete();

        // Delete the video file
        if (videoUrl != null && videoUrl.isNotEmpty) {
          final videoFileRef = FirebaseStorage.instance.refFromURL(videoUrl);
          await videoFileRef.delete();
        }

        // Delete the output video file
        if (outputVideoUrl != null && outputVideoUrl.isNotEmpty) {
          final outputVideoFileRef =
              FirebaseStorage.instance.refFromURL(outputVideoUrl);
          await outputVideoFileRef.delete();
        }
      }

      // Delete the athlete document
      await athleteRef.delete();
    } catch (e) {
      // Handle the error here
      print('Failed to delete athlete: $e');
    }
  }

  void navigateToVideos(String athleteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideosScreen(athleteId: athleteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 48, left: 16),
            child: Text(
              'Athletes',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _searchAthletes,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search, color: Colors.black),
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No athletes found.',
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final athleteData =
                        doc.data() as Map<String, dynamic>;

                    // Check if the required fields are present
                    final athleteId = doc.id;
                    final athleteName = athleteData['athleteName'] ?? '';
                    final age = athleteData['age'] ?? '';
                    final gender = athleteData['gender'] ?? '';
                    final height = athleteData['height'] ?? '';
                    final weight = athleteData['weight'] ?? '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Card(
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          tileColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          title: Text(
                            athleteName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Age: $age',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'Gender: $gender',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'Height: $height',
                                style: TextStyle(color: Colors.black),
                              ),
                              Text(
                                'Weight: $weight',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditAthleteScreen(
                                        docId: athleteId,
                                        athleteName: athleteName,
                                        age: age,
                                        height: height,
                                        weight: weight,
                                        gender: gender,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: Colors.black,
                                ),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'Delete Athlete',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        content: Text(
                                          'Are you sure you want to delete this athlete?',
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        backgroundColor: Colors.white,
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.black,
                                              ),
                                            ),
                                            onPressed: () {
                                              deleteAthlete(athleteId);
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            navigateToVideos(athleteId);
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
