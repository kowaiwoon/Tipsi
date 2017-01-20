//
//  ReportIncorrectListReader.h
//  WineWiz
//
//  Created by Kow Ai Woon on 11/25/11.
//  Copyright 2011 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ReportIncorrectListDelegate <NSObject>

-(void)reportIncorrectListSuccessful:(NSString*)message;
-(void)reportIncorrectListFailed:(NSString *)error;

@end

@interface ReportIncorrectListReader : NSObject {
    
    NSURLConnection     *urlConnection;
    NSMutableData       *urlData;
}

@property (nonatomic, assign) id<ReportIncorrectListDelegate>   delegate;

+(ReportIncorrectListReader*)sharedInstance;
-(void)requestReportIncorrectList:(NSString*)foursquareID UserID:(NSString*)userID Reason:(NSString*)reason Delegate:(id<ReportIncorrectListDelegate>)reportDelegate;
-(void)parseData:(NSString*)responseData;

@end
