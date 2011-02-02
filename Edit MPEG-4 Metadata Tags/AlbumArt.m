/*
 *  AlbumArt.m
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

#import "AlbumArt.h"


@implementation AlbumArt

@synthesize imageVersion;
@dynamic primitiveImageRepresentation;

- (void)setImageRepresentation:(NSData *)data {
	[self willChangeValueForKey:@"imageRepresentation"];
	[self setPrimitiveImageRepresentation:data];
	[self didChangeValueForKey:@"imageRepresentation"];
	imageVersion++;
}

- (NSString *)imageRepresentationType {
	return IKImageBrowserNSDataRepresentationType;
}

- (NSString *)imageUID {
	return [[[self objectID] URIRepresentation] description];
}

- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard {
	NSUInteger artwork_type = [[self valueForKey:@"imageType"] unsignedIntegerValue];
	NSString *dataType = nil;
	switch (artwork_type) {
		case MP4_ART_JPEG:
			dataType = @"public.jpeg";
			break;
		case MP4_ART_PNG:
			dataType = @"public.png";
			break;
		case MP4_ART_BMP:
			dataType = @"com.microsoft.bmp";
			break;
		case MP4_ART_GIF:
			dataType = @"com.compuserve.gif";
			break;
		default:
			break;
	}
	if (dataType) {
		return [NSArray arrayWithObject:dataType];
	} else {
		return [NSArray array];
	}
}

- (id)pasteboardPropertyListForType:(NSString *)type {
	if (type) {
		return [self valueForKey:@"imageRepresentation"];
	} else {
		return nil;
	}
}

@end
