//
//  TokenStringTransformer.m
//  Edit MPEG-4 Metadata Tags
//
//  Created by Brian Wells on 4/6/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "TokenStringTransformer.h"


@implementation TokenStringTransformer

+ (Class)transformedValueClass {
	return [NSArray class];
}

+ (BOOL)allowsReverseTransformation {
	return YES;
}

- (id)transformedValue:(id)value {
	if ([value isKindOfClass:[NSString class]]) {
		return [NSArray arrayWithObject:value];
	} else {
		return nil;
	}
}

- (id)reverseTransformedValue:(id)value {
	if ([value isKindOfClass:[NSArray class]]) {
        NSMutableString *result = [NSMutableString stringWithCapacity:100];
        [(NSArray *)value enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[NSString class]]) {
                [result appendString:obj];
            } else {
                [result appendFormat:@"%@",[obj description]];
            }
        }];
        return [NSString stringWithString:result];
	} else {
		return nil;
	}	
}

@end
