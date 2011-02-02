/*
 *  ImageDataTransformer.m
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

#import "ImageDataTransformer.h"


@implementation ImageDataTransformer

+ (Class)transformedValueClass {
	return [NSImage class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSData class]]) {
		return [[[NSImage alloc] initWithData:(NSData *)value] autorelease];
	} else {
		return nil;
	}
}

- (id)reverseTransformedValue:(id)value {
	if ([value isKindOfClass:[NSImage class]]) {
		return [value TIFFRepresentation];
	} else {
		return nil;
	}	
}

@end
