//
//  WineListRequestSaver.m
//  tipsi
//
//  Created by Kow Ai Woon on 4/2/15.
//  Copyright (c) 2015 tipsi. All rights reserved.
//

#import "WineListRequestSaver.h"
#import "NSObject+ObjectMap.h"


@implementation WineListRequestInfo
@end

@implementation WineListRequestSaver

#define FILE_NAME @"winelistrequest.json"
#define DAYS_LIMIT 30

static WineListRequestSaver   *singletonInstance;

+(WineListRequestSaver*)sharedInstance {
    
    @synchronized ([WineListRequestSaver class]) {
        
        if (!singletonInstance) {
            singletonInstance = [[WineListRequestSaver alloc] init];
            [singletonInstance loadContent];
        }
    }
    
    return singletonInstance;
}


- (void) loadContent {
    NSData * data = [NSData dataWithContentsOfFile:[self getFileName]];
    if (data != nil) {
        self.wineListRequests = [[NSObject arrayOfType:[WineListRequestInfo class] FromJSONData:data] mutableCopy];
        
        [self updateList];
    }
}


- (void) saveContent {
    NSData * data = [self.wineListRequests JSONData];
    [data writeToFile:[self getFileName] atomically:YES];
}

- (void) addRequest:(NSDate*) date withRestId:(NSNumber *) restId {
    if (self.wineListRequests == nil)
        [self loadContent];
    
    if (self.wineListRequests == nil) {
        self.wineListRequests = [[NSMutableArray alloc] init];
    }
    
    WineListRequestInfo * info = [[WineListRequestInfo alloc] init];
    info.requestDate = date;
    info.requestRestaurantId = restId;
    
    [self.wineListRequests addObject:info];
    
    [self saveContent];
}

- (NSDate *) getLastRequestTimeForRestaurant:(NSNumber *) restId {
    for(NSInteger i = [self.wineListRequests count] - 1; i >= 0; i--) {
        WineListRequestInfo * info = [self.wineListRequests objectAtIndex:i];
        if ([info.requestRestaurantId isEqualToNumber:restId]) {
            return info.requestDate;
        }
    }
    return nil;
}

- (void) updateList {
    for(NSInteger i = [self.wineListRequests count] - 1; i >= 0; i--) {
        WineListRequestInfo * info = [self.wineListRequests objectAtIndex:i];
        int days = -[info.requestDate timeIntervalSinceNow] / 24 / 60;
        if (days >= DAYS_LIMIT) {
            [self.wineListRequests removeObjectAtIndex:i];
        }
    }
    
    [self saveContent];
}

- (NSString *) getFileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:FILE_NAME];
    return appFile;
}

- (NSInteger) getRequestCountForLast30Days {
    [self updateList];
    return [self.wineListRequests count];
}

@end
