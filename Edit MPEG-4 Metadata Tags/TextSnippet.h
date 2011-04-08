//
//  TextSnippet.h
//  Edit MPEG-4 Metadata Tags
//
//  Created by Brian Wells on 4/2/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TextSnippet : NSObject {
@private
    NSString *text;
}
@property(copy, readwrite) NSString *text;

@end
