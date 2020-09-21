# RecorderPlaybackController

## Overview

The `RecorderPlaybackController` widget provides a means to co-ordinate a [SoundRecorderUI](soundrecorderui.md) and [SoundPlayerUI](soundplayerui.md) so that a user can record and playback via a single UI.

The `RecorderPlaybackController` is an InheritedWidget which allows the [SoundRecorderUI](soundrecorderui.md) and [SoundPlayerUI](soundplayerui.md) to find and attach to it.

[SoundRecorderUI](soundrecorderui.md) and [SoundPlayerUI](soundplayerui.md) widgets will automatically search for and attach to the nearest `RecorderPlaybackController` above them in the widget tree.

Due to the automated nature of the linkage you need to be careful where you place a `RecorderPlaybackController` in your widget tree to avoid unintentional connections. Keep the `RecorderPlaybackController` as close to the other two widgets as possible.

The `RecorderPlaybackController` MUST be above `SoundPlayerUI` and the `SoundRecorderUI` widgets in the Widget tree.

## Example:

This example is from the example app. It demonstrates how to create a Recorder `SoundRecorderUI` linked to a `SoundPlayerUI`.

The example demonstrates how to build a UI which allows a user to record audio and then immediately play it back.

The example also uses `requestPermissions` to display an explanatory dialog to the user before the OS displays its standard permission dialog.

The [RecorderPlaybackController](recorderplaybackcontroller.md) is responsible for coordinating the recording and playback so that only one can occur at a time.

```dart
import 'dart:async';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:sounds/sounds.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  var recordingPath = Track.tempFile(MediaFormat.aacADTS);
  runApp(SoundExampleApp._internal(recordingPath));
}

class SoundExampleApp extends StatelessWidget {
  final Track _track;

  //
  SoundExampleApp._internal(String recordingPath)
      : _track = Track.fromFile(recordingPath, mediaFormat: MediaFormat.aacADTS);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome to Flutter',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Welcome to Flutter'),
        ),
        body: buildBody(),
      ),
    );
  }

  Widget buildBody() {
    // link the recorder and player so you can record
    // and then playback the message.
    // Note: the recorder and player MUST share the same track.
    return RecorderPlaybackController(
        child: Column(
      children: [
        /// Add the recorder
        SoundRecorderUI(
          /// the track to record into.
          _track,

          /// callback for when recording needs permissions
          requestPermissions: requestPermissions,
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          // add the player
          child: SoundPlayerUI.fromTrack(_track),
        )
      ],
    ));
  }

  /// Callback for when the recorder needs permissions to record
  /// to the [track].
  Future<bool> requestPermissions(BuildContext context, Track track) async {
    var granted = false;

    /// change this to true if the track doesn't use
    /// external storage on android.
    var usingExternalStorage = false;

    // Request Microphone permission if needed
    print('storage: ${await Permission.microphone.status}');
    var microphoneRequired = !await Permission.microphone.isGranted;

    var storageRequired = false;

    if (usingExternalStorage) {
      /// only required if track is on external storage
      if (Permission.storage.status == PermissionStatus.undetermined) {
        print('You are probably missing the storage permission '
            'in your manifest.');
      }

      storageRequired =
          usingExternalStorage && !await Permission.storage.isGranted;
    }

    /// build the 'reason' why and what we are asking permissions for.
    if (microphoneRequired || storageRequired) {
      var both = false;

      if (microphoneRequired && storageRequired) {
        both = true;
      }

      var reason = "To record a message we need permission ";

      if (microphoneRequired) {
        reason += "to access your microphone";
      }

      if (both) {
        reason += " and ";
      }

      if (storageRequired) {
        reason += "to store a file on your phone";
      }

      reason += ".";

      if (both) {
        reason += " \n\nWhen prompted click the 'Allow' button on "
            "each of the following prompts.";
      } else {
        reason += " \n\nWhen prompted click the 'Allow' button.";
      }

      /// tell the user we are about to ask for permissions.
      if (await showAlertDialog(context, reason)) {
        var permissions = <Permission>[];
        if (microphoneRequired) permissions.add(Permission.microphone);
        if (storageRequired) permissions.add(Permission.storage);

        /// ask for the permissions.
        await permissions.request();

        /// check the user gave us the permissions.
        granted = await Permission.microphone.isGranted &&
            await Permission.storage.isGranted;
        if (!granted) grantFailed(context);
      } else {
        granted = false;
        grantFailed(context);
      }
    } else {
      granted = true;
    }

    // we already have the required permissions.
    return granted;
  }

  /// Display a snackbar saying that we can't record due to lack of permissions.
  void grantFailed(BuildContext context) {
    var snackBar = SnackBar(
        content: Text('Recording cannot start as you did not allow '
            'the required permissions'));

    // Find the Scaffold in the widget tree and use it to show a SnackBar.
    Scaffold.of(context).showSnackBar(snackBar);
  }

  ///
  Future<bool> showAlertDialog(BuildContext context, String prompt) {
    // set up the buttons
    Widget cancelButton = FlatButton(
      child: Text("Cancel"),
      onPressed: () => Navigator.of(context).pop(false),
    );
    Widget continueButton = FlatButton(
      child: Text("Continue"),
      onPressed: () => Navigator.of(context).pop(true),
    );

    // set up the AlertDialog
    var alert = AlertDialog(
      title: Text("Recording Permissions"),
      content: Text(prompt),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return alert;
      },
    );
  }
}
```

