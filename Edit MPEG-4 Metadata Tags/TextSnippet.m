//
//  TextSnippet.m
//  Edit MPEG-4 Metadata Tags
//
//  Created by Brian Wells on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TextSnippet.h"


@implementation TextSnippet

@synthesize text;

- (id)init {
    self = [super init];
    if (self) {
        self.text = @"";
    }
    return self;
}

@end
