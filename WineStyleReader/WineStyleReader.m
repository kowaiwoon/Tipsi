//
//  WineStyleReader.m
//  WineWiz
//
//  Created by Kow Ai Woon on 3/16/12.
//  Copyright 2012 tipsi. All rights reserved.
//

#import "WineStyleReader.h"
#import "JSON.h"
#import "AppConstants.h"

@implementation WineStyleReader

@synthesize wineStyles;
@synthesize delegate;
@synthesize isRequestLoading;

static WineStyleReader   *singletonInstance;

+(WineStyleReader*)sharedInstance {
    
    @synchronized ([WineStyleReader class]) {
        
        if (!singletonInstance) {
            singletonInstance = [[WineStyleReader alloc] init];
        }
    }
    
    return singletonInstance;
}

+(id)alloc {
    
    @synchronized([WineStyleReader class])
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
        wineStyles = [[NSMutableArray alloc] init];
        [self setStaticWineStyles];
    }
    
    return self;
}

#pragma mark - Logical Methods

-(void)setStaticWineStyles {
    
    [wineStyles removeAllObjects];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"WineStyles" ofType:@"plist"]];
    
    [wineStyles addObjectsFromArray:[NSArray arrayWithArray:[dictionary objectForKey:@"Wines"]]];
    
}

-(NSArray*)getWineStyleNames {
    
    NSMutableArray *wineStyleNames = [NSMutableArray array];
    for (int i=0; i<[wineStyles count]; i++) {
        [wineStyleNames addObject:[[wineStyles objectAtIndex:i] objectForKey:@"wineStyleName"] ];
    }
    
    return wineStyleNames;
}

-(NSString*)getWineStyleNameAtIndex:(int)index {
    
    NSString *wineStyleName = @"All Wines";
    if (index >= 0 && index < [wineStyles count]) {
        wineStyleName = [NSString stringWithFormat:@"%@",[[wineStyles objectAtIndex:index] objectForKey:@"wineStyleName"]];
    }
    
    return wineStyleName;
}

-(NSString*)getWineStyleIDForName:(NSString*)wineStyleName {
    
    NSString *wineStyleID = @"0";
    
    for (int i=0; i<[wineStyles count]; i++) {
        NSString *tempStr = [[wineStyles objectAtIndex:i] objectForKey:@"wineStyleName"];
        if ([tempStr caseInsensitiveCompare:wineStyleName] == NSOrderedSame) {
            wineStyleID = [NSString stringWithFormat:@"%@",[[wineStyles objectAtIndex:i] objectForKey:@"wineStyleId"]];
            break;
        }
    }
    
    return wineStyleID;
}

-(NSString*)getWineStyleNameWithId:(NSObject*)styleIdObj {
    NSString * styleID = [NSString stringWithFormat:@"%@", styleIdObj];
    
    for (int i=0; i<[wineStyles count]; i++) {
        NSString *tempWineStyle = [[wineStyles objectAtIndex:i] objectForKey:@"wineStyleId"];
        if ([tempWineStyle caseInsensitiveCompare:styleID] == NSOrderedSame) {
            return [NSString stringWithFormat:@"%@",[[wineStyles objectAtIndex:i] objectForKey:@"wineStyleName"]];
        }
    }
    return nil;
}

-(void)stripSlashes {
    
    for (int i=0; i<[wineStyles count]; i++) {
        NSString *wineName = [[wineStyles objectAtIndex:i] objectForKey:@"wineStyleName"];
        wineName = [wineName stringByTrimmingCharactersInSet:
                    [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSDictionary *dictionary = @{@"wineStyleId" : wineStyles[i][@"wineStyleId"],
                                     @"wineStyleName" : wineName};
        [wineStyles replaceObjectAtIndex:i withObject:dictionary];
    }
    
    NSDictionary *dictionary = @{@"wineStyleId" : @"0",
                                 @"wineStyleName" : @"All Wines"};
    [wineStyles insertObject:dictionary atIndex:0];
}

#pragma mark - API Request/Response

-(void)requestWineStyles:(id<WineStyleDelegate>)wineDelegate {
    
    isRequestLoading = YES;
    self.delegate = wineDelegate;
    [urlData setLength:0];
    NSString *urlString = [NSString stringWithFormat:@"%@wine/get_winestyle", TIPSI_API];
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"GET"];
    if (urlConnection) {
        [urlConnection cancel];

        urlConnection = nil;
    }
    urlConnection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:YES];
}

-(void)parseData:(NSString *)responseString {
    
    SBJSON *parser = [[SBJSON alloc] init];
	NSDictionary *data = [parser objectWithString:responseString error:nil];
    if ([data objectForKey:@"data"] && (NSNull*)[data objectForKey:@"data"] != [NSNull null] && [[data objectForKey:@"data"] isKindOfClass:[NSArray class]]) {
        [wineStyles removeAllObjects];
        [wineStyles addObjectsFromArray:[data objectForKey:@"data"]];
        [self stripSlashes];
        if (delegate && [delegate respondsToSelector:@selector(wineStyleListSuccessful:)]) {
            [delegate wineStyleListSuccessful:[self getWineStyleNames]];
            delegate = nil;
        }
    }
    else {
        if (delegate && [delegate respondsToSelector:@selector(wineStyleListFailed:)]) {
            [delegate wineStyleListFailed:@"Unable to connect to server, Check your internet connection and try again."];
            delegate = nil;
        }
    }

    isRequestLoading = NO;
}

#pragma mark - NSURLConnectionDelegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [urlData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (delegate && [delegate respondsToSelector:@selector(wineStyleListFailed:)]) {
        [delegate wineStyleListFailed:@"Unable to connect to server, check your internet connection and try again."];
        delegate = nil;
    }
    isRequestLoading = NO;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSString *json_string = [[NSString alloc] initWithData:urlData encoding:NSASCIIStringEncoding];
	TipsiLog(@"hello i m here%@",json_string);
    [self parseData:json_string];
}

@end
