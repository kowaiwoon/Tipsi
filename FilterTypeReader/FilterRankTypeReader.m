//
//  FilterRankTypeReader.m
//  tipsi
//
//  Created by Kow Ai Woon on 1/6/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import "FilterRankTypeReader.h"

@implementation FilterRankTypeReader {
    NSArray * filterRankTypes;
}

static FilterRankTypeReader   *singletonInstance;

+(FilterRankTypeReader*)sharedInstance {
    
    @synchronized ([FilterRankTypeReader class]) {
        
        if (!singletonInstance) {
            singletonInstance = [[FilterRankTypeReader alloc] init];
        }
    }
    
    return singletonInstance;
}

- (NSArray *) getRankTypes {
    if (filterRankTypes == nil) {
        filterRankTypes = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RankTypes" ofType:@"plist"]];
    }
    
    return filterRankTypes;
}

- (NSDictionary *) getRankTypeWithId:(NSNumber *) rankTypeId {
    if (filterRankTypes == nil) {
        filterRankTypes = [self getRankTypes];
    }
    for(int i = 0; i < [filterRankTypes count]; i++) {
        NSDictionary * rank = [filterRankTypes objectAtIndex:i];
        if ([[rank objectForKey:@"id"] isEqualToNumber:rankTypeId]){
            return rank;
        }
    }
    
    return nil;
}



@end
