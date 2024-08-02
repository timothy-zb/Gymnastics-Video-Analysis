import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'output.dart';

class VideosScreen extends StatefulWidget {
  final String athleteId;

  VideosScreen({required this.athleteId});

  @override
  _VideosScreenState createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  late Future<List<VideoData>> _videosFuture;

  @override
  void initState() {
    super.initState();
    _videosFuture = _getVideos();
  }

  Future<List<VideoData>> _getVideos() async {
    List<VideoData> videos = [];

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('athletes')
          .doc(widget.athleteId)
          .collection('videos')
          .get();

      for (QueryDocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic>? videoData = doc.data() as Map<String, dynamic>?;

        if (videoData != null) {
          videos.add(VideoData.fromMap(videoData, doc.id));
        }
      }
    } catch (e) {
      print('Error retrieving videos: $e');
    }

    return videos;
  }

  void _navigateToOutput(String outputVideoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OutputScreen(outputVideoUrl: outputVideoUrl),
      ),
    );
  }

  Future<void> _uploadVideoFromCamera() async {
    PickedFile? pickedFile = await ImagePicker().getVideo(source: ImageSource.camera);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      await _uploadAndSaveVideo(file);
    }

    setState(() {
      _videosFuture = _getVideos();
    });
  }

  Future<void> _uploadVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );

    if (result == null || result.files.isEmpty) {
      return; // User canceled video selection or camera capture, return without uploading
    }

    File file = File(result.files.single.path!);
    await _uploadAndSaveVideo(file);

    setState(() {
      _videosFuture = _getVideos();
    });
  }

  Future<void> _uploadAndSaveVideo(File file) async {
    try {
      String videoUrl = await _uploadVideoFile(file);
      await _addVideoDocument(videoUrl);
      await _sendAthleteId(widget.athleteId);
    } catch (e) {
      print('Failed to upload video: $e');
    }
  }

  Future<String> _uploadVideoFile(File file) async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference reference = FirebaseStorage.instance.ref().child('videos/$fileName');
    await reference.putFile(file);
    return await reference.getDownloadURL();
  }

  Future<void> _addVideoDocument(String videoUrl) async {
    CollectionReference videosRef = FirebaseFirestore.instance
        .collection('athletes')
        .doc(widget.athleteId)
        .collection('videos');

    await videosRef.add({
      'videoUrl': videoUrl,
      'outputVideoUrl': null,
    });
  }

  Future<void> _sendAthleteId(String athleteId) async {
    final url = 'https://172.17.81.155:443/process_video'; // Update with your Flask API URL
    final response = await http.post(
      Uri.parse(url),
      body: {'athlete_id': athleteId},
    );

    if (response.statusCode == 200) {
      print('Athlete ID sent successfully');
    } else {
      print('Failed to send athlete ID');
    }
  }

  Future<void> _deleteVideo(String docId, String videoUrl, String? outputVideoUrl) async {
    try {
      final videoRef = FirebaseFirestore.instance
          .collection('athletes')
          .doc(widget.athleteId)
          .collection('videos')
          .doc(docId);

      // Delete the video document
      await videoRef.delete();

      // Delete the video file
      if (videoUrl != null && videoUrl.isNotEmpty) {
        final videoFileRef = FirebaseStorage.instance.refFromURL(videoUrl);
        await videoFileRef.delete();
      }

      // Delete the output video file
      if (outputVideoUrl != null && outputVideoUrl.isNotEmpty) {
        final outputVideoFileRef = FirebaseStorage.instance.refFromURL(outputVideoUrl);
        await outputVideoFileRef.delete();
      }

      setState(() {
        _videosFuture = _getVideos();
      });
    } catch (e) {
      print('Failed to delete video: $e');
    }
  }

  Widget _buildVideoItem(VideoData videoData) {
    final outputVideoUrl = videoData.outputVideoUrl;

    if (outputVideoUrl == null) {
      return Container();
    }

    return ListTile(
      title: Text(
        'Video ${videoData.id}', // Replace with the appropriate video name from your data
        style: TextStyle(color: Colors.black),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.black),
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Delete Video'),
                content: Text('Are you sure you want to delete this video?'),
                actions: <Widget>[
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: Text('Delete'),
                    onPressed: () {
                      _deleteVideo(videoData.id, videoData.videoUrl, outputVideoUrl);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
      onTap: () {
        _navigateToOutput(outputVideoUrl);
      },
    );
  }

  Widget _buildVideosList(List<VideoData> videos) {
    if (videos.isEmpty) {
      return Center(
        child: Text(
          'No videos found.',
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final videoData = videos[index];
        return _buildVideoItem(videoData);
      },
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
              'Videos',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<VideoData>>(
              future: _videosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(color: Colors.black),
                    ),
                  );
                }

                if (snapshot.hasData) {
                  return _buildVideosList(snapshot.data!);
                }

                return Container();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _uploadVideo,
            child: Icon(Icons.cloud_upload),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.black,
            onPressed: _uploadVideoFromCamera,
            child: Icon(Icons.camera_alt),
          ),
        ],
      ),
    );
  }
}

class VideoData {
  final String id;
  final String videoUrl;
  final String? outputVideoUrl;

  VideoData({
    required this.id,
    required this.videoUrl,
    this.outputVideoUrl,
  });

  factory VideoData.fromMap(Map<String, dynamic> map, String id) {
    return VideoData(
      id: id,
      videoUrl: map['videoUrl'] ?? '',
      outputVideoUrl: map['outputVideoUrl'] as String?, // Cast to String?
    );
  }
}
