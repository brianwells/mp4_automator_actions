/*
 *  Enable MPEG-4 Chapter Text Track.m
 *
 *  Copyright (C) 2011 Brian D. Wells
 *
 *  This file is part of MP4 Automator Actions.
 *
 *  MP4 Automator Actions is free software: you can redistribute it 
 *  and/or modify it under the terms of the GNU General Public License
 *  as published by the Free Software Foundation, either version 3 of
 *  the License, or (at your option) any later version.
 *
 *  MP4 Automator Actions is distributed in the hope that it will be 
 *  useful, but WITHOUT ANY WARRANTY; without even the implied warranty
 *  of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with MP4 Automator Actions.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Additional permission under GNU GPL version 3 section 7
 *
 *  If you modify MP4 Automator Actions, or any covered work, by linking 
 *  or combining it with MP4v2 (or a modified version of that library), 
 *  containing parts covered by the terms of Mozilla Public License 1.1, 
 *  the licensors of MP4 Automator Actions grant you additional permission 
 *  to convey the resulting work. Corresponding Source for a non-source 
 *  form of such a combination shall include the source code for the parts 
 *  of MP4v2 used as well as that of the covered work.
 *
 *  Author: Brian D. Wells <spam_brian@me.com>
 *  Website: https://github.com/brianwells/mp4_automator_actions
 *
 */

#import "Enable MPEG-4 Chapter Text Track.h"


@implementation Enable_MPEG_4_Chapter_Text_Track

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
    // set up for GCD
    dispatch_queue_t process_queue = dispatch_queue_create("com.briandwells.Automator.Enable_MPEG_4_Chapter_Text_Track", NULL);
    //    dispatch_queue_t process_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t process_group = dispatch_group_create();
    
    // start processing
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[input count]];
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:[input count]];

    for (NSURL *srcURL in input) {
        
        dispatch_group_async(process_group, process_queue, ^{
            NSError *error = nil;
            MP4FileHandle srcFile;
            NSString *trakTrefChap;
            NSUInteger track_index, entry_index;
            MP4TrackId track_id, temp_track_id;
            uint64_t entry_count, ref_track_id, prev_track_id;
            NSString *language;
            
            srcFile = MP4Modify([[srcURL path] UTF8String], 0, 0);
            if (srcFile == MP4_INVALID_FILE_HANDLE) {
                // report error
                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:1 userInfo:nil];
            } else {
                // get lists of tracks
                NSUInteger track_count = MP4GetNumberOfTracks(srcFile, NULL, 0);
                NSMutableDictionary *textTracks =  [NSMutableDictionary dictionaryWithCapacity:track_count];
                NSMutableDictionary *audioTracks = [NSMutableDictionary dictionaryWithCapacity:track_count];
                NSMutableDictionary *videoTracks = [NSMutableDictionary dictionaryWithCapacity:track_count];
                NSMutableArray      *trackRefs =   [NSMutableArray           arrayWithCapacity:track_count];
                const char *track_type;
                char lang_code[4];
                MP4ChapterType primary_type, requested_type;
                MP4Chapter_t *chapters;
                uint32_t chapter_count;
                
                for (track_index = 0; track_index < track_count; track_index++) {
                    track_id = MP4FindTrackId(srcFile, track_index, NULL, 0);
                    if (MP4GetTrackLanguage(srcFile, track_id, lang_code)) {
                        language = [NSString stringWithCString:lang_code encoding:NSUTF8StringEncoding];
                    } else {
                        language = @"";
                    }
                    if (track_id == MP4_INVALID_TRACK_ID) {
                        // report error
                        error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:3 userInfo:nil];        
                        break;
                    } else {
                        track_type = MP4GetTrackType(srcFile, track_id);
                        if (track_type == NULL) {
                            // report error
                            error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:4 userInfo:nil];        
                            break;
                        } else if (strcmp(track_type, MP4_TEXT_TRACK_TYPE) == 0) {
                            [textTracks setObject:language forKey:[NSNumber numberWithUnsignedInteger:track_id]];
                        } else if (strcmp(track_type, MP4_VIDEO_TRACK_TYPE) == 0) {
                            [videoTracks setObject:language forKey:[NSNumber numberWithUnsignedInteger:track_id]];
                        } else if (strcmp(track_type, MP4_AUDIO_TRACK_TYPE) == 0) {
                            [audioTracks setObject:language forKey:[NSNumber numberWithUnsignedInteger:track_id]];
                        }
                        // check for chapter reference
                        trakTrefChap = [NSString stringWithFormat:@"moov.trak[%u].tref.chap", track_index];
                        if (MP4HaveAtom(srcFile, [trakTrefChap UTF8String]) && 
                            MP4GetIntegerProperty(srcFile, 
                                                  [[NSString stringWithFormat:@"%@.entryCount", trakTrefChap] UTF8String], 
                                                  &entry_count))
                        {
                            for (entry_index = 0; entry_index < entry_count; entry_index++) {
                                if (MP4GetIntegerProperty(srcFile,
                                                          [[NSString stringWithFormat:@"%@.entries[%u].trackId", trakTrefChap, entry_index] UTF8String],
                                                          &ref_track_id))
                                {
                                    [trackRefs addObject:[NSArray arrayWithObjects:[NSNumber numberWithUnsignedInteger:track_id],
                                                           [NSNumber numberWithUnsignedInteger:ref_track_id], nil]];
                                }
                                
                            }
                        }
                        
                    }                        
                }
                
                // process track refs
                if (error == nil) {
                    for (NSArray *refs in trackRefs) {
                        [textTracks  removeObjectForKey:[refs objectAtIndex:1]];
                        [audioTracks removeObjectForKey:[refs objectAtIndex:0]];
                        [videoTracks removeObjectForKey:[refs objectAtIndex:0]];
                    }

                    for (NSNumber *text_track in textTracks) {
                        ref_track_id = [text_track unsignedIntegerValue];
                        track_id = MP4_INVALID_TRACK_ID;
                        if ([textTracks count] != 1) {
                            // find first audio track by language 
                            for (NSNumber *audio_track in audioTracks) {
                                if ([[textTracks objectForKey:text_track] isEqual:[audioTracks objectForKey:audio_track]]) {
                                    track_id = [audio_track unsignedIntegerValue];
                                }
                            }
                        }
                        if (track_id == MP4_INVALID_TRACK_ID && [videoTracks count] > 0) {
                            // find first video track
                            track_id = [[[[videoTracks allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0] unsignedIntegerValue];
                        }
                        if (track_id == MP4_INVALID_TRACK_ID && [audioTracks count] > 0) {
                            // find first audio track
                            track_id = [[[[audioTracks allKeys] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0] unsignedIntegerValue];
                        }
                        if (track_id == MP4_INVALID_TRACK_ID) {
                            // report error
                            error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:5 userInfo:nil];        
                            break;
                        } else {
                            // verify timescale
                            if (MP4GetTrackTimeScale(srcFile, track_id) != MP4GetTrackTimeScale(srcFile, ref_track_id)) {
                                // report error
                                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:6 userInfo:nil];        
                                break;
                            }

                            // START BIG HACK!!!
                            
                            temp_track_id = MP4AddChapterTextTrack(srcFile, track_id, MP4GetTrackTimeScale(srcFile, track_id));
                            if (temp_track_id == MP4_INVALID_TRACK_ID) {
                                // report error
                                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:7 userInfo:nil];        
                                break;
                            }
                            MP4DeleteTrack(srcFile, temp_track_id);
                            
                            track_index = MP4FindTrackIndex(srcFile, track_id);
                            if (track_index == -1) {
                                // report error
                                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:8 userInfo:nil];        
                                break;
                            }
                            trakTrefChap = [NSString stringWithFormat:@"moov.trak[%u].tref.chap", track_index];
                            MP4GetIntegerProperty(srcFile, 
                                                  [[NSString stringWithFormat:@"%@.entryCount", trakTrefChap] UTF8String], 
                                                  &entry_count);
                            for (entry_index = 0; entry_index < entry_count; entry_index++) {
                                MP4GetIntegerProperty(srcFile,
                                                      [[NSString stringWithFormat:@"%@.entries[%u].trackId", trakTrefChap, entry_index] UTF8String],
                                                      &prev_track_id);
                                if (prev_track_id == temp_track_id) {
                                    MP4SetIntegerProperty(srcFile,
                                                          [[NSString stringWithFormat:@"%@.entries[%u].trackId", trakTrefChap, entry_index] UTF8String],
                                                          ref_track_id);
                                    break;
                                }
                            }
                            
                            // END BIG HACK!!!
                        }
                    }
                }

                // change chapter format
                if (error == nil) {

                    primary_type = MP4GetChapters(srcFile, &chapters, &chapter_count, MP4ChapterTypeAny);
                    if (primary_type != MP4ChapterTypeNone && chapters != NULL) {

                        // get chapter format
                        switch ([[[self parameters] objectForKey:@"chapterFormat"] unsignedIntegerValue]) {
                            case 0:
								// delete Nero
								// add Qt if primary_type != Qt
                                requested_type = MP4ChapterTypeQt;
                                break;
                            case 1:
								// delete Qt
								// add Nero if primary_type != Nero
                                requested_type = MP4ChapterTypeNero;
                                break;
                            case 2:
								// add Qt if primary_type != Qt
								// add Nero if primary_type != Nero
                                requested_type = MP4ChapterTypeQt | MP4ChapterTypeNero;
                                break;
                            default:
                                // no idea how this would happen...
                                requested_type = MP4ChapterTypeNone;
                                break;
                        }

						if (!(requested_type & MP4ChapterTypeQt)) {
							// delete Qt
							(void)MP4DeleteChapters(srcFile, MP4ChapterTypeQt, MP4_INVALID_TRACK_ID);
						} else if (primary_type != MP4ChapterTypeQt) {
							// add Qt
							if (MP4SetChapters(srcFile, chapters, chapter_count, MP4ChapterTypeQt) != MP4ChapterTypeQt) {
								// report error
								error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:9 userInfo:nil];
							}
						}

						if (!(requested_type & MP4ChapterTypeNero)) {
							// delete Nero
							(void)MP4DeleteChapters(srcFile, MP4ChapterTypeNero, MP4_INVALID_TRACK_ID);
						} else if (primary_type != MP4ChapterTypeNero) {
							// add Nero
							if (MP4SetChapters(srcFile, chapters, chapter_count, MP4ChapterTypeNero) != MP4ChapterTypeNero) {
								// report error
								error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:10 userInfo:nil];
							}
						}

                        MP4Free(chapters);
                    }
                }
                
                // finalize changes to file
                MP4Close(srcFile);
            }

            if (error == nil) {
                // successful
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [returnArray addObject:srcURL];
                });
            } else {
                // report error
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [errorDict setObject:error forKey:srcURL];
                });
                
            }
        });
        
    }
    
    // wait for processing to finish
    dispatch_group_wait(process_group, DISPATCH_TIME_FOREVER);
    dispatch_release(process_group);
    dispatch_release(process_queue);
    
    // check for error
    if ([errorDict count] > 0) {
        for (NSURL *fileURL in errorDict) {
            NSError *error = [errorDict objectForKey:fileURL];
            NSLog(@"%@:%@ %@ (%ld)",[[self bundle] bundleIdentifier],[fileURL path],[error localizedDescription],[error code]);
        }
        *errorInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:errOSASystemError],NSAppleScriptErrorNumber,
                      [NSString stringWithFormat:@"ERROR: Unable to rebuild %ld MP4 file%@",[errorDict count],([errorDict count] == 1 ? @"" : @"s")],NSAppleScriptErrorMessage, 
                      nil];
    }
    
	return returnArray;    
}

@end
