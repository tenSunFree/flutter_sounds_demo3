# Introduction

## Sounds

[![](https://raw.githubusercontent.com/bsutton/sounds/master/SoundsLogo.png)](https://raw.githubusercontent.com/bsutton/sounds/master/SoundsLogo.png)

[![pub version](https://camo.githubusercontent.com/7c696da820eebbf794d24e0b1339ec1a987f8a8a/68747470733a2f2f696d672e736869656c64732e696f2f7075622f762f736f756e64732e7376673f7374796c653d666c61742d737175617265)](https://pub.dartlang.org/packages/sounds)

## Overview

Sounds is a Flutter package allowing you to play and record audio for both the `android` and `ios` platforms.

Sounds provides both a high level API and widgets for:

* play audio 
* record audio

Sounds can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

The Sounds package supports playback from:

* Assets
* Files
* URL

## Features

The Sounds package includes the following features

* Play audio without any UI
* Play audio using the built in SoundPlayerUI Widget.
* Play audio using the OSs' Media Player
* Roll your own UI utilising the Sounds api.
* Record audio without any UI
* Record audio using the builtin SoundRecorderUI Widget.
* Roll your own Recording UI utilising the Sounds api.
* Support for releasing/resuming resources when the app pauses/resumes.

The core classes are:

| Class | Usage |
| :--- | :--- |
| [SoundPlayerUI](soundplayerui.md) | A Flutter Widget Audio Player |
| [SoundRecorderUI](soundrecorderui.md) | A Flutter Widget for recording |
| [QuickPlay](quickplay.md) | Plays an audio file without a UI. Easiest way to play a beep. |
| [SoundPlayer.noUI](soundplayer.md#headless-playback-no-ui) | API to playback audio with fine grained control |
| [SoundPlayer.withShadeUI](soundplayer.md#os-shade-using-the-os-media-ui) | API to playback audio using the OS's Shade \(media player\) |
| [SoundRecorder](soundrecorder.md) | API to record audio with fine grained control. |
| [Track](track.md) | Container for audio used by all of the above classes. |
| [MediaFormat](mediaformat.md) | Defines what MediaFormat is being used. |
| [RecorderPlaybackController](recorderplaybackcontroller.md) | Flutter InheritedWidget used to co-ordinate Recording and Playback in a single UI. |
| [Albums](albums.md) | Play a sequence of Tracks via the OS's Shade \(media player\) |

![](.gitbook/assets/image%20%281%29.png)

### Help

Audio is a fundamental building block needed by almost every flutter project.

I'm looking to make Sounds the go to project for Flutter Audio with support for each of the Flutter supported platforms.

Sounds is a large and complex project which requires me to maintain multiple hardware platforms and test environments.

I greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.

See the [Contributing](contributing/overview.md) section below for details.

#### Sponsorship

If you can't help out by directly contributing code maybe you could Sponsor me so I can spend more time improving Sounds.

Sounds is a large commitment and I'm maintaining several other dart related projects so any support would be greatly appreciated.

Key short term goals are:

* Hire a graphics designer to improve the look of the widgets
* Provide support for the web
* Provide support for a wider range of Codecs
* Provide support for streaming

If I can get enough sponsorship I intend hiring a grad to do a chunk of the dirty work so I can focus on some of the larger features such as Web Support.

You can find the purple heart Sponsor button at the top of the page.

If you can't afford a coffee then show your support by 'liking' the Sounds project on the [pub.dev](https://pub.dev/packages/sounds) site.

## Documentation

[Install](installing.md)

[Manual](https://bsutton.gitbook.io/sounds/)

[API Reference](https://pub.dev/documentation/sounds/latest/)

### Roadmap

See the [Roadmap](roadmap.md) for details on the future of Sounds.

### Contributing

See the [Contributing](contributing/overview.md) guide for details on contributing to Sounds.

The key classes are:

### Api classes

[QuickPlay](quickplay.md) - instantly play an audio file \(no ui\). Perfect for the odd beep.

[Track](track.md) - Defines a track including the artist details and the audio media.

[Album](albums.md) - play a collection of tracks via the OSs' audio UI.

[SoundPlayer](soundplayer.md) - provides an API for playing audio including pause/resume/seek.

[SoundRecorder](soundrecorder.md) - API for recording audio.

### Widgets

[SoundPlayerUI](soundplayerui.md) - displays an HTML 5 style audio controller widget.

[SoundRecorderUI](soundrecorderui.md) - displays a recording widget.

[RecorderPlaybackController](recorderplaybackcontroller.md) - pairs a SoundPlayerUI and SoundRecorderUI to provide a coordinated recording/playback UI.

Note: there are some limitations on the supported [MediaFormat](mediaformat.md).

