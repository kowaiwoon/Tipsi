//
//  ReportIncorrectListReader.m
//  WineWiz
//
//  Created by Kow Ai Woon on 11/25/11.
//  Copyright 2011 tipsi. All rights reserved.
//

#import "ReportIncorrectListReader.h"
#import "AppConstants.h"
#import "JSON.h"
#import "TipsiAPI.h"

@implementation ReportIncorrectListReader

@synthesize delegate;

static ReportIncorrectListReader    *singletonInstance;
+(ReportIncorrectListReader*)sharedInstance {
    @synchronized ( [ReportIncorrectListReader class])
    {
        if (!singletonInstance) {
            singletonInstance = [[ReportIncorrectListReader alloc] init];
        }
    }
    return singletonInstance;
}

+(id)alloc {
    
    @synchronized([ReportIncorrectListReader class])
    {
        NSAssert(singletonInstance == nil, @"Attempting to allocate another instance of singleton class");
        singletonInstance = [super alloc];
    }
    return singletonInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        urlData = [[NSMutableData alloc] init];
    }
    
    return self;
}

#pragma mark - API Request/Response

-(void)requestReportIncorrectList:(NSString*)foursquareID UserID:(NSString*)userID Reason:(NSString*)reason Delegate:(id<ReportIncorrectListDelegate>)reportDelegate {
    self.delegate = reportDelegate;
    [urlData setLength:0];
    //tipsi api call - report wine list error
    TipsiLog(@"user id: %@, reason: %@, fs_id: %@", userID, reason, foursquareID);
    @weakify(self);
    [TipsiAPI  postWineListErrorWithReason:reason andUserId:userID andFoursquareId:foursquareID andCallback:^(id result, NSError *error) {
        @strongify(self);
        if (!error) {
            TipsiLog(@"result: %@", result);
            [self.delegate reportIncorrectListSuccessful:[result objectForKey:@"message"]];
        } else {
            TipsiEventError(@"report Incorrect list", [result valueForKey:@"error_message"], error);
            [globalInstance parseError:@"api/report_incorrect_list/"
                                params:@{@"reason" : reason?:@"nil",
                                         @"user_id" : userID?:@"nil",
                                         @"foursquare_id" : foursquareID?:@"nil"}
                            returnData:result];
        }
    }];    
}

-(void)parseData:(NSString*)responseData {
    SBJSON *parser = [[SBJSON alloc] init];
	NSMutableDictionary *data = [parser objectWithString:responseData error:nil];
    if ((NSNull*)[data objectForKey:@"message"] == [NSNull null]) {
        
        if (delegate && [delegate respondsToSelector:@selector(reportIncorrectListFailed:)]) {
            [delegate reportIncorrectListFailed:@"Unable to connect to server, check your internet connection and try again."];
            delegate = nil;
        }
    }
    else {
        if (delegate && [delegate respondsToSelector:@selector(reportIncorrectListSuccessful:)]) {
            [delegate reportIncorrectListSuccessful:[data objectForKey:@"message"]];
            delegate = nil;
        }
    }
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [urlData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (delegate && [delegate respondsToSelector:@selector(reportIncorrectListFailed:)]) {
        [delegate reportIncorrectListFailed:@"Unable to connect to server, check your internet connection and try again."];
        delegate = nil;
    }    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *json_string = [[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding];
	TipsiLog(@"%@",json_string);
    [self parseData:json_string];
}

@end
