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

@synthesize droppedIndexes;

- (void)awakeFromNib {
	[super awakeFromNib];
	self.droppedIndexes = [NSIndexSet indexSet];
	[self addObserver:self
		   forKeyPath:@"arrangedObjects.imageRepresentation"
			  options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
			  context:nil];
	[self addObserver:self
		   forKeyPath:@"arrangedObjects"
			  options:NSKeyValueObservingOptionNew
			  context:nil];
	[imageView registerForDraggedTypes:[NSArray arrayWithObject:NSFilenamesPboardType]];
}

- (void) dealloc
{
    self.droppedIndexes = nil;
    [super dealloc];
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

- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    NSPasteboard *pboard = [sender draggingPasteboard];
	self.droppedIndexes = [NSIndexSet indexSet];

	if ([pboard availableTypeFromArray:[NSArray arrayWithObject:NSFilenamesPboardType]] != nil) {
		return NSDragOperationEvery;
	}

	return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSUInteger location = [imageView indexAtLocationOfDroppedItem];
	NSUInteger count = 0;
	for (id file in [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType]) {
		NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:file];
		[self addArtworkFromURL:fileURL index:location + count];
		[fileURL release];
		fileURL = nil;
		count++;
	}
	self.droppedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(location, count)];
	return YES;
}

- (void)concludeDragOperation:(id < NSDraggingInfo >)sender
{
	[imageView reloadData];
	[self setSelectionIndexes:self.droppedIndexes];
}


- (void) addArtworkFromURL:(NSURL *)fileURL index:(NSUInteger)index
{
	NSManagedObject *imageObject;
	NSData *fileData;
	NSImage *fileImage = nil;
	NSError *error = nil;

	fileData = [NSData dataWithContentsOfURL:fileURL
									 options:NSDataReadingUncached
									   error:&error];
	if (!error) {
		// pre-flight image
		fileImage = [[NSImage alloc] initWithData:fileData];
		if (!fileImage) {
			error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadCorruptFileError userInfo:nil];
		}
	}
	if (error) {
		// complain about any error reading the file
		NSAlert *alert = [[NSAlert alloc] init];
		[alert addButtonWithTitle:@"Continue"];
		[alert setMessageText:[NSString stringWithFormat:@"Unable to read file \"%@\".",[fileURL lastPathComponent]]];
		[alert setInformativeText:[error localizedDescription]];
		[alert setAlertStyle:NSCriticalAlertStyle];
		[alert runModal];
		[alert release];
	} else {
		// get type
		NSUInteger artwork_type = MP4_ART_UNDEFINED;
		CFStringRef uti = NULL;
		LSItemInfoRecord file_info;
		if (LSCopyItemInfoForURL((CFURLRef)fileURL, kLSRequestExtension | kLSRequestTypeCreator, &file_info) == noErr) {
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
				artwork_type = MP4_ART_JPEG;
			} else if (UTTypeConformsTo(uti, CFSTR("public.png"))) {
				artwork_type = MP4_ART_PNG;
			} else if (UTTypeConformsTo(uti, CFSTR("com.microsoft.bmp"))) {
				artwork_type = MP4_ART_BMP;
			} else if (UTTypeConformsTo(uti, CFSTR("com.compuserve.gif"))) {
				artwork_type = MP4_ART_GIF;
			} else {
				// should do something sane here if unknown image?
			}
			if (uti != NULL) {
				CFRelease(uti);
				uti = NULL;
			}
		}

		// bump existing images
		if (index != NSUIntegerMax) {
			for (NSManagedObject *item in [self arrangedObjects]) {
				NSUInteger position = [[item valueForKey:@"imageIndex"] unsignedIntegerValue];
				if (position >= index) {
					[item setValue:[NSNumber numberWithUnsignedInteger:position + 1] forKey:@"imageIndex"];
				}
			}
		}

		// add new image
		imageObject = [NSEntityDescription insertNewObjectForEntityForName:@"AlbumArt"
													inManagedObjectContext:[self managedObjectContext]];
		[imageObject setValue:[NSNumber numberWithUnsignedInteger:index] forKey:@"imageIndex"];
		[imageObject setValue:[NSNumber numberWithUnsignedInteger:artwork_type] forKey:@"imageType"];
		[imageObject setValue:fileData forKey:@"imageRepresentation"];
		[imageObject setValue:[[filesController selectedObjects] lastObject] forKey:@"mpegFile"];

	}
	if (fileImage)
		[fileImage release];
	fileImage = nil;
}

@end
