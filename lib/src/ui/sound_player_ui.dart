/*
 * This file is part of Sounds.
 *
 *   Sounds is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Sounds is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Sounds.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sounds_common/sounds_common.dart';

import '../../sounds.dart';
import '../sound_player.dart' show PlayerInvalidStateException;
import 'grayed_out.dart';
import 'recorder_playback_controller.dart';
import 'slider.dart';
import 'slider_position.dart';
import 'tick_builder.dart';

typedef OnLoad = Future<Track> Function(BuildContext context);

/// A HTML 5 style audio play bar.
/// Allows you to play/pause/resume and seek an audio track.
/// The [SoundPlayerUI] displays:
///   a spinner whilst loading audio
///   play/resume buttons
///   a slider to indicate and change the current play position.
///   optionally displays the album title and track if the
///   [Track] contains those details.
class SoundPlayerUI extends StatefulWidget {
  static const int _barHeight = 60;

  final bool _showTitle;

  /// the [Track] we are playing .
  /// If the fromLoader ctor is used this will be null
  /// until the user clicks the Play button and onLoad
  /// returns a non null [Track]
  final Track _track;

  final OnLoad _onLoad;

  final bool _enabled;

  final bool _autoFocus;

  ///
  /// [SoundPlayerUI.fromTrack] Constructs a Playbar with a Track.
  /// [track] is the Track that contains the audio to play.
  ///
  /// The [track] must have been created with a [MediaFormat] otherwise
  /// a [MediaFormatException] will be thrown.
  ///
  /// When the user clicks the play the audio held by the Track will
  /// be played.
  /// If [showTitle] is true (default is false) then the play bar will also
  /// display the track name and album (if set).
  /// If [enabled] is true (the default) then the Player will be enabled.
  /// If [enabled] is false then the player will be disabled and the user
  /// will not be able to click the play button.
  /// The [audioFocus] allows you to control what happens to other
  /// media that is playing when our player starts.
  /// By default we use [AudioFocus.hushOthersWithResume] which will
  /// reduce the volume of any other players.
  SoundPlayerUI.fromTrack(Track track,
      {Key key,
        bool showTitle = false,
        bool enabled = true,
        bool autoFocus = true})
      : _track = track,
        _autoFocus = autoFocus,
        _showTitle = showTitle,
        _onLoad = null,
        _enabled = enabled,
        super(key: key) {
    if (track.mediaFormat == null) {
      // we need the format so we can get the duration.
      throw MediaFormatException('You must provide a mediaFormat to the track');
    }
  }

  /// [SoundPlayerUI.fromLoader] allows you to dynamically provide
  /// a [Track] when the user clicks the play button.
  ///
  /// The [track] must have been created with a [mediaFormat] otherwise
  /// a [MediaFormatException] will be thrown.
  ///
  /// You can cancel the play action by returning
  /// null when _onLoad is called.
  /// [onLoad] is the function that is called when the user clicks the
  /// play button. You return either a Track to be played or null
  /// if you want to cancel the play action.
  /// If [showTitle] is true (default is false) then the play bar will also
  /// display the track name and album (if set).
  /// If [enabled] is true (the default) then the Player will be enabled.
  /// If [enabled] is false then the player will be disabled and the user
  /// will not be able to click the play button.
  /// The [audioFocus] allows you to control what happens to other
  /// media that is playing when our player starts.
  /// By default we use [AudioFocus.hushOthersWithResume] which will
  /// reduce the volume of any other players.
  SoundPlayerUI.fromLoader(OnLoad onLoad,
      {Key key,
        bool showTitle = false,
        bool enabled = true,
        bool autoFocus = true})
      : _onLoad = onLoad,
        _autoFocus = autoFocus,
        _showTitle = showTitle,
        _track = null,
        _enabled = enabled,
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SoundPlayerUIState(enabled: _enabled);
  }
}

/// internal state.
class SoundPlayerUIState extends State<SoundPlayerUI> {
  final SoundPlayer _player;
  final _sliderPosition = SliderPosition();

  /// we keep our own local stream as the players come and go.
  /// This lets our StreamBuilder work without  worrying about
  /// the player's stream changing under it.
  final StreamController<PlaybackDisposition> _localController;

  // we are current play (but may be paused)
  PlayState __playState = PlayState.stopped;

  // Indicates that we have start a transition (play to pause etc)
  // and we should block user interaction until the transition completes.
  bool __transitioning = false;

  /// indicates that we have started the player but we are waiting
  /// for it to load the audio resource.
  bool __loading = false;

  /// If the widget was constructed with a call to [fromLoader] then
  /// [_loadedTrack] holds the track that was loaded last time
  /// we called [play] and the [_loader] method was called.
  /// If the widget was constructed with a call to [fromTrack] then
  /// we use the track i the widget.
  Track _loadedTrack;

  StreamSubscription _playerSubscription;

  /// returns the active track.
  /// If [fromLoader] was called then this may return null.
  Track get track {
    if (widget._onLoad != null) {
      return _loadedTrack;
    } else {
      return widget._track;
    }
  }

  var position = Duration(seconds: 0);
  var duration = Duration(seconds: 0);

  ///
  SoundPlayerUIState({bool enabled})
      : _player = SoundPlayer.noUI(),
        _localController = StreamController<PlaybackDisposition>.broadcast() {
    _sliderPosition.position = Duration(seconds: 0);
    _sliderPosition.maxPosition = Duration(seconds: 0);
    if (!enabled) {
      __playState = PlayState.disabled;
    }

    _setCallbacks();
  }

  @override
  void didUpdateWidget(covariant SoundPlayerUI oldWidget) {
    super.didUpdateWidget(oldWidget);

    Log.d('didUpdateWidget ${track?.artist}');
    track?.duration?.then((duration) {
      _localController.add(PlaybackDisposition(PlaybackDispositionState.init,
          position: Duration.zero, duration: duration));
    });
  }

  /// We can play if we have a non-zero track length or we are dynamically
  /// loading tracks via _onLoad.
  Future<bool> get canPlay async {
    return widget._onLoad != null || (track != null && (track.length > 0));
  }

  /// detect hot reloads when debugging and stop the player.
  /// If we don't the platform specific code keeps running
  /// and sending methodCalls to a slot that no longe exists.
  /// I'm not certain this is working as advertised.
  @override
  void reassemble() async {
    super.reassemble();
    if (track != null) {
      if (_playState != PlayState.stopped) {
        await stop();
      }
      trackRelease(track);
    }
    //Log.d('Hot reload releasing plugin');
    //_player.release();
  }

  @override
  Widget build(BuildContext context) {
    registerPlayer(context, this);
    return ChangeNotifierProvider<SliderPosition>(
        create: (_) => _sliderPosition, child: _buildPlayBar());
  }

  void _setCallbacks() {
    /// TODO
    /// should we chain these events incase the user of our api
    /// also wants to see these events?
    _player.onStarted = ({wasUser}) => _onStarted();
    _player.onStopped = ({wasUser}) => _onStopped();

    /// pipe the new sound players stream to our local controller.
    _player.dispositionStream().listen(_localController.add);
  }

  /// This can occur:
  /// * When the user clicks play and the [SoundPlayer] sends
  ///     an event to indicate the player is up.
  /// * When the app is paused/resume by the user switching away.
  void _onStarted() {
    _loading = false;
    _playState = PlayState.playing;
  }

  void _onStopped() {
    if (widget._autoFocus) {
      _player.audioFocus(AudioFocus.abandonFocus);
    }
    setState(() {
      /// we can get a race condition when we stop the playback
      /// We have disabled the play button and called stop.
      /// The OS then sends an onStopped call which tries
      /// to put the state into a stopped state overriding
      /// the disabled state.
      if (_playState != PlayState.disabled) {
        _playState = PlayState.stopped;
      }
    });
  }

  /// This method is used by the [RecorderPlaybackController] to attached
  /// the [_localController] to the [SoundRecordUI]'s stream.
  /// This is only done when this player is attached to a
  /// [RecorderPlaybackController].
  ///
  /// When recording starts we are attached to the recorderStream.
  /// When recording finishes this method is called with a null and we
  /// revert to the [_player]'s stream.
  ///
  void _connectRecorderStream(Stream<PlaybackDisposition> recorderStream) {
    if (recorderStream != null) {
      recorderStream.listen(_localController.add);
    } else {
      /// revert to piping the player
      _player.dispositionStream().listen(_localController.add);
    }
  }

  @override
  Future<void> dispose() async {
    Log.d('stopping Player on dispose');
    await _stop(supressState: true);
    await _player.release();
    super.dispose();
  }

  Widget _buildPlayBar() {
    var rows = <Widget>[];
    // rows.add(Row(children: [_buildDuration(), _buildSlider()]));
    rows.add(Row(children: [_buildDuration(),]));
    if (widget._showTitle && track != null) rows.add(_buildTitle());

    // return Container(
    //     decoration: BoxDecoration(
    //         color: Colors.grey,
    //         borderRadius: BorderRadius.circular(SoundPlayerUI._barHeight / 2)),
    //     child: Row(children: [
    //       _buildPlayButton(),
    //       Expanded(child: Column(children: rows))
    //     ]));

    return Column(
      children: [
        Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        _buildDuration(),
        Expanded(
          flex: 1,
          child: SizedBox(),
        ),
        _buildTitle(),
        Expanded(
          flex: 9,
          child: SizedBox(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 42,
              child: SizedBox(),
            ),
            _buildPlayButton(),
            Expanded(
              flex: 15,
              child: SizedBox(),
            ),
          ],
        ),


        Expanded(
          flex: 23,
          child: SizedBox(),
        )
      ],
    );
  }

  /// Returns the players current state.
  PlayState get _playState {
    return __playState;
  }

  set _playState(PlayState state) {
    setState(() => __playState = state);
  }

  /// Controls whether the Play button is enabled or not.
  ///
  /// By default the Play Button is enabled.
  ///
  /// Cannot toggle this whilst the player is playing or paused.
  void enablePlayback({@required bool enabled}) {
    assert(__playState != PlayState.playing && __playState != PlayState.paused);
    setState(() {
      if (enabled == true) {
        __playState = PlayState.stopped;
      } else if (enabled == false) {
        __playState = PlayState.disabled;
      }
    });
  }

  /// Called when the user clicks  the Play/Pause button.
  /// If the audio is paused or stopped the audio will start
  /// playing.
  /// If the audio is playing it will be paused.
  ///
  /// see [play] for the method to programmatically start
  /// the audio playing.
  Future<void> _onPlay(BuildContext localContext) async {
    switch (_playState) {
      case PlayState.stopped:
        await play();
        break;

      case PlayState.playing:
      // pause the player
        await pause();
        break;
      case PlayState.paused:
      // resume the player
        await resume();

        break;
      case PlayState.disabled:
      // shouldn't be possible as play button is disabled.
        await _stop();
        break;
    }
  }

  /// Call [resume] to resume playing the audio.
  Future<void> resume() async {
    _transitioning = true;

    try {
      await _player.resume();
      _playState = PlayState.playing;
    } on PlayerInvalidStateException catch (e) {
      Log.w('Error calling resume ${e.toString()}', error: e);
    } finally {
      _transitioning = false;
    }
  }

  /// Call [pause] to pause playing the audio.
  Future<void> pause() async {
    // pause the player
    _transitioning = true;

    try {
      await _player.pause();
      _playState = PlayState.paused;
    } on PlayerInvalidStateException catch (e) {
      Log.w('Error calling pause ${e.toString()}', error: e);
    } finally {
      _transitioning = false;
    }
  }

  /// start playback.
  Future<void> play() async {
    _transitioning = true;
    _loading = true;
    Log.d('Loading starting');

    if (track != null && _player.isPlaying) {
      Log.d('play called whilst player running. Stopping Player first.');
      await _stop();
    }

    Future<Track> trackLoader;

    if (widget._onLoad == null) {
      trackLoader = Future.value(track);
    } else {
      /// release the prior track we played.
      if (track != null) {
        trackRelease(track);
      }

      /// dynamically load the track.
      trackLoader = widget._onLoad(context);
    }

    /// no track then just silently ignore the start action.
    /// This means that _onLoad returned null and the user
    /// can display appropriate errors.
    try {
      _loadedTrack = await trackLoader;
      if (track != null) {
        if (track.mediaFormat == null) {
          // we need the format so we can get the duration.
          throw MediaFormatException(
              'You must provide a mediaFormat to the track');
        }
        await _start();
      } else {
        throw _TrackLoaderException(
            "The onLoad callback returned a null Track which isn't permitted");
      }
    } on MediaFormatException catch (exception, st) {
      Log.e(
        'Error occured loading the track: ${exception.toString()}',
        error: exception,
        stackTrace: st,
      );
    } on _TrackLoaderException {
      Log.w('No Track provided by _onLoad. Call to start has been ignored');
    } finally {
      _loading = false;
      _transitioning = false;
    }
  }

  /// internal start method.
  Future<void> _start() async {
    try {
      if (widget._autoFocus == true) {
        await _player.audioFocus(AudioFocus.hushOthersWithResume);
      }
      await _player.play(track);
      _playState = PlayState.playing;
    } on PlayerInvalidStateException catch (e, st) {
      Log.e('Error calling play() ${e.toString()}', error: e, stackTrace: st);
      _playState = PlayState.stopped;
    } finally {
      _loading = false;
      _transitioning = false;
    }
  }

  /// Call [stop] to stop the audio playing.
  ///
  Future<void> stop() async {
    await _stop();
  }

  ///
  /// interal stop method.
  ///
  Future<void> _stop({bool supressState = false}) async {
    if (!_player.isStopped) {
      /// we always set wasUser to false as this is handled internally
      /// and we don't care how or why the audio was stopped.
      await _player.stop(wasUser: false);
      if (_playerSubscription != null) {
        await _playerSubscription.cancel();
        _playerSubscription = null;
      }
    }

    // if called via dispose we can't trigger setState.
    if (supressState) {
      __playState = PlayState.stopped;
      __transitioning = false;
      __loading = false;
    } else {
      _playState = PlayState.stopped;
      _transitioning = false;
      _loading = false;
    }

    _sliderPosition.position = Duration.zero;
  }

  /// put the ui into a 'loading' state which
  /// will start the spinner.
  set _loading(bool value) {
    setState(() => __loading = value);
  }

  /// current loading state.
  bool get _loading {
    return __loading;
  }

  /// When we are moving between states we mark
  /// ourselves as 'transition' to block other
  /// transitions.
  // ignore: avoid_setters_without_getters
  set _transitioning(bool value) {
    Log.d(green('Transitioning = $value'));
    setState(() => __transitioning = value);
  }

  /// Build the play button which includes the loading spinner and pause button
  ///
  Widget _buildPlayButton() {
    Widget button;

    if (_loading == true) {
      button = Container(
          // color: Color(0x50000000),

          /// use a tick builder so we don't show the spinkit unless
          /// at least 100ms has passed. This stops a little flicker
          /// of the spiner caused by the default loading state.
          child: TickBuilder(
              interval: Duration(milliseconds: 100),
              builder: (context, index) {
                if (index > 1) {
                  return StreamBuilder<PlaybackDisposition>(
                      stream: _localController.stream,
                      initialData: PlaybackDisposition.init(),
                      builder: (context, asyncData) {
                        var disposition = asyncData.data;
                        // Log.e(yellow('state ${disposition.state} '
                        //     'progress: ${disposition.progress}'));
                        var progress = 0.0;
                        switch (disposition.state) {
                          case PlaybackDispositionState.preload:
                            progress = null; // indeterminate
                            break;
                          case PlaybackDispositionState.loading:
                            progress = disposition.progress;
                            break;
                          default:
                            progress = null;
                            break;
                        }
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                              strokeWidth: 5, value: progress),
                        );
                      });
                } else {
                  return Container(width: 32, height: 32);
                }
              }));
    } else {
      button = _buildPlayButtonIcon(button);
      // button = Container(width: double.infinity, color: Color(0x50000000),);
      // button = Row(
      //   mainAxisAlignment: MainAxisAlignment.center,
      //   children: <Widget>[
      //     Text(" hello world "),
      //     Text(" I am Jack "),
      //   ],
      // );
    }
    return Container(
        width: 50,
        height: 50,
        child: Padding(
            padding: EdgeInsets.only(left: 0, right: 0),
            child: FutureBuilder<bool>(
                future: canPlay,
                builder: (context, asyncData) {
                  var _canPlay = false;
                  if (asyncData.connectionState == ConnectionState.done) {
                    _canPlay = asyncData.data && !__transitioning;
                  }

                  return InkWell(
                      onTap: _canPlay ? () => _onPlay(context) : null,
                      child: button);
                })));
  }

  Widget _buildPlayButtonIcon(Widget widget) {
    switch (_playState) {
      case PlayState.playing:
        widget = Icon(Icons.pause, color: Colors.grey, size: 45,);
        break;
      case PlayState.stopped:
      case PlayState.paused:
        widget = FutureBuilder<bool>(
            future: canPlay,
            builder: (context, asyncData) {
              var canPlay = false;
              if (asyncData.connectionState == ConnectionState.done) {
                canPlay = asyncData.data;
              }
              // return Icon(Icons.play_arrow,
              //     color: canPlay ? Colors.black : Colors.blueGrey);
              return canPlay
                  ? Icon(Icons.play_arrow, color: Colors.black45, size: 45,)
                  : Icon(Icons.pause, color: Colors.grey, size: 45,);
            });
        break;
      case PlayState.disabled:
        GrayedOut(
            grayedOut: true,
            child: widget = Icon(Icons.pause, color: Colors.grey, size: 45,));
        break;
    }
    return widget;
  }

  Widget _buildDuration() {
    return StreamBuilder<PlaybackDisposition>(
        stream: _localController.stream,
        initialData: PlaybackDisposition.zero(),
        builder: (context, snapshot) {
          var disposition = snapshot.data;
          print('disposition: $disposition');

          if (duration == Duration(seconds: 0)) {
            print('disposition2: $disposition');
            position = disposition.position;
            duration = disposition.duration;
            print('disposition3: ${Format.duration(disposition.duration)}');
            return Text(
              '${Format.duration(disposition.duration, showSuffix: false)}',
              style: TextStyle(fontSize: 120,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold),);
            print('disposition4: $disposition');
          } else if (duration != Duration(seconds: 0)) {
            if (duration != disposition.duration) {
              position = disposition.position;
              duration = disposition.duration;
              return Text('${Format.duration(
                  disposition.duration, showSuffix: false)}',
                style: TextStyle(fontSize: 120,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),);
            } else if (position != disposition.position) {
              position = disposition.position;
              duration = disposition.duration;
              return Text('${Format.duration(
                  disposition.position, showSuffix: false)}',
                style: TextStyle(fontSize: 120,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),);
            } else {
              position = disposition.position;
              duration = disposition.duration;
              return Text('${Format.duration(
                  disposition.duration, showSuffix: false)}',
                style: TextStyle(fontSize: 120,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold),);
            }

            print('disposition5: $disposition');
          } else if (position != disposition.position) {
            print('disposition6: $disposition');
            return Text(
              '${Format.duration(disposition.position, showSuffix: false)}',
              style: TextStyle(fontSize: 30, color: Colors.grey),);
          } else if (duration != disposition.duration) {
            print('disposition7: $disposition');
            return Text('${Format.duration(disposition.duration)}',
              style: TextStyle(fontSize: 30, color: Colors.grey),);
          } else {
            print('disposition8: $disposition');
            return Container();
          }

          // if()

          // if()


          //
          //

          // return Text(
          //     '${Format.duration(disposition.position, showSuffix: false)}'
          //         ' / '
          //         '${Format.duration(disposition.duration)}');
        });
  }

  Widget _buildSlider() {
    return Expanded(
        child: PlaybarSlider(
          _localController.stream,
              (position) {
            _sliderPosition.position = position;
            _player.seekTo(position);
          },
        ));
  }

  Widget _buildTitle() {
    var columns = <Widget>[];

    if (track.title != null) {
      columns.add(Text(track.title, style: TextStyle(fontSize: 20),));
    }
    if (track.title != null && track.artist != null) {
      columns.add(Text(' / ', style: TextStyle(fontSize: 20),));
    }
    if (track.artist != null) {
      columns.add(Text(track.artist, style: TextStyle(fontSize: 20),));
    }
    return
      Container(
        margin: EdgeInsets.only(bottom: 5),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: columns),
      );
  }
}

/// Describes the state of the playbar.
enum PlayState {
  /// stopped
  stopped,

  ///
  playing,

  ///
  paused,

  ///
  disabled
}

///
/// Functions used to hide internal implementation details
///
// void updatePlayerDuration(SoundPlayerUIState playerState
// , Duration duration) =>
//     playerState?._updateDuration(duration);

void connectPlayerToRecorderStream(SoundPlayerUIState playerState,
    Stream<PlaybackDisposition> recorderStream) {
  playerState._connectRecorderStream(recorderStream);
}

class _TrackLoaderException implements Exception {
  final String _message;

  ///
  _TrackLoaderException(this._message);

  String toString() => _message;
}
