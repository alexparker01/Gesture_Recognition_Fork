import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Controlled Output App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GestureControlledOutputApp(),
    );
  }
}

class GestureControlledOutputApp extends StatefulWidget {
  const GestureControlledOutputApp({super.key});

  @override
  State<GestureControlledOutputApp> createState() => _GestureControlledOutputAppState();
}

class _GestureControlledOutputAppState extends State<GestureControlledOutputApp> {
  int _inputValue = 0; //This is the int that will be fed by the Arduino based on gesture
  final _audioPlayer = AudioPlayer(); //This is the audio player for the alert sounds

  Color _getBackgroundColor() { //This sets the bg colour based on the input value
    if (_inputValue == 0) {
      return Colors.grey;
    } else if (_inputValue == 1) {
      return Colors.blue;
    } else if (_inputValue == 2) {
      return Colors.green;
    } else if (_inputValue == 3) {
      return Colors.pink.shade200;
    } else if (_inputValue == 4) {
      return Colors.red;
    } else {
      return Colors.yellow.shade200;
    }
  }

  String _getDisplayText() { //This sets the text based on the input value
    if (_inputValue == 0) {
      return "Awaiting input gesture";
    } else if (_inputValue == 1) {
      return "Patient is thirsty";
    } else if (_inputValue == 2) {
      return "Patient is hungry";
    } else if (_inputValue == 3) {
      return "Patient needs the restroom";
    } else if (_inputValue == 4) {
      return "Patient is in pain";
    } else {
      return "Gesture not recognised";
    }
  }

  Future<void> updateSound(int value) async { //This plays the calmer alert for non-emergencies and the urgent one for emergencies
    await _audioPlayer.stop();
    if (value == 0) {
      // pass (isn't a thing in dart)
    } else if (value < 4) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/calm.mp3'));
    } else if (value == 4) {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/urgent.mp3'));
    } else {
      // pass
    }
  }

  void _readGesture(int value) { //This updates the currently read gesture. Controlled by buttons for now, but will be replaced with the Arduino input
    setState(() {
      _inputValue = value;
    });
    updateSound(value);
  }

  @override
  Widget build(BuildContext context) { //This is the main Widget Tree
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              _getDisplayText(),
              style: const TextStyle(fontSize: 24, color: Colors.black),
            ),
            const SizedBox(height: 50),
            ElevatedButton( //This button is for the carer to clear the alert once they respond to it
              onPressed: () => _readGesture(0),
              child: const Text('Clear Gesture'),
            ),
            const SizedBox(height: 50),
            ElevatedButton( //This button and all the following ones, will be removed when this app is connected to the Arduino input
              onPressed: () => _readGesture(1),
              child: const Text('Thirsty'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture(2),
              child: const Text('Hungry'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture(3),
              child: const Text('Restroom'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture(4),
              child: const Text('Pain'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture(5),
              child: const Text('Unrecognised gesture'),
            ),
          ],
        ),
      ),
    );
  }
}

