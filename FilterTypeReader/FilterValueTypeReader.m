//
//  FilterValueTypeReader.m
//  tipsi
//
//  Created by Kow Ai Woon on 1/6/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import "FilterValueTypeReader.h"

@implementation FilterValueTypeReader {
    NSArray * filterValueTypes;
}

static FilterValueTypeReader   *singletonInstance;

+(FilterValueTypeReader*) sharedInstance {
    
    @synchronized ([FilterValueTypeReader class]) {
        
        if (!singletonInstance) {
            singletonInstance = [[FilterValueTypeReader alloc] init];
        }
    }
 
    return singletonInstance;
}

- (NSArray *) getValueTypes {
    if (filterValueTypes == nil) {
        filterValueTypes = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ValueTypes" ofType:@"plist"]];
    }
    
    return filterValueTypes;
}

- (NSDictionary *) getValueTypeWithId:(NSNumber *) valueTypeId {
    if (filterValueTypes == nil) {
        filterValueTypes = [self getValueTypes];
    }
    for(int i = 0; i < [filterValueTypes count]; i++) {
        NSDictionary * valueType = [filterValueTypes objectAtIndex:i];
        if ([[valueType objectForKey:@"id"] isEqualToNumber:valueTypeId]){
            return valueType;
        }
    }
    
    return nil;
}


@end
