//
//  FilterValueTypeReader.h
//  tipsi
//
//  Created by Kow Ai Woon on 1/6/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kFilterValueTypeNone = 0,
    kFilterValueTypeVsRetail = 1,
    kFilterValueTypeVsNearBy = 2,
    kFilterValueTypeVsRestSp = 3,
    kFilterValueTypeGlass = 4,
    kFilterValueTypeBottle = 5
} FilterValueTypes;

@interface FilterValueTypeReader : NSObject

+(FilterValueTypeReader*) sharedInstance;
- (NSArray *) getValueTypes;
- (NSDictionary *) getValueTypeWithId:(NSNumber *) valueTypeId;


@end
