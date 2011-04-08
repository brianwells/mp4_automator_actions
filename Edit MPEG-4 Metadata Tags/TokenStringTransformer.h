//
//  TokenStringTransformer.h
//  Edit MPEG-4 Metadata Tags
//
//  Created by Brian Wells on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TokenStringTransformer : NSValueTransformer {
    
}

+ (Class)transformedValueClass;
+ (BOOL)allowsReverseTransformation;
- (id)transformedValue:(id)value;
- (id)reverseTransformedValue:(id)value;

@end
