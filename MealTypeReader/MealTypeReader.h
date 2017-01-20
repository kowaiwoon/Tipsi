//
//  MealTypeReader.h
//  WineWiz
//
//  Created by Kow Ai Woon on 3/16/12.
//  Copyright 2012 tipsi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MealTypeReader : NSObject {
    
    NSURLConnection     *urlConnection;
    NSMutableData       *urlData;
}

@property(nonatomic, retain) NSMutableArray         *mealTypes;
@property(nonatomic) BOOL    isRequestLoading;

+(MealTypeReader*)sharedInstance;

-(void)setStaticMealTypes;
-(BOOL)isFoodIdExist:(NSString*)foodId;
-(NSArray*)getMealNames;
-(NSString*)getMealNameAtIndex:(NSInteger)index;
-(NSString*)getMealIDForName:(NSString*)mealName;


-(void) getNormalIcon:(NSInteger)mealIndex andCallback:(void (^)(id result, BOOL bLocal)) callback;
-(void) getHighlightIcon:(NSInteger)mealIndex andCallback:(void (^)(id result, BOOL bLocal)) callback;

@end
