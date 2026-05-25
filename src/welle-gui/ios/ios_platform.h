/*
 *    iOS platform integration for welle.io
 *
 *    This file is part of the welle.io.
 *
 *    welle.io is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 */

#pragma once

/* Configure the iOS audio session for media playback so that audio keeps
 * playing when the device's ring/silent switch is set to silent, and -
 * together with the "audio" UIBackgroundMode - when the app is in the
 * background. Call once at application startup.
 *
 * Implemented in ios_platform.mm (Objective-C++).
 */
void welle_io_configure_ios_audio_session();
