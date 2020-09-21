import 'package:meta/meta.dart';
import 'package:sounds_common/sounds_common.dart';

import 'adts_aac_media_format.dart';
import 'native_duration_provider.dart';
import 'native_media_formats.dart';

/// Base class for all Native MediaFormat.
/// Native MediaFormat are those MediaFormat which are supported
/// by the underlying OS.
///
/// The available set Native MediaFormat varies depending on the OS and the OS
/// version.
///
/// The [NativeMediaFormat.common] MediaFormat is supported by all OS
/// and OS versions and maps to AACADTSMediaFormat
abstract class NativeMediaFormat extends MediaFormat {
  ///
  const NativeMediaFormat.detail({
    @required String name,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
  }) : super.detail(
          name: name,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitRate: bitRate,
        );

  @override
  Future<bool> get isNativeDecoder async =>
      await NativeMediaFormats().isNativeDecoder(this);

  @override
  Future<bool> get isNativeEncoder async =>
      await NativeMediaFormats().isNativeEncoder(this);

  @override
  Future<Duration> getDuration(String path) =>
      NativeDurationProvider().getDuration(path);

  /// On Android the Codec encoder and the container (file) format a specified
  /// separately.
  ///
  /// The index used by the android encoder (recording) to select
  /// the media format.
  /// This is passed to MediaRecorder.setAudioEncoder and is taken from
  /// MediaRecorder.AudioEncoder
  int get androidEncoder;

  /// The container (file) format used to store the audio.
  /// Values are taken from MediaRecorder.OutputFormat
  /// and passed MediaRecorder.setOutputFormat
  int get androidFormat;

  /// On iOS the Codec encoder and container (file) format are specified
  /// via a single AudioFormat specified in AVFormatIDKey
  /// A list of supported formats:
  /// https://medium.com/@borisdering/ios-core-audio-avformatidkey-dictionary-642a53b509de
  ///
  int get iosFormat;

  /// A common media format supported by all platforms.
  /// You should use this format unless you have a specific
  /// reason to use an alternate format.
  ///
  /// Sounds only records/playbacks using natively supported codecs.
  /// Use the sounds_codec package for utilities to convert to/from
  /// other codecs.
  static NativeMediaFormat common = AdtsAacMediaFormat();
}

// class AMRNBMediaContainer extends MediaContainer {
//   AMRNBMediaContainer() : super('AMR_NB');

//   /// MediaRecorder.OutputFormat.AMR_NB
//   @override
//   int get androidId => 3;

//   @override
//   int get iosId => throw UnsupportedError('AMR_NB is not supported on IOS');
// }

// class AMRWBMediaContainer extends MediaContainer {
//   AMRWBMediaContainer() : super('AMR_WB');

//   /// MediaRecorder.OutputFormat.AMR_WB
//   @override
//   int get androidId => 4;

//   @override
//   int get iosId => throw UnsupportedError('AMR_WB is not supported on IOS');
// }
