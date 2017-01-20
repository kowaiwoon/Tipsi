//
//  FilterRankTypeReader.h
//  tipsi
//
//  Created by Kow Ai Woon on 1/6/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kFilterRankTypeNone = 0,
    kFilterRankTypeSommPick = 1,
    kFilterRankTypeForMe = 2,
    kFilterRankTypeProRate = 3,
    kFilterRankTypeConsumerRate = 4,
    kFilterRankTypeVintage = 5,
    kFilterRankTypeRare = 6,
    kFilterRankTypeSaved = 7,
    kFilterRankTypeSommPair = 8
} FilterRankTypes;

@interface FilterRankTypeReader : NSObject

+(FilterRankTypeReader*) sharedInstance;

- (NSArray *) getRankTypes;
- (NSDictionary *) getRankTypeWithId:(NSNumber *) rankTypeId;


@end
