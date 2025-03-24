import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

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
  var _inputVar = "empty"; //This is the variable that will be fed by the Arduino based on gesture
  final _audioPlayer = AudioPlayer(); //This is the audio player for the alert sounds
  final _ble = FlutterReactiveBle(); //This is the BLE connection to the Arduino

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;

  var _found = false;

  @override
  initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  dispose() {
    _scanSub?.cancel();
    _connectSub?.cancel();
    _notifySub?.cancel();
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice d) {
    if (d.name == 'Nano33BLE' && !_found) {  // NEED TO RENAME THIS TO THE NAME OF THE ARDUINO
      _found = true;
      _connectSub = _ble.connectToDevice(id: d.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(d.id);
          print("CONNECTED TO A DEVICE");
        }
      });
    }
  }

  void _onConnected(String deviceId) {
    final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('19B10000-E8F2-537E-4F6C-D104768A1214'),
        characteristicId: Uuid.parse('19B10001-E8F2-537E-4F6C-D104768A1214'));

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
      setState(() {
        String gesture = const Utf8Decoder().convert(bytes).trim();
        print("Received gesture: $gesture");
        _readGesture(gesture); // Process the incoming gesture
      });
    });
  }

  Color _getBackgroundColor() { //This sets the bg colour based on the input value
    if (_inputVar == "empty") {
      return Colors.grey;
    } else if (_inputVar == "figure8") {
      return Colors.blue;
    } else if (_inputVar == "vertical") {
      return Colors.green;
    } else if (_inputVar == "clockwise") {
      return Colors.pink.shade200;
    } else if (_inputVar == "horizontal") {
      return Colors.red;
    } else {
      return Colors.yellow.shade200;
    }
  }

  String _getDisplayText() { //This sets the text based on the input value
    if (_inputVar == "empty") {
      return "Awaiting input gesture";
    } else if (_inputVar == "figure8") {
      return "Patient is thirsty";
    } else if (_inputVar == "vertical") {
      return "Patient is hungry";
    } else if (_inputVar == "clockwise") {
      return "Patient needs the restroom";
    } else if (_inputVar == "horizontal") {
      return "Patient is in pain";
    } else {
      return "Gesture not recognised";
    }
  }

  Future<void> updateSound(String gesture) async { //This plays the calmer alert for non-emergencies and the urgent one for emergencies
    await _audioPlayer.stop();
    if (gesture == "empty") {
      // pass (isn't a thing in dart)
    } else if (gesture == "horizontal") {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/urgent.mp3'));
    } else {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.play(AssetSource('sounds/calm.mp3'));
    }
  }

  void _readGesture(String gesture) { //This updates the currently read gesture. Controlled by buttons for now, but will be replaced with the Arduino input
    setState(() {
      _inputVar = gesture;
    });
    updateSound(gesture);
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
              onPressed: () => _readGesture("empty"),
              child: const Text('Clear Gesture'),
            ),
            const SizedBox(height: 50),
            ElevatedButton( //This button and all the following ones, will be removed when this app is connected to the Arduino input
              onPressed: () => _readGesture("figure8"),
              child: const Text('Thirsty'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture("vertical"),
              child: const Text('Hungry'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture("clockwise"),
              child: const Text('Restroom'),
            ),
            ElevatedButton(
              onPressed: () => _readGesture("horizontal"),
              child: const Text('Pain'),
            ),
          ],
        ),
      ),
    );
  }
}

