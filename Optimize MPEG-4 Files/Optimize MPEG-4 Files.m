/*
 *  Optimize MPEG-4 Files.m
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

#import "Optimize MPEG-4 Files.h"


@implementation Optimize_MPEG_4_Files

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
    NSFileManager *fm = [NSFileManager defaultManager];

    // set up for GCD
    dispatch_queue_t process_queue = dispatch_queue_create("com.briandwells.Automator.Optimize_MPEG_4_Files", NULL);
    //    dispatch_queue_t process_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t process_group = dispatch_group_create();
    
    // start processing
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[input count]];
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:[input count]];
	
    for (NSURL *srcURL in input) {
		dispatch_group_async(process_group, process_queue, ^{
            NSError *error = nil;
			
			// get temp file name
            CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
            CFStringRef uuidStr = CFUUIDCreateString(kCFAllocatorDefault, uuid);
            NSURL *tmpURL = [[srcURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:[NSString stringWithFormat:@".%@.tmp",uuidStr]];
            CFRelease(uuidStr);
            CFRelease(uuid);
			
			// optimize to temp file
			if (!MP4Optimize([[srcURL path] UTF8String], [[tmpURL path] UTF8String], 0)) {
				// report error
                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:1 userInfo:nil];
			}

            // replace original file with temp file
            if (error == nil && [fm removeItemAtURL:srcURL error:&error] && [fm moveItemAtURL:tmpURL toURL:srcURL error:&error]) {
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
