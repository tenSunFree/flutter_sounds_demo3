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

// Values for AUDIO_FOCUS_GAIN on Android
///
class AndroidAudioFocusGain {
  ///belongs to AUDIOFOCUS_GAIN
  static const stopOthers = 1;

  ///
  static const transient = 2;

  ///
  static const transientMayDuck = 3;

  ///
  ///
  static const transientExclusive = 4;
}
