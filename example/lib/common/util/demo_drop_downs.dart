import 'package:flutter/material.dart';
import 'package:sounds_common/sounds_common.dart';
import 'package:sounds/sounds.dart';
import 'package:sounds_demo/common/util/demo_media_path.dart';
import 'demo_active_codec.dart';
import 'demo_common.dart';

/// Widget containing the set of drop downs used in the UI
/// Media
/// MediaFormat
class Dropdowns extends StatefulWidget {
  final void Function(MediaFormat) _onMediaFormatChanged;

  /// ctor
  const Dropdowns({
    Key key,
    @required void Function(MediaFormat) onMediaFormatChanged,
  })  : _onMediaFormatChanged = onMediaFormatChanged,
        super(key: key);

  @override
  _DropdownsState createState() => _DropdownsState();
}

class _DropdownsState extends State<Dropdowns> {
  _DropdownsState();

  @override
  Widget build(BuildContext context) {
    final mediaDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('Record To:'),
        ),
        buildMediaDropdown(),
      ],
    );

    final codecDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('MediaFormat:'),
        ),
        buildCodecDropdown(),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            mediaDropdown,
            // Flexible(child: Container(color: Color(0xFF43435), width:30,height: 10),),
//
            Container(color: Color(0xFF000000), width: 30, height: 10),
//
            // // Flexible(child: Container(color: Color(0xFF232345), height: 10),),
            // Flexible(child: codecDropdown,),
            codecDropdown,
          ],
        ),
      ),



    );
  }

  Widget buildCodecDropdown() {
    return FutureBuilder<List<NativeMediaFormat>>(
        future: NativeMediaFormats().encoders,
        builder: (context, asynData) {
          if (!asynData.hasData)
            return Text('Loading MediaFormats');
          else {
            var menuItems = <DropdownMenuItem<MediaFormat>>[];

            for (var mediaFormat in asynData.data) {
              menuItems.add(DropdownMenuItem<MediaFormat>(
                value: mediaFormat,
                child: Text(mediaFormat.name),
              ));
            }

            return DropdownButton<MediaFormat>(
                value: ActiveMediaFormat().mediaFormat,
                onChanged: (newMediaFormat) async {
                  widget._onMediaFormatChanged(newMediaFormat);

                  /// this is hacky as we should be passing the actual
                  /// useOSUI flag.
                  await ActiveMediaFormat().setMediaFormat(
                      withShadeUI: false, mediaFormat: newMediaFormat);

                  //await getDuration(ActiveMediaFormat().mediaFormat);
                  setState(() {});
                },
                items: menuItems);
          }
        });
  }

  DropdownButton<MediaStorage> buildMediaDropdown() {
    return DropdownButton<MediaStorage>(
      value: MediaPath().media,
      onChanged: (newMedia) {
        MediaPath().media = newMedia;

        setState(() {});
      },
      items: <DropdownMenuItem<MediaStorage>>[
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.file,
          child: Text('File'),
        ),
        DropdownMenuItem<MediaStorage>(
          value: MediaStorage.buffer,
          child: Text('Buffer'),
        ),
      ],
    );
  }
}
