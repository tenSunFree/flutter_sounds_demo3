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

import 'package:flutter/material.dart';

/// GreyedOut optionally grays out the given child widget.
/// [child] the child widget to display
/// If [greyedOut] is true then the child will be grayed out and
/// any touch activity over the child will be discarded.
/// If [greyedOut] is false then the child will displayed as normal.
/// The [opacity] setting controls the visiblity of the child
/// when it is greyed out. A value of 1.0 makes the child fully visible,
/// a value of 0.0 makes the child fully opaque.
/// The default value of [opacity] is 0.3.
class GrayedOut extends StatelessWidget {
  ///
  final Widget child;

  ///
  final bool grayedOut;

  ///
  final double opacity;

  ///
  GrayedOut({@required this.child, this.grayedOut = true})
      : opacity = grayedOut == true ? 0.3 : 1.0;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
        absorbing: grayedOut, child: Opacity(opacity: opacity, child: child));
  }
}
