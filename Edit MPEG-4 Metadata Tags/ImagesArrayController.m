/*
 *  ImagesArrayController.m
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

#import "ImagesArrayController.h"
#import "AlbumArt.h"

@implementation ImagesArrayController

- (void)awakeFromNib {
	[super awakeFromNib];
	[self addObserver:self
		   forKeyPath:@"arrangedObjects.imageRepresentation"
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:nil];
	[self addObserver:self
		   forKeyPath:@"arrangedObjects"
			  options:NSKeyValueObservingOptionNew
			  context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	if ([keyPath isEqual:@"arrangedObjects.imageRepresentation"]) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[imageView reloadData];
		});
	} else if ([keyPath isEqual:@"arrangedObjects"]) {
		NSUInteger count = 0;
		for (NSManagedObject *item in [self arrangedObjects]) {
			if ([[item valueForKey:@"imageIndex"] unsignedIntegerValue] != count) {
				[item setValue:[NSNumber numberWithUnsignedInteger:count] forKey:@"imageIndex"];
			}
			count++;
		}
		
	}
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


- (void) imageBrowser:(IKImageBrowserView *) aBrowser removeItemsAtIndexes:(NSIndexSet *) indexes
{
	for (NSManagedObject *object in [[self arrangedObjects] objectsAtIndexes:indexes]) {
		[[object managedObjectContext] deleteObject:object];
	}
	[imageView reloadData];
}

- (BOOL) imageBrowser:(IKImageBrowserView *) aBrowser moveItemsAtIndexes: (NSIndexSet *)indexes toIndex:(NSUInteger)destinationIndex
{
	NSMutableArray *items = [NSMutableArray arrayWithCapacity:[indexes count]];
	NSManagedObject *imageObject;
	for (NSManagedObject *item in [[self arrangedObjects] objectsAtIndexes:indexes]) {
		// make new copy
		imageObject = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumArt"
													inManagedObjectContext:[item managedObjectContext]];
		[imageObject setValue:[item valueForKey:@"imageIndex"] forKey:@"imageIndex"];
		[imageObject setValue:[item valueForKey:@"imageType"] forKey:@"imageType"];
		[imageObject setValue:[item valueForKey:@"imageRepresentation"] forKey:@"imageRepresentation"];
		[items addObject:imageObject];
	}
	
	destinationIndex -= [indexes countOfIndexesInRange:NSMakeRange(0, destinationIndex)];
	[self removeObjectsAtArrangedObjectIndexes:indexes];
	[self insertObjects:items atArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(destinationIndex, [items count])]];
    [imageView reloadData];
    
    return YES;
}

- (NSUInteger)imageBrowser:(IKImageBrowserView *) aBrowser writeItemsAtIndexes:(NSIndexSet *) itemIndexes toPasteboard:(NSPasteboard *)pasteboard {	
	[pasteboard clearContents];
	[pasteboard writeObjects:[[self arrangedObjects] objectsAtIndexes:itemIndexes]];
	return [itemIndexes count];
}


@end
