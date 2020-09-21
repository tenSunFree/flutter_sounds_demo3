import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sounds_common/sounds_common.dart';
import 'package:sounds/sounds.dart';
import 'file:///C:/FlutterSoundsDemo3/flutter_sounds_demo3/example/lib/common/util/demo_active_codec.dart';
import 'file:///C:/FlutterSoundsDemo3/flutter_sounds_demo3/example/lib/common/util/demo_player_state.dart';
import 'file:///C:/FlutterSoundsDemo3/flutter_sounds_demo3/example/lib/common/util/recorder_state.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool initialized = false;

  String recordingFile;
  Track track;

  @override
  void initState() {
    super.initState();
    createDirectory("flutter").then((directoryPath) {
      String recordingFilePath = directoryPath + '/' + 'test.aac';
      File file = new File(recordingFilePath);
      if (!file.existsSync()) file.createSync();
      track = Track.fromFile(recordingFilePath,
          mediaFormat: WellKnownMediaFormats.adtsAac);
      String recordingFileName = 'test.aac';
      track.artist = recordingFileName;
      recordingFile = recordingFilePath;
      setState(() {});
    });
  }

  Future<String> createDirectory(String url) async {
    await requestStoragePermission();
    final documentsDirectory = await getApplicationDocumentsDirectory();
    var file = Directory(documentsDirectory.path + "/" + url);
    try {
      bool exists = await file.exists();
      if (!exists) await file.create();
    } catch (e) {
      print(e);
    }
    String directoryPath = file.path.toString();
    return directoryPath;
  }

  Future requestStoragePermission() async {
    await [Permission.storage].request();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: false,
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.data == false) {
            return Container();
          } else {
            return Stack(alignment: Alignment.center, //指定未定位或部分定位widget的对齐方式
                children: <Widget>[
                  Image.asset('assets/icon_home.png'),
                  _buildRecorder(track)
                ]);
          }
        });
  }

  Future<bool> init() async {
    if (!initialized) {
      await initializeDateFormatting();
      await RecorderState().init();
      ActiveMediaFormat().recorderModule = RecorderState().recorderModule;
      await ActiveMediaFormat().setMediaFormat(
          withShadeUI: false, mediaFormat: WellKnownMediaFormats.adtsAac);
      initialized = true;
    }
    return initialized;
  }

  Widget _buildRecorder(Track track) {
    return track == null
        ? Container()
        : RecorderPlaybackController(
            child: Stack(alignment: Alignment.center, children: [
            Column(children: [
              buildSizeBoxExpanded(1),
              Container(
                  width: double.infinity,
                  height: 300,
                  child: SoundPlayerUI.fromTrack(track,
                      showTitle: true, autoFocus: PlayerState().hushOthers)),
              buildSizeBoxExpanded(100)
            ]),
            Column(children: [
              buildSizeBoxExpanded(61),
              Row(children: [
                buildSizeBoxExpanded(20),
                SoundRecorderUI(track,
                    requestPermissions: requestMicrophonePermission),
                buildSizeBoxExpanded(63)
              ]),
              buildSizeBoxExpanded(100)
            ])
          ]));
  }

  Expanded buildSizeBoxExpanded(int flex) =>
      Expanded(flex: flex, child: SizedBox());

  Future<bool> requestMicrophonePermission(
      BuildContext context, Track track) async {
    var granted = false;
    var microphoneRequired = !await Permission.microphone.isGranted;
    if (microphoneRequired) {
      var both = false;
      if (microphoneRequired) both = true;
      var reason = "To record a message we need permission ";
      if (microphoneRequired) reason += "to access your microphone";
      reason += ".";
      if (both) {
        reason += " \n\nWhen prompted click the 'Allow' button on "
            "each of the following prompts.";
      } else {
        reason += " \n\nWhen prompted click the 'Allow' button.";
      }
      if (await showAlertDialog(context, reason)) {
        var permissions = <Permission>[];
        if (microphoneRequired) permissions.add(Permission.microphone);
        await permissions.request();
        granted = await Permission.microphone.isGranted;
        if (!granted) grantFailed(context);
      } else {
        granted = false;
        grantFailed(context);
      }
    } else {
      granted = true;
    }
    return granted;
  }

  Future<bool> showAlertDialog(BuildContext context, String prompt) {
    Widget cancelButton = FlatButton(
        child: Text("Cancel"),
        onPressed: () => Navigator.of(context).pop(false));
    Widget continueButton = FlatButton(
        child: Text("Continue"),
        onPressed: () => Navigator.of(context).pop(true));
    var alert = AlertDialog(
        title: Text("Recording Permissions"),
        content: Text(prompt),
        actions: [cancelButton, continueButton]);
    return showDialog<bool>(
        context: context,
        builder: (context) {
          debugPrint('demo_body.dart, _MainBodyState, showAlertDialog2');
          return alert;
        });
  }

  void grantFailed(BuildContext context) {
    var snackBar = SnackBar(
        content: Text('Recording cannot start as you did not allow '
            'the required permissions'));
    Scaffold.of(context).showSnackBar(snackBar);
  }
}
