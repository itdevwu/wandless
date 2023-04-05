import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accelerometer',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const AccelerometerPage(),
    );
  }
}

class AccelerometerPage extends StatefulWidget {
  const AccelerometerPage({super.key});

  @override
  _AccelerometerPageState createState() => _AccelerometerPageState();
}

class _AccelerometerPageState extends State<AccelerometerPage> {
  List<double> _userAccelerometerValues = [0, 0, 0];
  StreamSubscription? _streamSubscription;

  // Log
  bool isLogging = false;
  String label = "log";
  List<List<String>> accLogs = [
    ["time", "x", "y", "z"]
  ];

  Stream<UserAccelerometerEvent> _accEvents() {
    UserAccelerometerEvent resultEvent = UserAccelerometerEvent(1.1, 4.5, 1.4);
    userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      resultEvent = event;
    });

    return Stream.periodic(
      const Duration(milliseconds: 10),
          (_) => resultEvent,
    );
  }

  void _logAccData(UserAccelerometerEvent event) {
    setState(() {
      _userAccelerometerValues = <double>[event.x, event.y, event.z];
      if (isLogging) {
      final DateTime now = DateTime.now();
      final List<String> logRow = [
      now.toIso8601String(),
      event.x.toStringAsFixed(8),
      event.y.toStringAsFixed(8),
      event.z.toStringAsFixed(8),
      ];
      accLogs.add(logRow);
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _streamSubscription = _accEvents().listen(_logAccData);


    // _streamSubscription =
    //     userAccelerometerEvents
    //         .sampleTime(const Duration(milliseconds: 10))
    //         .listen((UserAccelerometerEvent event) {
    //   setState(() {
    //     _userAccelerometerValues = <double>[event.x, event.y, event.z];
    //     if (isLogging) {
    //       final DateTime now = DateTime.now();
    //       final List<String> logRow = [
    //         now.toIso8601String(),
    //         event.x.toStringAsFixed(8),
    //         event.y.toStringAsFixed(8),
    //         event.z.toStringAsFixed(8),
    //       ];
    //       accLogs.add(logRow);
    //     }
    //   });
    // });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accelerometer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Accelerometer Values:',
            ),
            Text(
              'x: ${_userAccelerometerValues[0].toStringAsFixed(8)}',
            ),
            Text(
              'y: ${_userAccelerometerValues[1].toStringAsFixed(8)}',
            ),
            Text(
              'z: ${_userAccelerometerValues[2].toStringAsFixed(8)}',
            ),
            Text("isLogging: $isLogging"),
            Text("Log count: ${(accLogs.length - 1).toString()}"),
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'label',
              ),
              enabled: true,
              autofocus: true,
              textAlign: TextAlign.center,
              maxLines: 1,
              onChanged: (value) {
                label = value;
              },
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          setState(() {
            isLogging = !isLogging;
          });

          if (isLogging == false && accLogs.isNotEmpty) {
            var now = DateTime.now();
            String logFileName =
                "${label}_${now.toIso8601String().split(':')[0]}-${now.toIso8601String().split(':')[1]}-${now.toIso8601String().split(':')[2]}.csv";
            String csv = const ListToCsvConverter().convert(accLogs);

            final tempDir = await getTemporaryDirectory();

            String path = tempDir.absolute.path;
            File file = File('$path/$logFileName');
            String absPath = file.absolute.path;
            await file.writeAsString(csv);
            Share.shareFiles([absPath]);

            accLogs = [
              ["time", "x", "y", "z"]
            ];
          }
        },
        child: Icon(isLogging ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
