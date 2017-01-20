//
//  WineListRequestSaver.h
//  tipsi
//
//  Created by Kow Ai Woon on 4/2/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WineListRequestInfo : NSObject

@property(nonatomic, retain) NSDate *requestDate;
@property(nonatomic, retain) NSNumber *requestRestaurantId;

@end


@interface WineListRequestSaver : NSObject

@property(nonatomic, retain) NSMutableArray *wineListRequests;
@property(nonatomic) BOOL isRequestLoading;

+(WineListRequestSaver*) sharedInstance;

- (void) addRequest:(NSDate*) date withRestId:(NSNumber *) restId;
- (NSDate *) getLastRequestTimeForRestaurant:(NSNumber *) restId;
- (NSInteger) getRequestCountForLast30Days;

@end
