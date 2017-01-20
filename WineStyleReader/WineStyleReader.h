//
//  WineStyleReader.h
//  WineWiz
//
//  Created by Kow Ai Woon on 3/16/12.
//  Copyright 2012 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WineStyleDelegate <NSObject>

-(void)wineStyleListSuccessful:(NSArray*)wineStyleList;
-(void)wineStyleListFailed:(NSString*)error;

@end

@interface WineStyleReader : NSObject {
    
    NSURLConnection     *urlConnection;
    NSMutableData       *urlData;
}

@property(nonatomic, retain) NSMutableArray             *wineStyles;
@property(nonatomic, assign) id<WineStyleDelegate>      delegate;
@property(nonatomic) BOOL    isRequestLoading;

+(WineStyleReader*)sharedInstance;

-(void)requestWineStyles:(id<WineStyleDelegate>)wineDelegate;
-(void)parseData:(NSString*)responseString;
-(void)stripSlashes;
-(void)setStaticWineStyles;
-(NSArray*)getWineStyleNames;
-(NSString*)getWineStyleNameAtIndex:(int)index;
-(NSString*)getWineStyleNameWithId:(NSObject*)wineStyleId;
-(NSString*)getWineStyleIDForName:(NSString*)wineStyleName;

@end
