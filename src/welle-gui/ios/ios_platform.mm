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

#import <AVFoundation/AVFoundation.h>

#include "ios_platform.h"

void welle_io_configure_ios_audio_session()
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error = nil;

    // "Playback" category: audio is a core feature of the app, so it must
    // keep playing when the ring/silent switch is set to silent, and
    // (together with the "audio" UIBackgroundMode in Info.plist) when the
    // app is in the background.
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error != nil) {
        NSLog(@"welle.io: could not set AVAudioSession category: %@", error);
        error = nil;
    }

    [session setActive:YES error:&error];
    if (error != nil) {
        NSLog(@"welle.io: could not activate AVAudioSession: %@", error);
    }
}
