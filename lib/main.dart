import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:desktop_multi_window/desktop_multi_window.dart' as dmuw;
import 'package:flutter/material.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loom_rs/components/reusable_timer.dart';
import 'package:loom_rs/core/core.dart';
import 'package:loom_rs/providers/timer_provider.dart';
import 'package:loom_rs/screens/confetti_screen.dart';
import 'package:loom_rs/screens/my_cam_view.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:win32/win32.dart';
import 'package:loom_rs/helper.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Window.initialize();

  final condition = args.firstOrNull == 'multi_window';

  /// index	Type	description
  /// 0	String	the value always is "multi_window".
  /// 1	int	the id of the window.
  /// 2	String	the [arguments] of the window.
  /// You can use [WindowController] to control the window.
  debugPrint(args.asMap().keys.toString()); //flutter: (0, 1, 2)
  debugPrint(
    args.asMap().entries.toString(),
  ); // flutter: (MapEntry(0: multi_window), MapEntry(1: 1), MapEntry(2: ))

  if (condition) {
    /// COMMON SCREENS
    await Window.hideWindowControls();
    await Window.hideTitle();

    Window.makeWindowFullyTransparent();
    await Window.setEffect(effect: WindowEffect.transparent);
    await windowManager.ensureInitialized();

    /// FOR CONFETTI SCREEN
    await Window.enterFullscreen();
    runApp(MaterialApp(home: const ConfettiScreen()));

    /// FOR TEMPLATES
    // runApp(const TemplateWindow());

    /// FOR CAM VIEW
    // runApp(const MyCamView());

    // await windowManager.setSize(Size(200, 200));
    // await windowManager.setAlwaysOnTop(true);
    // await windowManager.setAlignment(Alignment.bottomRight);
    // // await windowManager.setAsFrameless();
  } else {
    await windowManager.ensureInitialized();

    runApp(ProviderScope(child: const ScreenRecorderApp()));
    await Core.mainConfigs();
  }
}

enum RecordingMode { full, region, window }

class ScreenRecorderApp extends StatelessWidget {
  const ScreenRecorderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloom🍁🌸',
      theme: ThemeData.light().copyWith(scaffoldBackgroundColor: Colors.white),
      home: const ScreenRecorderHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Define the callback type for EnumWindows.
typedef EnumWindowsProcNative =
    ffi.Int32 Function(ffi.Int32 hwnd, ffi.Int32 lParam);
typedef EnumWindowsProcDart = int Function(int hwnd, int lParam);

class _ScreenRecorderHomeState extends State<ScreenRecorderHome> {
  final List<String> _segments =
      []; // Store only the relative filenames (e.g., "segment_0.ts")
  Process? _ffmpegProcess;
  bool _isRecording = false;
  bool _isPaused = false;
  int _segmentIndex = 0;

  late final ref;

  // Default recording mode.
  RecordingMode _recordingMode = RecordingMode.full;

  // Controllers for region capture mode.
  final TextEditingController _xController = TextEditingController(text: '0');
  final TextEditingController _yController = TextEditingController(text: '0');
  final TextEditingController _widthController = TextEditingController(
    text: '1280',
  );
  final TextEditingController _heightController = TextEditingController(
    text: '720',
  );

  // For window selection mode.
  Set<String> _availableWindows = {};
  String? _selectedWindow;

  String get _ffmpegPath {
    if (Platform.isWindows) {
      return 'C:/dev/ffmpeg-7.1.1-full_build/bin/ffmpeg.exe';
    } else if (Platform.isMacOS) {
      return '/Users/rittiksoni/Desktop/rs_bloom/assets/ffmpeg/mac/ffmpeg';
    }
    return 'ffmpeg';
  }

  @override
  void initState() {
    super.initState();
    if (_recordingMode == RecordingMode.window && Platform.isWindows) {
      _fetchAvailableWindows();
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) => ref = ProviderScope.containerOf(context),
    );
  }

  // Static list to accumulate window titles.
  static final Set<String> _enumWindowTitles = <String>{};

  // Static callback for EnumWindows.
  static int _enumWindowsProc(int hWnd, int lParam) {
    // Don't enumerate windows unless they are marked as WS_VISIBLE
    if (IsWindowVisible(hWnd) == FALSE) return TRUE;

    final length = GetWindowTextLength(hWnd);
    if (length == 0) {
      return TRUE;
    }

    final buffer = wsalloc(length + 1);
    GetWindowText(hWnd, buffer, length + 1);
    _enumWindowTitles.add(buffer.toDartString());

    free(buffer);

    return TRUE;
  }

  /// Retrieves open, visible window titles.
  List<String> getOpenWindowTitles() {
    _enumWindowTitles.clear();
    final enumProc =
        ffi.Pointer.fromFunction<EnumWindowsProcNative>(
          _enumWindowsProc,
          0,
        ).cast<ffi.NativeFunction<WNDENUMPROC>>();
    EnumWindows(enumProc, 0);
    return List<String>.from(_enumWindowTitles);
  }

  Future<void> _fetchAvailableWindows() async {
    if (Platform.isWindows) {
      final windows = getOpenWindowTitles();
      setState(() {
        _availableWindows = windows.toSet();
        _selectedWindow =
            _availableWindows.isNotEmpty
                ? _availableWindows.elementAt(1)
                : null;
      });
    }
  }

  Future<String> _startSegment() async {
    // Create the recordings folder if it doesn't exist.
    final recordingsDir = Directory('recordings');
    if (!recordingsDir.existsSync()) {
      recordingsDir.createSync(recursive: true);
    }

    // Create relative and absolute filenames.
    final segmentFilename = 'segment_$_segmentIndex.ts';
    final fullPath = 'recordings/$segmentFilename';
    _segmentIndex++;

    // Build FFmpeg arguments.
    List<String> ffmpegArgs = ['-y'];
    if (_recordingMode == RecordingMode.full) {
      ffmpegArgs.addAll([
        '-f',
        Helper.getFFmpegEngine,
        '-framerate',
        '30',
        '-i',
        Platform.isWindows ? 'desktop' : 'default',
      ]);
    } else if (_recordingMode == RecordingMode.region) {
      if (Platform.isWindows) {
        ffmpegArgs.addAll([
          '-f',
          'gdigrab',
          '-framerate',
          '30',
          '-offset_x',
          _xController.text,
          '-offset_y',
          _yController.text,
          '-video_size',
          '${_widthController.text}x${_heightController.text}',
          '-i',
          'desktop',
        ]);
      } else {
        ffmpegArgs.addAll([
          '-f',
          Helper.getFFmpegEngine,
          '-framerate',
          '30',
          '-i',
          'default',
        ]);
      }
    } else if (_recordingMode == RecordingMode.window) {
      if (Platform.isWindows && _selectedWindow != null) {
        ffmpegArgs.addAll([
          '-f',
          'gdigrab', // Use gdigrab for capturing specific windows on Windows
          '-framerate',
          '30',
          '-i',
          'title=$_selectedWindow',
        ]);
      } else {
        ffmpegArgs.addAll([
          '-f',
          Helper.getFFmpegEngine,
          '-framerate',
          '30',
          '-i',
          'default',
        ]);
      }
    }

    // Append encoding options and the output file.
    ffmpegArgs.addAll([
      '-vcodec',
      'libx264',
      '-preset',
      'ultrafast',
      if (_recordingMode != RecordingMode.window) '-pix_fmt',
      if (_recordingMode != RecordingMode.window) 'yuv420p',
      '-crf',
      '23',
      fullPath,
    ]);

    // Start the FFmpeg process.
    _ffmpegProcess = await Process.start(
      _ffmpegPath,
      ffmpegArgs,
      runInShell: true,
    );
    _ffmpegProcess?.stderr.transform(SystemEncoding().decoder).listen((data) {
      debugPrint('FFmpeg stderr: $data');
    });

    // Store the relative file name.
    _segments.add(segmentFilename);
    return segmentFilename;
  }

  Future<void> _stopSegment() async {
    if (_ffmpegProcess != null) {
      _ffmpegProcess!.stdin.write('q');
      await _ffmpegProcess!.stdin.flush();
      await _ffmpegProcess!.stdin.close();
      await _ffmpegProcess!.exitCode;
      _ffmpegProcess = null;
    }
  }

  Future<void> _startRecording() async {
    await _startSegment();
    setState(() {
      ref.read(recordingTimerProvider.notifier).start();
      _isRecording = true;
      _isPaused = false;
    });
  }

  Future<void> _pauseRecording() async {
    await _stopSegment();
    setState(() {
      _isPaused = true;
      ref.read(recordingTimerProvider.notifier).pause();
    });
  }

  Future<void> _resumeRecording() async {
    await _startSegment();
    setState(() {
      _isPaused = false;
      ref
          .read(recordingTimerProvider.notifier)
          .start(); // resume is same as start
    });
  }

  Future<void> _stopRecording() async {
    await _stopSegment();
    await _mergeSegments();
    setState(() {
      _isRecording = false;
      ref.read(recordingTimerProvider.notifier).reset();
      _isPaused = false;
      _segmentIndex = 0;
      _segments.clear();
    });
  }

  Future<void> _mergeSegments() async {
    // Create a list file in the recordings folder.
    final listFile = File('recordings/segments.txt');
    final buffer = StringBuffer();
    // Write relative file paths (that FFmpeg will resolve using the working directory).
    for (var segment in _segments) {
      buffer.writeln("file '$segment'");
    }
    await listFile.writeAsString(buffer.toString());

    final outputFilename =
        'recordings/final_output_${DateTime.now().millisecondsSinceEpoch}.mkv';

    // Run FFmpeg in the recordings folder so that the relative file names match.
    final result = await Process.run(_ffmpegPath, [
      '-y',
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      listFile.path,
      '-c',
      'copy',
      outputFilename,
    ], runInShell: true);

    debugPrint('Merge stderr: ${result.stderr}');

    if (result.exitCode == 0) {
      try {
        // Delete each segment file.
        for (var segment in _segments) {
          final file = File('recordings/$segment');
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
        // Delete the segments list file.
        if (listFile.existsSync()) {
          listFile.deleteSync();
        }
      } catch (e) {
        debugPrint('Cleanup error: $e');
      }
    } else {
      debugPrint('Merging failed with exit code ${result.exitCode}');
    }
  }

  Future<void> openTemplateWindow() async {
    final window = await dmuw.DesktopMultiWindow.createWindow();
    final mq = await screenRetriever.getPrimaryDisplay();
    // window
    //   ..setFrame(const Offset(0, 0) & Size(200, 200))
    //   // ..setFrame(const Offset(0, 0) & Size(mq.size.width, mq.size.height))
    //   ..center();
    // await window.setFrame(const Offset(0, 0) & Size(200, 200));
    // await window.center();
    await window.show();
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await openTemplateWindow();
                  },
                  child: const Text('Open Template Window'),
                ),
                const SizedBox(height: 20),
                ReusableRecordingTimerText(),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bloom🍁🌸',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CloseButton(
                        onPressed: () async {
                          await windowManager.hide();
                        },
                      ),
                    ],
                  ),
                ),
                RadioListTile<RecordingMode>(
                  title: Row(
                    children: [
                      Icon(Icons.computer_rounded),
                      SizedBox(width: 5),
                      const Text('Full Screen'),
                    ],
                  ),
                  value: RecordingMode.full,
                  groupValue: _recordingMode,
                  onChanged: (value) {
                    setState(() {
                      _recordingMode = value!;
                    });
                  },
                ),
                RadioListTile<RecordingMode>(
                  title: Row(
                    children: [
                      Icon(Icons.photo_size_select_small_rounded),
                      SizedBox(width: 5),
                      const Text('Specific Region'),
                    ],
                  ),
                  value: RecordingMode.region,
                  groupValue: _recordingMode,
                  onChanged: (value) {
                    setState(() {
                      _recordingMode = value!;
                    });
                  },
                ),
                RadioListTile<RecordingMode>(
                  title: Row(
                    children: [
                      Icon(Icons.window_rounded),
                      SizedBox(width: 5),
                      const Text('Specific Window'),
                    ],
                  ),
                  value: RecordingMode.window,
                  groupValue: _recordingMode,
                  onChanged: (value) {
                    setState(() {
                      _recordingMode = value!;
                      if (Platform.isWindows) {
                        _fetchAvailableWindows();
                      }
                    });
                  },
                ),
                if (_recordingMode == RecordingMode.region)
                  Column(
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _xController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Offset X',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _yController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Offset Y',
                              ),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _widthController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Width',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                if (_recordingMode == RecordingMode.window &&
                    Platform.isWindows)
                  Column(
                    mainAxisSize: MainAxisSize.min,

                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        'Select a Window:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton<String>(
                          isDense: true,

                          value: _selectedWindow,

                          items:
                              _availableWindows.map((window) {
                                return DropdownMenuItem<String>(
                                  value: window,
                                  child: Text(window),
                                );
                              }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedWindow = newValue;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: _isRecording ? Colors.red : Colors.green,
                  ),
                  child: Text(
                    _isRecording ? 'Stop' : 'Start',

                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isRecording ? Colors.white : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (_isRecording)
                  ElevatedButton(
                    onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      backgroundColor: _isPaused ? Colors.orange : Colors.blue,
                    ),
                    child: Text(_isPaused ? 'Resume' : 'Pause'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScreenRecorderHome extends StatefulWidget {
  const ScreenRecorderHome({super.key});

  @override
  State<ScreenRecorderHome> createState() => _ScreenRecorderHomeState();
}
