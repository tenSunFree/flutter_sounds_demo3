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
import 'package:sounds_common/sounds_common.dart';

///
class PlaybarSlider extends StatefulWidget {
  final void Function(Duration position) _seek;

  ///
  final Stream<PlaybackDisposition> stream;

  ///
  PlaybarSlider(this.stream, this._seek);

  @override
  State<StatefulWidget> createState() {
    return PlaybarSliderState();
  }
}

///
class PlaybarSliderState extends State<PlaybarSlider> {
  @override
  Widget build(BuildContext context) {
    return SliderTheme(
        data: SliderTheme.of(context).copyWith(
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.0),
            inactiveTrackColor: Colors.blueGrey),
        child: StreamBuilder<PlaybackDisposition>(
            stream: widget.stream,
            initialData: PlaybackDisposition.zero(),
            builder: (context, snapshot) {
              var disposition = snapshot.data;
              return Slider(
                max: disposition.duration.inMilliseconds.toDouble(),
                value: disposition.position.inMilliseconds.toDouble(),
                onChanged: (value) =>
                    widget._seek(Duration(milliseconds: value.toInt())),
              );
            }));
  }
}
