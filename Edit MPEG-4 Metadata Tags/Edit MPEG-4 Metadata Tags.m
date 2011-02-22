/*
 *  Edit MPEG-4 Metadata Tags.m
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

#import "Edit MPEG-4 Metadata Tags.h"

#define menu_val(nam,val) [NSDictionary dictionaryWithObjectsAndKeys:val,@"value",nam,@"name",nil]
#define menu_int(nam,val) menu_val(nam,[[NSNumber numberWithInt:val] stringValue])
#define menu_txt(nam) menu_val(nam,nam)

#define get_tag_txt(parm,tag_name) if (tags->tag_name != nil) \
[fileObject setValue:[NSString stringWithUTF8String:tags->tag_name] forKey:parm];

#define get_tag_txt(parm,tag_name) if (tags->tag_name != nil) \
[fileObject setValue:[NSString stringWithUTF8String:tags->tag_name] forKey:parm];

#define get_tag_int(parm,tag_name) if (tags->tag_name != nil) \
[fileObject setValue:[[NSNumber numberWithUnsignedInteger:*(tags->tag_name)] stringValue] forKey:parm];

#define get_tag_bol(parm,tag_name) if (tags->tag_name != nil) \
[fileObject setValue:[NSNumber numberWithBool:*(tags->tag_name)] forKey:parm];

#define set_tag_txt(parm,tag_name) if ([changedTags containsObject:parm]) { \
value = [fileObject valueForKey:parm]; \
tag_name(tags, (isEmpty(value) ? NULL : [value UTF8String])); \
}

#define set_tag_i16(parm,tag_name) if ([changedTags containsObject:parm]) { \
value = [fileObject valueForKey:parm]; \
if (!isEmpty(value)) { \
uint16_value = [value integerValue]; \
tag_name(tags, &uint16_value); \
} else { \
tag_name(tags, NULL); \
} \
}

#define set_tag_i32(parm,tag_name) if ([changedTags containsObject:parm]) { \
value = [fileObject valueForKey:parm]; \
if (!isEmpty(value)) { \
uint32_value = [value integerValue]; \
tag_name(tags, &uint32_value); \
} else { \
tag_name(tags, NULL); \
} \
}

#define set_tag_bol(parm,tag_name) if ([changedTags containsObject:parm]) { \
value = [fileObject valueForKey:parm]; \
if (!isEmpty(value)) { \
uint8_value = [value integerValue]; \
tag_name(tags, &uint8_value); \
} else { \
tag_name(tags, NULL); \
} \
}

#define TTYPE @"type"
#define TDATA @"data"

#define clr_tag(name) [tagsToClear addObject:name];
#define set_tag(name,type,value) [tagsToSet setObject:[NSDictionary dictionaryWithObjectsAndKeys: \
[NSNumber numberWithInt:type], TTYPE, [NSData dataWithBytes:&value length:sizeof(value)], TDATA, \
nil] forKey:name]; \
clr_tag(name);

static inline BOOL isEmpty(id thing) {
	if (thing == nil) {
		return YES;
	} else if ([thing isKindOfClass:[NSNull class]]) {
		return YES;
	} else if ([thing respondsToSelector:@selector(length)]) {
		if ([(NSData *)thing length] == 0) {
			return YES;
		}
	} else if ([thing respondsToSelector:@selector(count)]) {
		if ([(NSArray *)thing count] == 0) {
			return YES;
		}
	} else if ([thing respondsToSelector:@selector(integerValue)]) {
		if ([(NSNumber *)thing integerValue] == 0) {
			return YES;
		}
	}
	return NO;
}

@implementation Edit_MPEG_4_Metadata_Tags

+ (void)initialize {
    ImageDataTransformer *transformer = [[[ImageDataTransformer alloc] init] autorelease];
    [NSValueTransformer setValueTransformer:transformer forName:@"ImageDataTransformer"];
}

//- (void)awakeFromNib
- (void)opened
{	
	// can be called multiple times by Automator

	// populate menus
	[genreController setContent:[NSArray arrayWithObjects:
								 menu_int(@"None",				 0),
								 
								 // iTunes genres
								 menu_int(@"Alternative",		21),
								 menu_txt(@"Blues/R&B"			  ),
								 menu_txt(@"Books & Spoken"       ),
								 menu_txt(@"Children's Music"     ),
								 menu_int(@"Classical",         33),
								 menu_int(@"Country",			 3),
								 menu_int(@"Dance",				 4),
								 menu_int(@"Easy Listening",	99),
								 menu_int(@"Electronic",		53),
								 menu_int(@"Folk",				81),
								 menu_txt(@"Hip Hop/Rap"          ),
								 menu_txt(@"Holiday"			  ),
								 menu_int(@"House",				36),
								 menu_int(@"Industrial",		20),
								 menu_txt(@"iTunes U"			  ),
								 menu_int(@"Jazz",				 9),
								 menu_int(@"New Age",			11),
								 menu_int(@"Pop",				14),
								 menu_txt(@"Religious"            ),
								 menu_int(@"Rock",				18),
								 menu_int(@"Soundtrack",		25),
								 menu_int(@"Techno",			19),
								 menu_int(@"Trance",			32),
								 menu_txt(@"Unclassifiable"       ),
								 menu_txt(@"World"				  ),
								 
								 
	/*								 
	 // ID3v1 genres
	 menu_int(@"Blues",				 1),
	 menu_int(@"Classic Rock",		 2),
	 menu_int(@"Country",			 3),
	 menu_int(@"Dance",				 4),
	 menu_int(@"Disco",				 5),
	 menu_int(@"Funk",				 6),
	 menu_int(@"Grunge",			 7),
	 menu_int(@"Hop-Hop",			 8),
	 menu_int(@"Jazz",				 9),
	 menu_int(@"Metal",				10),
	 menu_int(@"New Age",			11),
	 menu_int(@"Oldies",			12),
	 menu_int(@"Other",				13),
	 menu_int(@"Pop",				14),
	 menu_int(@"R&B",				15),
	 menu_int(@"Rap",				16),
	 menu_int(@"Reggae",			17),
	 menu_int(@"Rock",				18),
	 menu_int(@"Techno",			19),
	 menu_int(@"Industrial",		20),
	 menu_int(@"Alternative",		21),
	 menu_int(@"Ska",				22),
	 menu_int(@"Death Metal",		23),
	 menu_int(@"Pranks",			24),
	 menu_int(@"Soundtrack",		25),
	 menu_int(@"Euro-Techno",		26),
	 menu_int(@"Ambient",			27),
	 menu_int(@"Trip-Hop",			28),
	 menu_int(@"Vocal",				29),
	 menu_int(@"Jazz+Funk",			30),
	 menu_int(@"Fusion",			31),
	 menu_int(@"Trance",			32),
	 menu_int(@"Classical",			33),
	 menu_int(@"Instrumental",		34),
	 menu_int(@"Acid",				35),
	 menu_int(@"House",				36),
	 menu_int(@"Game",				37),
	 menu_int(@"Sound Clip",		38),
	 menu_int(@"Gospel",			39),
	 menu_int(@"Noise",				40),
	 menu_int(@"AlternRock",		41),
	 menu_int(@"Bass",				42),
	 menu_int(@"Soul",				43),
	 menu_int(@"Punk",				44),
	 menu_int(@"Space",				45),
	 menu_int(@"Meditative",		46),
	 menu_int(@"Instrumental Pop",	47),
	 menu_int(@"Instrumental Rock",	48),
	 menu_int(@"Ethnic",			49),
	 menu_int(@"Gothic",			50),
	 menu_int(@"Darkwave",			51),
	 menu_int(@"Techno-Industrial",	52),
	 menu_int(@"Electronic",		53),
	 menu_int(@"Pop-Folk",			54),
	 menu_int(@"Eurodance",			55),
	 menu_int(@"Dream",				56),
	 menu_int(@"Southern Rock",		57),
	 menu_int(@"Comedy",			58),
	 menu_int(@"Cult",				59),
	 menu_int(@"Gangsta",			60),
	 menu_int(@"Top 40",			61),
	 menu_int(@"Christian Rap",		62),
	 menu_int(@"Pop/Funk",			63),
	 menu_int(@"Jungle",			64),
	 menu_int(@"Native American",	65),
	 menu_int(@"Cabaret",			66),
	 menu_int(@"New Wave",			67),
	 menu_int(@"Psychedelic",		68),
	 menu_int(@"Rave",				69),
	 menu_int(@"Showtunes",			70),
	 menu_int(@"Trailer",			71),
	 menu_int(@"Lo-Fi",				72),
	 menu_int(@"Tribal",			73),
	 menu_int(@"Acid Punk",			74),
	 menu_int(@"Acid Jazz",			75),
	 menu_int(@"Polka",				76),
	 menu_int(@"Retro",				77),
	 menu_int(@"Musical",			78),
	 menu_int(@"Rock & Roll",		79),
	 menu_int(@"Hard Rock",			80),
	 */
								 nil]];
	
	[mediaKindController setContent:[NSArray arrayWithObjects:
									 menu_int(@"None",				 0),
									 menu_int(@"Music",				 1),
									 menu_int(@"Audiobook",			 2),
									 menu_val(@"Podcast",	   @"pcst"),
									 menu_val(@"iTunes U",     @"itnu"),
									 menu_int(@"Music Video",		 6),
									 menu_int(@"Movie",				 9),
									 menu_int(@"TV Show",			10),
									 menu_int(@"Booklet",			11),
									 menu_int(@"Ringtone",			14),
									 nil]];
	[contentRatingController setContent:[NSArray arrayWithObjects:
										 menu_int(@"None",			 0),
										 menu_int(@"Clean",			 2),
										 menu_int(@"Explicit",		 4),
										 nil]];

	if (results == nil)
		results = [[NSMutableDictionary dictionaryWithCapacity:3] retain];
	
	[super opened];
}

- (NSManagedObjectModel *)managedObjectModel {
	return [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[self bundle]]];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (persistentStoreCoordinator == nil) {
		persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
		[persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:nil];
	}
	return persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
	if (managedObjectContext == nil) {
		managedObjectContext = [[NSManagedObjectContext alloc] init];
		[managedObjectContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
	}
	return managedObjectContext;
}

- (NSArray *)filesSortDescriptors {
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"fileIndex" ascending:YES] autorelease]];
}

- (NSArray *)imagesSortDescriptors {
	return [NSArray arrayWithObject:[[[NSSortDescriptor alloc] initWithKey:@"imageIndex" ascending:YES] autorelease]];
}

- (void)runAsynchronouslyWithInput:(id)input
{
	// set up for GCD
    dispatch_queue_t process_queue = dispatch_queue_create("com.briandwells.Automator.Edit_MPEG_4_Metadata_Tags", NULL);
    //    dispatch_queue_t process_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t process_group = dispatch_group_create();

    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
																	object:nil 
																	 queue:[NSOperationQueue mainQueue] 
																usingBlock:^(NSNotification *notification)
	{
		// handle save notification
		if ([notification object] != [self managedObjectContext]) {
			[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
		}
		
	}];
	
    // read metadata from files
	
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:[input count]];
	NSWorkspace *ws = [NSWorkspace sharedWorkspace];
	NSUInteger counter = 0;
	
    for (NSURL *srcURL in input) {
        
        dispatch_group_async(process_group, process_queue, ^{
			NSError *error = nil;
            MP4FileHandle srcFile;
			NSManagedObject *fileObject;
			NSManagedObject *imageObject;
			MP4ItmfItemList *tagList;
			MP4ItmfItem *tagItem;
			MP4ItmfData *tagData;
			const MP4Tags *tags;
			uint8_t itnu_value = 0;
			NSUInteger count;

			NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
			[threadContext setUndoManager:nil];
			[threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
			
			srcFile = MP4Read([[srcURL path] UTF8String], 0);
            if (srcFile == MP4_INVALID_FILE_HANDLE) {
                // report error
                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:1 userInfo:nil];
            } else {
				fileObject = [NSEntityDescription insertNewObjectForEntityForName:@"MPEGFile"
														   inManagedObjectContext:threadContext];
				[fileObject setValue:[srcURL absoluteString] forKey:@"fileURL"];
				[fileObject setValue:[srcURL lastPathComponent] forKey:@"fileName"];
				[fileObject setValue:[NSNumber numberWithUnsignedInteger:counter] forKey:@"fileIndex"];
				[fileObject setValue:[[ws iconForFile:[srcURL path]] TIFFRepresentation] forKey:@"fileIcon"];
				
				// read "itnu"
				tagList = MP4ItmfGetItemsByCode(srcFile, "itnu");
				if (tagList && tagList->size != 0) {
					tagItem = &tagList->elements[0];
					tagData = &tagItem->dataList.elements[0];
					itnu_value = tagData->value[0];	// assume one byte for now
					MP4ItmfItemListFree(tagList);
				}
				
				tags = MP4TagsAlloc();
				MP4TagsFetch(tags, srcFile);
				
				get_tag_txt(@"tagName",					name);
				get_tag_txt(@"tagArtist",				artist);
				get_tag_txt(@"tagAlbumArtist",			albumArtist);
				get_tag_txt(@"tagAlbum",				album);
				get_tag_txt(@"tagGrouping",				grouping);
				get_tag_txt(@"tagComposer",				composer);
				get_tag_txt(@"tagDescription",			description);
				get_tag_txt(@"tagLongDescription",		longDescription);
				get_tag_txt(@"tagReleaseDate",			releaseDate);
				get_tag_txt(@"tagTVShow",				tvShow);
				get_tag_txt(@"tagTVNetwork",			tvNetwork);
				get_tag_txt(@"tagTVEpisodeID",			tvEpisodeID);
				get_tag_txt(@"tagSortName",				sortName);
				get_tag_txt(@"tagSortArtist",			sortArtist);
				get_tag_txt(@"tagSortAlbumArtist",		sortAlbumArtist);
				get_tag_txt(@"tagSortAlbum",			sortAlbum);
				get_tag_txt(@"tagSortComposer",			sortComposer);
				get_tag_txt(@"tagSortTVShow",			sortTVShow);
				get_tag_txt(@"tagCopyright",			copyright);
				get_tag_txt(@"tagEncodingTool",			encodingTool);
				get_tag_txt(@"tagEncodedBy",			encodedBy);
				get_tag_txt(@"tagPurchaseDate",			purchaseDate);
				get_tag_txt(@"tagKeywords",				keywords);
				get_tag_txt(@"tagCategory",				category);
				get_tag_txt(@"tagLyrics",				lyrics);
				get_tag_txt(@"tagComments",				comments);
				
				get_tag_int(@"tagTempo",				tempo);
				get_tag_int(@"tagTVEpisodeNumber",		tvEpisode);
				get_tag_int(@"tagTVSeasonNumber",		tvSeason);
				get_tag_int(@"tagContentRating",		contentRating);
				
				get_tag_bol(@"tagCompilation",			compilation);
				get_tag_bol(@"tagHDVideo",				hdVideo);
				get_tag_bol(@"tagGaplessPlayback",		gapless);
				
				if (tags->track != nil) {
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:tags->track->index] stringValue]
								  forKey:@"tagTrackNumber"];
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:tags->track->total] stringValue]
								  forKey:@"tagTrackTotal"];					
				}
				if (tags->disk != nil) {
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:tags->disk->index] stringValue]
								  forKey:@"tagDiscNumber"];
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:tags->disk->total] stringValue]
								  forKey:@"tagDiscTotal"];					
				}
				
				if (tags->genre != nil) {
					[fileObject setValue:[NSString stringWithUTF8String:tags->genre] forKey:@"tagGenre"];
				} else if (tags->genreType != nil) {
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:*(tags->genreType)] stringValue] forKey:@"tagGenre"];
				}
				
				if (itnu_value != 0) {
					[fileObject setValue:@"itnu" forKey:@"tagMediaType"];
				} else if (tags->podcast != 0 && *(tags->podcast) != 0) {
					[fileObject setValue:@"pcst" forKey:@"tagMediaType"];
				} else if (tags->mediaType != 0) {
					[fileObject setValue:[[NSNumber numberWithUnsignedInteger:*(tags->mediaType)] stringValue] forKey:@"tagMediaType"];
				}
				
				for (count = 0; count < tags->artworkCount; count++) {
					imageObject = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumArt"
															   inManagedObjectContext:threadContext];
					[imageObject setValue:[NSNumber numberWithUnsignedInteger:count] forKey:@"imageIndex"];
					[imageObject setValue:[NSNumber numberWithUnsignedInteger:tags->artwork[count].type] forKey:@"imageType"];
					[imageObject setValue:[NSData dataWithBytes:tags->artwork[count].data length:tags->artwork[count].size] forKey:@"imageRepresentation"];
					[imageObject setValue:fileObject forKey:@"mpegFile"];
				}
				
				MP4TagsFree(tags);
				MP4Close(srcFile);
			}
			
            if (error == nil) {
                // successful
				[threadContext save:&error];
            }
			if (error != nil) {
                // report error
				[threadContext reset];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [errorDict setObject:error forKey:srcURL];
                });
                
            }
			
			[threadContext release];
			threadContext = nil;
		});
		counter++;
	}
	
	// wait for processing to finish
    dispatch_group_wait(process_group, DISPATCH_TIME_FOREVER);
    dispatch_release(process_group);
    dispatch_release(process_queue);
    
	[[NSNotificationCenter defaultCenter] removeObserver:observer];
	
    // check for error
    if ([errorDict count] > 0) {
        for (NSURL *fileURL in errorDict) {
            NSError *error = [errorDict objectForKey:fileURL];
            NSLog(@"%@:%@ %@ (%ld)",[[self bundle] bundleIdentifier],[fileURL path],[error localizedDescription],[error code]);
        }
		[self didFinishRunningWithError:[NSDictionary dictionaryWithObjectsAndKeys:
                      [NSNumber numberWithInt:errOSASystemError],NSAppleScriptErrorNumber,
                      [NSString stringWithFormat:@"ERROR: Unable to process %ld MP4 file%@",[errorDict count],([errorDict count] == 1 ? @"" : @"s")],NSAppleScriptErrorMessage, 
                      nil]];
    }
	
	// show user interface
	[tagsWindow makeKeyAndOrderFront:self];
}

- (IBAction)saveAction:(id)sender {
	[tagsWindow endEditingFor:nil];
	[tagsWindow orderOut:self];
	
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:3];
    NSError *error = nil;

	// set up for GCD
    dispatch_queue_t process_queue = dispatch_queue_create("com.briandwells.Automator.Edit_MPEG_4_Metadata_Tags.process", NULL);
    dispatch_queue_t report_queue = dispatch_queue_create("com.briandwells.Automator.Edit_MPEG_4_Metadata_Tags.report", NULL);
    //    dispatch_queue_t process_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_group_t process_group = dispatch_group_create();
	
	// get files
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setPredicate:nil];
	[fetchRequest setSortDescriptors:[self filesSortDescriptors]];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"MPEGFile" inManagedObjectContext:[self managedObjectContext]]];
	NSArray *fetchResult = [managedObjectContext executeFetchRequest:fetchRequest error:&error];

	if (fetchResult == nil) {
		[errorDict setObject:error forKey:@"Internal Error"];
	} else {
		// get list of changed values
		NSMutableDictionary *fileChanges = [NSMutableDictionary dictionaryWithCapacity:[fetchResult count]];
		for (NSManagedObject *fileObject in fetchResult) {
			NSDictionary *updatedValues = [fileObject changedValues];
			if ([updatedValues count] > 0) {
				[fileChanges setObject:[updatedValues allKeys]
								forKey:[fileObject objectID]];
			} else {
				[results setObject:[fileObject valueForKey:@"fileIndex"]
							forKey:[NSURL URLWithString:[fileObject valueForKey:@"fileURL"]]];
			}
		}
		
		// save changes
		[[self managedObjectContext] save:&error];
		if (error) {
			[errorDict setObject:error forKey:@"Internal Error"];
		} else {
			// process changes
			for (NSManagedObjectID *fileID in fileChanges) {				

				dispatch_group_async(process_group, process_queue, ^{
					NSError *error = nil;
					MP4FileHandle dstFile;
					const MP4Tags *tags;
					id value, value2;
					uint32_t uint32_value;
					uint16_t uint16_value;
					uint8_t uint8_value;
					MP4TagTrack track;
					MP4TagDisk disc;
					MP4TagArtwork artwork;
					NSMutableSet *tagsToClear = [NSMutableSet setWithCapacity:2];
					NSMutableDictionary *tagsToSet = [NSMutableDictionary dictionaryWithCapacity:2];
					id errorObject;
					NSURL *dstURL = nil;
					
					NSManagedObjectContext *threadContext = [[NSManagedObjectContext alloc] init];
					[threadContext setUndoManager:nil];
					[threadContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
					
					NSManagedObject *fileObject = [threadContext existingObjectWithID:fileID error:&error];
					if (!fileObject) {
						errorObject = @"Internal Error";
					} else {
						dstURL = [NSURL URLWithString:[fileObject valueForKey:@"fileURL"]];
						errorObject = dstURL;
						dstFile = MP4Modify([[dstURL path] UTF8String], 0, 0);
						if (dstFile == MP4_INVALID_FILE_HANDLE) {
							// report error
							error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:1 userInfo:nil];
						} else {
							tags = MP4TagsAlloc();
							MP4TagsFetch(tags, dstFile);
							NSArray *changedTags = [fileChanges objectForKey:fileID];

							set_tag_txt(@"tagName",				MP4TagsSetName				);
							set_tag_txt(@"tagArtist",			MP4TagsSetArtist			);
							set_tag_txt(@"tagAlbumArtist",		MP4TagsSetAlbumArtist		);
							set_tag_txt(@"tagAlbum",			MP4TagsSetAlbum				);
							set_tag_txt(@"tagGrouping",			MP4TagsSetGrouping			);
							set_tag_txt(@"tagComposer",			MP4TagsSetComposer			);
							set_tag_txt(@"tagDescription",		MP4TagsSetDescription		);
							set_tag_txt(@"tagLongDescription",	MP4TagsSetLongDescription	);
							set_tag_txt(@"tagReleaseDate",		MP4TagsSetReleaseDate		);
							set_tag_txt(@"tagTVShow",			MP4TagsSetTVShow			);
							set_tag_txt(@"tagTVNetwork",		MP4TagsSetTVNetwork			);
							set_tag_txt(@"tagTVEpisodeID",		MP4TagsSetTVEpisodeID		);
							set_tag_txt(@"tagSortName",			MP4TagsSetSortName			);
							set_tag_txt(@"tagSortArtist",		MP4TagsSetSortArtist		);
							set_tag_txt(@"tagSortAlbumArtist",	MP4TagsSetSortAlbumArtist	);
							set_tag_txt(@"tagSortAlbum",		MP4TagsSetSortAlbum			);
							set_tag_txt(@"tagSortComposer",		MP4TagsSetSortComposer		);
							set_tag_txt(@"tagSortTVShow",		MP4TagsSetSortTVShow		);
							set_tag_txt(@"tagCopyright",		MP4TagsSetCopyright			);
							set_tag_txt(@"tagEncodingTool",		MP4TagsSetEncodingTool		);
							set_tag_txt(@"tagEncodedBy",		MP4TagsSetEncodedBy			);
							set_tag_txt(@"tagPurchaseDate",		MP4TagsSetPurchaseDate		);
							set_tag_txt(@"tagKeywords",			MP4TagsSetKeywords			);
							set_tag_txt(@"tagCategory",			MP4TagsSetCategory			);
							set_tag_txt(@"tagLyrics",			MP4TagsSetLyrics			);
							set_tag_txt(@"tagComments",			MP4TagsSetComments			);
							
							set_tag_i16(@"tagTempo",			MP4TagsSetTempo				);
							set_tag_i32(@"tagTVEpisodeNumber",	MP4TagsSetTVEpisode			);
							set_tag_i32(@"tagTVSeasonNumber",	MP4TagsSetTVSeason			);
							
							set_tag_bol(@"tagCompilation",		MP4TagsSetCompilation		);
							set_tag_bol(@"tagHDVideo",			MP4TagsSetHDVideo			);
							set_tag_bol(@"tagGaplessPlayback",	MP4TagsSetGapless			);
							
							if ([changedTags containsObject:@"tagGenre"]) {
								value = [fileObject valueForKey:@"tagGenre"];
								if (isEmpty(value)) {
									MP4TagsSetGenreType(tags, NULL);
									MP4TagsSetGenre(tags, NULL);
								} else {
									if ([value isKindOfClass:[NSNumber class]]) {
										uint16_value = CFSwapInt16HostToBig([value unsignedIntegerValue]);
										set_tag(@"gnre",MP4_ITMF_BT_IMPLICIT,uint16_value);
										MP4TagsSetGenre(tags, NULL);
									} else {
										MP4TagsSetGenreType(tags, NULL);
										MP4TagsSetGenre(tags, [value UTF8String]);
									}
								}
							}
							
							if ([changedTags containsObject:@"tagContentRating"]) {
								value = [fileObject valueForKey:@"tagContentRating"];
								if (isEmpty(value)) {
									MP4TagsSetContentRating(tags, NULL);
								} else {
									uint8_value = [(NSNumber *)value unsignedIntegerValue];
									MP4TagsSetContentRating(tags, &uint8_value);
								}
							}
							
							if ([changedTags containsObject:@"tagMediaType"]) {
								value = [fileObject valueForKey:@"tagMediaType"];
								clr_tag(@"pcst");
								clr_tag(@"itnu");
								if (isEmpty(value)) {
									MP4TagsSetMediaType(tags, NULL);
								} else {
									if ([value isKindOfClass:[NSNumber class]]) {
										uint8_value = [value unsignedIntegerValue];
										MP4TagsSetMediaType(tags, &uint8_value);
									} else {
										MP4TagsSetMediaType(tags, NULL);
										uint8_value = 1;
										set_tag(value,MP4_ITMF_BT_INTEGER,uint8_value);
									}								
								}
							}
							
							if ([changedTags containsObject:@"tagTrackNumber"] || [changedTags containsObject:@"tagTrackTotal"]) {
								value = [fileObject valueForKey:@"tagTrackNumber"];
								value2 = [fileObject valueForKey:@"tagTrackTotal"];
								if (isEmpty(value) && isEmpty(value2)) {
									MP4TagsSetTrack(tags, NULL);
								} else {
									track.index = [value integerValue];
									track.total = [value2 integerValue];
									MP4TagsSetTrack(tags, &track);
								}
							}
							
							if ([changedTags containsObject:@"tagDiscNumber"] || [changedTags containsObject:@"tagDiscTotal"]) {
								value = [fileObject valueForKey:@"tagDiscNumber"];
								value2 = [fileObject valueForKey:@"tagDiscTotal"];
								if (isEmpty(value) && isEmpty(value2)) {
									MP4TagsSetDisk(tags, NULL);
								} else {
									disc.index = [value integerValue];
									disc.total = [value2 integerValue];
									MP4TagsSetDisk(tags, &disc);
								}
							}
							
							if ([changedTags containsObject:@"tagArtwork"]) {
								// fetch artwork
								NSFetchRequest *artRequest = [[[NSFetchRequest alloc] init] autorelease];
								[artRequest setPredicate:[NSPredicate predicateWithFormat:@"mpegFile == %@", fileObject]];
								[artRequest setSortDescriptors:[self imagesSortDescriptors]];
								[artRequest setEntity:[NSEntityDescription entityForName:@"AlbumArt" inManagedObjectContext:[self managedObjectContext]]];
								NSArray *art = [managedObjectContext executeFetchRequest:artRequest error:&error];
								if (art) {
									// remove existing artwork
									while (tags->artworkCount > 0) {
										MP4TagsRemoveArtwork(tags, 0);
									}
									// add new artwork
									for (NSManagedObject *imageObject in art) {
										NSData *data = [imageObject valueForKey:@"imageRepresentation"];
										artwork.data = (void *)[data bytes];
										artwork.size = [data length];
										artwork.type = [[imageObject valueForKey:@"imageType"] unsignedIntegerValue];
										MP4TagsAddArtwork(tags, &artwork);
									}
								}
							}						
							
							// save changes to file
							MP4TagsStore(tags, dstFile);
							MP4TagsFree(tags);
							
							//
							if ([tagsToSet count] > 0 || [tagsToClear count] > 0) {
								for (NSString *code in tagsToClear) {
									MP4ItmfItemList *list = MP4ItmfGetItemsByCode(dstFile, [code UTF8String]);
									if (list) {
										uint32_t i;
										for (i = 0; i < list->size; i++) {
											MP4ItmfItem* item = &list->elements[i];
											MP4ItmfRemoveItem(dstFile, item);
										}
										MP4ItmfItemListFree(list);
									}
								}
								for (NSString *code in tagsToSet) {
									NSData *temp = [[tagsToSet objectForKey:code] objectForKey:TDATA];
									MP4ItmfItem *item = MP4ItmfItemAlloc([code UTF8String], 1);
									MP4ItmfData *data = &item->dataList.elements[0];
									data->typeCode = [[[tagsToSet objectForKey:code] objectForKey:TTYPE] integerValue];
									data->valueSize = [temp length];
									data->value = (uint8_t*)malloc(data->valueSize);
									memcpy(data->value, [temp bytes], data->valueSize);
									MP4ItmfAddItem(dstFile, item);
									MP4ItmfItemFree(item);
								}
							}				
							
							MP4Close(dstFile);
						}
						
					}
					
					if (error == nil) {
						// successful
						dispatch_group_async(process_group, report_queue, ^{
							[results setObject:[fileObject valueForKey:@"fileIndex"]
										forKey:dstURL];
						});
					} else {
						// report error
						dispatch_group_async(process_group, report_queue, ^{
							[errorDict setObject:error forKey:errorObject];
						});
					}

					[threadContext release];
					threadContext = nil;
				});					
			}
		}
	}
	
	// wait for processing to finish
    dispatch_group_wait(process_group, DISPATCH_TIME_FOREVER);
    dispatch_release(process_group);
    dispatch_release(process_queue);
    dispatch_release(report_queue);

    // check for error
    if ([errorDict count] > 0) {
        for (id errorObject in errorDict) {
            NSError *error = [errorDict objectForKey:errorObject];
            NSLog(@"%@:%@ %@ (%ld)",[[self bundle] bundleIdentifier],
				  ([errorObject isKindOfClass:[NSURL class]] ? [errorObject path] : errorObject),
				  [error localizedDescription],[error code]);
        }
		[self didFinishRunningWithError:[NSDictionary dictionaryWithObjectsAndKeys:
										 [NSNumber numberWithInt:errOSASystemError],NSAppleScriptErrorNumber,
										 [NSString stringWithFormat:@"ERROR: Unable to process %ld MP4 file%@",[errorDict count],([errorDict count] == 1 ? @"" : @"s")],NSAppleScriptErrorMessage, 
										 nil]];
    } else {
		[self didFinishRunningWithError:nil];
	}
}

- (IBAction)cancelAction:(id)sender {
	[tagsWindow orderOut:self];
	[self didFinishRunningWithError:[NSDictionary dictionaryWithObjectsAndKeys:
									 [NSNumber numberWithInt:userCanceledErr],NSAppleScriptErrorNumber,
									 @"User aborted action",NSAppleScriptErrorMessage, 
									 nil]];	
}

- (void)willFinishRunning
{
	// clear out data
	[[self managedObjectContext] reset];
	// default tab selection
	[tabView selectFirstTabViewItem:self];
}

- (id)output
{
	// return results
	return [results keysSortedByValueUsingSelector:@selector(compare:)];
}

- (void)closed
{
	// clean up
	[results release];
	results = nil;
	[managedObjectContext release];
	managedObjectContext = nil;
	[persistentStoreCoordinator release];
	persistentStoreCoordinator = nil;
}

- (IBAction) addArtworkImage:(id)sender
{

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:
									@"public.jpeg",
									@"public.png",
									@"com.microsoft.bmp",
									@"com.compuserve.gif",
									nil]];
	[openPanel beginSheetModalForWindow:[artworkBrowser window] completionHandler:^(NSInteger result) {
        if (result) {
			NSArray *files = [openPanel URLs];
			for (NSURL *fileURL in files) {
				[imagesController addArtworkFromURL:fileURL index:NSUIntegerMax];
			}
			[artworkBrowser reloadData];
			NSRange selection = NSMakeRange([[imagesController arrangedObjects] count] - [files count], [files count]);
			[imagesController setSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:selection]];
        }
    }];

}

- (IBAction) removeArtworkImage:(id)sender
{
	NSIndexSet *selection = [imagesController selectionIndexes];
	if ([selection count] != 0) {
		[imagesController removeObjectsAtArrangedObjectIndexes:selection];
	} else {
		// clear entire list of images
		[imagesController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,[[imagesController arrangedObjects] count])]];
	}
	[artworkBrowser reloadData];
}

@end
