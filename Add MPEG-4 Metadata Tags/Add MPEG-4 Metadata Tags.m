/*
 *  Add MPEG-4 Metadata Tags.m
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

#import "Add MPEG-4 Metadata Tags.h"

#define menu_val(nam,val) [NSDictionary dictionaryWithObjectsAndKeys:val,@"value",nam,@"name",nil]
#define menu_int(nam,val) menu_val(nam,[NSNumber numberWithInt:val])
#define menu_txt(nam) menu_val(nam,nam)

#define set_tag_txt(parm,tag_name) value = [[self parameters] objectForKey:parm]; \
if (!isEmpty(value)) { \
	value = expandMacros(value,counter,total); \
	tag_name(tags, [value UTF8String]); \
	changes++; \
}
#define set_tag_i16(parm,tag_name) value = [[self parameters] objectForKey:parm]; \
if (!isEmpty(value)) { \
	value = expandMacros(value,counter,total); \
	uint16_value = [value integerValue]; \
	tag_name(tags, &uint16_value); \
	changes++; \
}
#define set_tag_i32(parm,tag_name) value = [[self parameters] objectForKey:parm]; \
if (!isEmpty(value)) { \
uint32_value = [value integerValue]; \
tag_name(tags, &uint32_value); \
changes++; \
}

#define set_tag_bol(parm,tag_name) value = [[self parameters] objectForKey:parm]; \
if (!isEmpty(value)) { \
	uint8_value = [value integerValue]; \
	tag_name(tags, &uint8_value); \
	changes++; \
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

static NSString * expandMacros(NSString *value, NSUInteger count, NSUInteger total) {
	NSRange work = NSMakeRange(0, [value length]);
	NSMutableString *newValue = [NSMutableString stringWithCapacity:[value length]];
	NSRange range = [value rangeOfString:@"%[" options:NSLiteralSearch range:work];
	while (range.location != NSNotFound) {
		if (range.location > work.location) {
			[newValue appendString:[value substringWithRange:NSMakeRange(work.location, range.location - work.location)]];
		}
		work = NSMakeRange(range.location + range.length, work.length - (range.location - work.location) - range.length);
		// find end of macro
		range = [value rangeOfString:@"]" options:NSLiteralSearch range:work];
		if (range.location == NSNotFound) {
			// no more macros
			[newValue appendString:[value substringWithRange:NSMakeRange(work.location - 2, work.length + 2)]];
			work.length = 0;
		} else {
			// try to expand macro
			NSString *macroValue = [value substringWithRange:NSMakeRange(work.location, range.location - work.location)];
			NSString *macroResult = nil;
			NSUInteger minLength;
			
			unichar c = [[macroValue lowercaseString] characterAtIndex:0];
			switch (c) {
				case 'i':
					minLength = ([macroValue characterAtIndex:1] == '0' ? [macroValue length] - 1 : 0);
					macroResult = [NSString stringWithFormat:(minLength == 0 ? @"%lu" : [NSString stringWithFormat:@"%%0%dlu",minLength]),
								   [[macroValue substringFromIndex:1] integerValue] + count];
					break;
				case 't':
					minLength = ([macroValue characterAtIndex:1] == '0' ? [macroValue length] - 1 : 0);
					macroResult = [NSString stringWithFormat:(minLength == 0 ? @"%lu" : [NSString stringWithFormat:@"%%0%dlu",minLength]),
								   total];
					break;
				default:
					break;
			}

			if (macroResult == nil) {
				[newValue appendString:[value substringWithRange:NSMakeRange(work.location - 2, range.location - work.location + 3)]];
			} else {
				[newValue appendString:macroResult];
			}
			work = NSMakeRange(range.location + range.length, work.length - (range.location - work.location) - range.length);
			range = [value rangeOfString:@"%[" options:NSLiteralSearch range:work];
		}
	}
	[newValue appendString:[value substringWithRange:work]];
	return newValue;
}

@implementation Add_MPEG_4_Metadata_Tags

//- (void)awakeFromNib {
- (void)opened
{
	if (artworkImages == nil)
		artworkImages = [[NSMutableArray alloc] init];

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
	[lyricsView setString:[[self parameters] objectForKey:@"tagLyrics"]];
	[artworkImages removeAllObjects];
	[[[self parameters] objectForKey:@"tagArtwork"] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[artworkImages addObject:[NSURL URLWithString:obj]];
	}];
	[artworkBrowser reloadData];

	[indexTokenField setStringValue:@""];
	[indexTokenField setObjectValue:[NSArray arrayWithObjects:
									@"%[i0]",	@"%[i1]",
									@"%[i00]",	@"%[i01]",
									@"%[i000]",	@"%[i001]",
									nil]];
	[totalTokenField setStringValue:@""];
	[totalTokenField setObjectValue:[NSArray arrayWithObjects:@"%[t1]", @"%[t01]", @"%[t001]", nil]];

	[super opened];
}

- (void)closed
{
	[artworkImages release];
	artworkImages = nil;
	[super closed];
}

- (void)writeToDictionary:(NSMutableDictionary *)dictionary
{
	NSMutableArray *art = [NSMutableArray arrayWithCapacity:[artworkImages count]];
	[artworkImages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		[art addObject:[obj absoluteString]];
	}];
	[[self parameters] setObject:art forKey:@"tagArtwork"];
	[[self parameters] setObject:[NSString stringWithString:[lyricsView string]] forKey:@"tagLyrics"];
	[super writeToDictionary:dictionary];
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
			[artworkImages addObjectsFromArray:[openPanel URLs]];
			[artworkBrowser reloadData];
        }
    }];
}

- (IBAction) removeArtworkImage:(id)sender
{
	NSIndexSet *selection = [artworkBrowser selectionIndexes];
	if ([selection count] != 0) {
		[artworkImages removeObjectsAtIndexes:selection];
	} else {
		// clear entire list of images
		[artworkImages removeAllObjects];
	}
	[artworkBrowser reloadData];
}

- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) aBrowser
{
	return [artworkImages count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index
{
	return [artworkImages objectAtIndex:index];
}

- (void) imageBrowser:(IKImageBrowserView *) aBrowser removeItemsAtIndexes:(NSIndexSet *) indexes
{
	[artworkImages removeObjectsAtIndexes:indexes];
	[artworkBrowser reloadData];
}

- (BOOL) imageBrowser:(IKImageBrowserView *) aBrowser moveItemsAtIndexes: (NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
	NSArray *tempArray = [artworkImages objectsAtIndexes:indexes];
    [artworkImages removeObjectsAtIndexes:indexes];
    
    destinationIndex -= [indexes countOfIndexesInRange:NSMakeRange(0, destinationIndex)];
    [artworkImages insertObjects:tempArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [tempArray count])]];
    [artworkBrowser reloadData];
    
    return YES;
}

- (id)tokenField:(NSTokenField *)_tokenField representedObjectForEditingString:(NSString *)_editingString
{
	return _editingString;
}

- (NSArray *)tokenField:(NSTokenField *)_tokenField shouldAddObjects:(NSArray *)_tokens atIndex:(NSUInteger)_index
{
	NSArray *result = [super tokenField:_tokenField shouldAddObjects:_tokens atIndex:_index];
	NSMutableArray *newResult = [NSMutableArray arrayWithCapacity:[result count]];
	NSCharacterSet *set = [NSCharacterSet lowercaseLetterCharacterSet];
	for (NSString *token in result) {
		if ([token hasPrefix:@"%["] && [token hasSuffix:@"]"] && [set characterIsMember:[token characterAtIndex:2]]) {
			token = [NSString stringWithFormat:@"%%[%@%@]",
						[[NSString stringWithFormat:@"%c",[token characterAtIndex:2]] uppercaseString],
						[token substringWithRange:NSMakeRange(3, [token length] - 4)]];
		}
		[newResult addObject:token];
	}
	return newResult;
}

- (NSTokenStyle)tokenField:(NSTokenField *)_tokenField styleForRepresentedObject:(id)_representedObject
{
	NSTokenStyle style = [super tokenField:_tokenField styleForRepresentedObject:_representedObject];
	if (style == NSPlainTextTokenStyle &&
		[_representedObject hasPrefix:@"%["] &&
		[_representedObject hasSuffix:@"]"]) {
		style = NSRoundedTokenStyle;
	}
	return style;
}

- (NSString *)tokenField:(NSTokenField *)_tokenField displayStringForRepresentedObject:(id)_representedObject
{
	NSString *result = [super tokenField:_tokenField displayStringForRepresentedObject:_representedObject];
	if ([result isEqualToString:_representedObject] &&
		[_representedObject hasPrefix:@"%["] &&
		[_representedObject hasSuffix:@"]"]) {
		unichar c = [_representedObject characterAtIndex:2];
		switch (c) {
			case 'I':
				result = [NSString stringWithFormat:@"Index %@", [_representedObject substringWithRange:NSMakeRange(3, [_representedObject length] - 4)]];
				break;
			case 'i':
			case 't':
				result = [_representedObject substringWithRange:NSMakeRange(3, [_representedObject length] - 4)];
				break;
			case 'T':
				result = [NSString stringWithFormat:@"Total %@", [_representedObject substringWithRange:NSMakeRange(3, [_representedObject length] - 4)]];
				break;
			default:
				break;
		}
	}
	return result;
}

- (id)runWithInput:(id)input fromAction:(AMAction *)anAction error:(NSDictionary **)errorInfo
{
    // set up for GCD
    dispatch_queue_t process_queue = dispatch_queue_create("com.briandwells.Automator.Add_MPEG_4_Metadata_Tags", NULL);
    //    dispatch_queue_t process_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_group_t process_group = dispatch_group_create();
    
    // start processing
    NSMutableArray *returnArray = [NSMutableArray arrayWithCapacity:[input count]];
    NSMutableDictionary *errorDict = [NSMutableDictionary dictionaryWithCapacity:[input count]];
	
	NSUInteger counter = 0;
	NSUInteger total = [input count];
    for (NSURL *srcURL in input) {
        
        dispatch_group_async(process_group, process_queue, ^{
			NSError *error = nil;
            MP4FileHandle srcFile;
			const MP4Tags *tags;
			id value, value2;
			NSInteger changes = 0;
			uint32_t uint32_value;
			uint16_t uint16_value;
			uint8_t uint8_value;
			MP4TagTrack track;
			MP4TagDisk disc;
			MP4TagArtwork artwork;
			NSMutableSet *tagsToClear = [NSMutableSet setWithCapacity:2];
			NSMutableDictionary *tagsToSet = [NSMutableDictionary dictionaryWithCapacity:2];

            srcFile = MP4Modify([[srcURL path] UTF8String], 0, 0);
            if (srcFile == MP4_INVALID_FILE_HANDLE) {
                // report error
                error = [NSError errorWithDomain:[[self bundle] bundleIdentifier] code:1 userInfo:nil];
            } else {
				tags = MP4TagsAlloc();
				MP4TagsFetch(tags, srcFile);
				
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
				
				value = [[self parameters] objectForKey:@"tagGenre"];
				if (!isEmpty(value)) {
					if ([value isKindOfClass:[NSNumber class]]) {
						uint16_value = CFSwapInt16HostToBig([value unsignedIntegerValue]);
						set_tag(@"gnre",MP4_ITMF_BT_IMPLICIT,uint16_value);
						MP4TagsSetGenre(tags, NULL);
					} else {
						MP4TagsSetGenreType(tags, NULL);
						MP4TagsSetGenre(tags, [value UTF8String]);
					}
					changes++;
				}
				
				value = [[self parameters] objectForKey:@"tagContentRating"];
				if (!isEmpty(value)) {
					uint8_value = [(NSNumber *)value unsignedIntegerValue];
					MP4TagsSetContentRating(tags, &uint8_value);
					changes++;
				}

				value = [[self parameters] objectForKey:@"tagMediaType"];
				if (!isEmpty(value)) {
					clr_tag(@"pcst");
					clr_tag(@"itnu");
					if ([value isKindOfClass:[NSNumber class]]) {
						uint8_value = [value unsignedIntegerValue];
						MP4TagsSetMediaType(tags, &uint8_value);
					} else {
						MP4TagsSetMediaType(tags, NULL);
						uint8_value = 1;
						set_tag(value,MP4_ITMF_BT_INTEGER,uint8_value);
					}
					changes++;
				}
				
				value = [[self parameters] objectForKey:@"tagTrackNumber"];
				value2 = [[self parameters] objectForKey:@"tagTrackTotal"];
				if (!isEmpty(value) || !isEmpty(value2)) {
					value = expandMacros(value,counter,total);
					value2 = expandMacros(value2,counter,total);
					track.index = [value integerValue];
					track.total = [value2 integerValue];
					MP4TagsSetTrack(tags, &track);
					changes++;
				}

				value = [[self parameters] objectForKey:@"tagDiscNumber"];
				value2 = [[self parameters] objectForKey:@"tagDiscTotal"];
				if (!isEmpty(value) || !isEmpty(value2)) {
					value = expandMacros(value,counter,total);
					value2 = expandMacros(value2,counter,total);
					disc.index = [value integerValue];
					disc.total = [value2 integerValue];
					MP4TagsSetDisk(tags, &disc);
					changes++;
				}
				
				value = [[self parameters] objectForKey:@"tagArtwork"];
				if (!isEmpty(value)) {
					// remove existing artwork
					while (tags->artworkCount > 0) {
						MP4TagsRemoveArtwork(tags, 0);
					}
					// add new artwork
					for (NSString *url_str in value) {
						NSURL *file_url = [NSURL URLWithString:url_str];
						NSData *data = [NSData dataWithContentsOfURL:file_url 
															 options:NSDataReadingUncached 
															   error:&error];
						if (data) {
							artwork.data = (void *)[data bytes];
							artwork.size = [data length];
							// get type
							CFStringRef uti = NULL;
							LSItemInfoRecord file_info;
							if (LSCopyItemInfoForURL((CFURLRef)file_url, kLSRequestExtension | kLSRequestTypeCreator, &file_info) == noErr) {
								if (file_info.extension != NULL) {
									uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
																				file_info.extension,
																				kUTTypeData);
									CFRelease(file_info.extension);
								}
								if (uti == NULL) {
									CFStringRef type_str = UTCreateStringForOSType(file_info.filetype);
									if (type_str != NULL) {
										uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassOSType,
																					type_str, 
																					kUTTypeData);
										CFRelease(type_str);
									}
								}
								
								if (UTTypeConformsTo(uti, CFSTR("public.jpeg"))) {
									artwork.type = MP4_ART_JPEG;
								} else if (UTTypeConformsTo(uti, CFSTR("public.png"))) {
									artwork.type = MP4_ART_PNG;
								} else if (UTTypeConformsTo(uti, CFSTR("com.microsoft.bmp"))) {
									artwork.type = MP4_ART_BMP;
								} else if (UTTypeConformsTo(uti, CFSTR("com.compuserve.gif"))) {
									artwork.type = MP4_ART_GIF;
								} else {
									artwork.type = MP4_ART_UNDEFINED;
								}
								if (uti != NULL) {
									CFRelease(uti);
									uti = NULL;
								}
								MP4TagsAddArtwork(tags, &artwork);
							}
						} else {
							// error should contain NSError
							break;
						}
					}
					changes++;
				}
				
				if (changes)
					MP4TagsStore(tags, srcFile);
				MP4TagsFree(tags);
				
				//
				if ([tagsToSet count] > 0 || [tagsToClear count] > 0) {
					for (NSString *code in tagsToClear) {
						MP4ItmfItemList *list = MP4ItmfGetItemsByCode(srcFile, [code UTF8String]);
						if (list) {
							uint32_t i;
							for (i = 0; i < list->size; i++) {
								MP4ItmfItem* item = &list->elements[i];
								MP4ItmfRemoveItem(srcFile, item);
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
						MP4ItmfAddItem(srcFile, item);
						MP4ItmfItemFree(item);
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
		
		counter++;
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
                      [NSString stringWithFormat:@"ERROR: Unable to process %ld MP4 file%@",[errorDict count],([errorDict count] == 1 ? @"" : @"s")],NSAppleScriptErrorMessage, 
                      nil];
    }
    
	return returnArray;    
}

@end
