import 'package:flutter/material.dart';
import 'dart:async';
import 'package:numberpicker/numberpicker.dart';
import 'package:audioplayers/audioplayers.dart'; // Import audioplayers

// Global key for the scaffold messenger to show SnackBars from the service class
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: StartCookingScreen(
        instructions: '1. Preheat oven to 350°F...\n2. Mix ingredients...',
      ),
    );
  }
}

class StartCookingScreen extends StatefulWidget {
  final String instructions;

  const StartCookingScreen({Key? key, required this.instructions})
      : super(key: key);

  @override
  _StartCookingScreenState createState() => _StartCookingScreenState();
}

class _StartCookingScreenState extends State<StartCookingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Cooking'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 100.0), // Adjust this value
              child: Text(
                widget.instructions,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: FloatingActionButton(
                  onPressed: () {
                    _showTimerDialog();
                  },
                  child: Icon(Icons.timer),
                  backgroundColor:
                      Colors.amber, // Set the background color to amber
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimerDialog() {
    TimerService.instance.onTimerFinished = () {
      // Reopen the TimerDialog after the timer finishes
      _showTimerDialog();
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TimerDialog();
      },
    );
  }
}

class TimerDialog extends StatefulWidget {
  @override
  _TimerDialogState createState() => _TimerDialogState();
}

class _TimerDialogState extends State<TimerDialog> {
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        // Center the title widget
        child: Text(
          'Set Timer',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold), // Optional styling
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTimePicker(
                  'Hours',
                  _hours,
                  (value) => _setHours(value),
                ),
              ),
              Expanded(
                child: _buildTimePicker(
                  'Minutes',
                  _minutes,
                  (value) => _setMinutes(value),
                ),
              ),
              Expanded(
                child: _buildTimePicker(
                  'Seconds',
                  _seconds,
                  (value) => _setSeconds(value),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          ValueListenableBuilder<Duration>(
            valueListenable: TimerService.instance.duration,
            builder: (context, duration, child) {
              return Text(
                _formatDuration(duration),
                style: TextStyle(fontSize: 24),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: TimerService.instance.isRunning,
          builder: (context, isRunning, child) {
            return TextButton(
              onPressed: () {
                if (isRunning) {
                  TimerService.instance.stopTimer();
                  setState(() {
                    _hours = 0;
                    _minutes = 0;
                    _seconds = 0;
                  });
                } else {
                  if (_hours > 0 || _minutes > 0 || _seconds > 0) {
                    TimerService.instance.startTimer(
                      Duration(
                          hours: _hours, minutes: _minutes, seconds: _seconds),
                    );
                    Navigator.of(context).pop();
                  }
                }
              },
              child: Text(isRunning ? 'Stop' : 'Start'),
            );
          },
        ),
      ],
    );
  }

  void _setHours(int value) {
    setState(() {
      _hours = value;
    });
  }

  void _setMinutes(int value) {
    setState(() {
      _minutes = value;
    });
  }

  void _setSeconds(int value) {
    setState(() {
      _seconds = value;
    });
  }

  Widget _buildTimePicker(
      String label, int initialValue, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label),
        NumberPicker(
          value: initialValue,
          minValue: 0,
          maxValue: label == 'Hours' ? 23 : 59,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }
}

class TimerService {
  TimerService._privateConstructor();

  static final TimerService instance = TimerService._privateConstructor();

  final ValueNotifier<Duration> duration = ValueNotifier<Duration>(Duration());
  final ValueNotifier<bool> isRunning = ValueNotifier<bool>(false);
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  VoidCallback? onTimerFinished; // Callback to notify when timer finishes

  void startTimer(Duration startDuration) {
    duration.value = startDuration;
    isRunning.value = true;
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (duration.value.inSeconds > 0) {
        duration.value = duration.value - Duration(seconds: 1);
      } else {
        timer.cancel();
        isRunning.value = false;
        _showAlert();
      }
    });
  }

  void stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
    duration.value = Duration();
    isRunning.value = false;
    _audioPlayer.stop();
  }

  Future<void> _showAlert() async {
    print('Timer finished. Showing alert.');

    // Play sound
    try {
      // Load the audio file from assets
      await _audioPlayer.setSource(
        AssetSource('sounds/alarm.mp3'),
      );
      await _audioPlayer.resume(); // Play the sound
    } catch (e) {
      print('Error playing sound: $e');
    }

    // Notify the screen to reopen the TimerDialog
    if (onTimerFinished != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onTimerFinished!();
      });
    }
  }
}
