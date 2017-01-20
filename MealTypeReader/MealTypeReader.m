//
//  MealTypeReader.m
//  WineWiz
//
//  Created by Kow Ai Woon on 3/16/12.
//  Copyright 2012 tipsi. All rights reserved.
//

#import "MealTypeReader.h"
#import "MealPreparationListObj.h"
#import "MealTypeObject.h"
#import "JSON.h"
#import "AppConstants.h"

#import "TipsiAPI.h"

@implementation MealTypeReader

@synthesize isRequestLoading;

static MealTypeReader   *singletonInstance;

+(MealTypeReader*)sharedInstance {
    
    @synchronized ([MealTypeReader class]) {
        
        if (!singletonInstance) {
            singletonInstance = [[MealTypeReader alloc] init];
        }
    }
    
    return singletonInstance;
}

+(id)alloc {
    
    @synchronized([MealTypeReader class])
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
        self.mealTypes = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark - Logical Methods

- (void) parseMealData:(NSArray*)arr {
    for ( NSDictionary* dic in arr ) {
        MealTypeObject* mealObj = [[MealTypeObject alloc] init];
        [mealObj parseMealInfo:dic isLocal:YES];
        
        if ( ![self isFoodIdExist:mealObj.mealTitle] )
            [self.mealTypes addObject:mealObj];
    }
    
    [[MealPreparationListObj sharedInstance] loadMealPreparationArray:arr];
    [[MealPreparationListObj sharedInstance] loadMealPreparationList];
}

-(void)setStaticMealTypes {
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MealTypes" ofType:@"plist"]];
    NSArray *array = [NSArray arrayWithArray:[dictionary objectForKey:@"Meals"]];
    [self parseMealData:array];
        
    @weakify(self);
    [TipsiAPI  getMealTypes:^(id result, NSError *error) {
        @strongify(self);        
        if (!error) {
            [self.mealTypes removeAllObjects];
            [self parseMealData:result];
        } else {
            [globalInstance parseError:@"meal/fetchall/"
                                params:nil
                            returnData:result];
        }
    }];
}

-(NSArray*)getMealNames {
    
    NSMutableArray *mealNames = [NSMutableArray array];
    for (int i=0; i<[self.mealTypes count]; i++) {
        MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:i];
        [mealNames addObject:mealObj.mealTitle];
    }
    
    return mealNames;
}

-(NSString*)getMealNameAtIndex:(NSInteger)index {
    
    NSString *mealName = @"All Food";
    if (index >= 0 && index < [self.mealTypes count]) {
        MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:index];
        mealName = [NSString stringWithFormat:@"%@",mealObj.mealTitle];
    }
    
    return mealName;
}

-(NSString*)getMealIDForName:(NSString*)mealName {
    
    NSString *mealID = @"0";
    for (int i=0; i<[self.mealTypes count]; i++) {
        MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:i];

        if ([mealObj.mealTitle caseInsensitiveCompare:mealName] == NSOrderedSame) {
            mealID = [NSString stringWithFormat:@"%@",mealObj.mealId];
            break;
        }
    }
    return mealID;
}

-(void)getNormalIcon:(NSInteger)mealIndex andCallback:(void (^)(id result, BOOL bLocal)) callback{
    MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:mealIndex];
    
    if ( mealObj.bFromLocal ) {
        callback (mealObj.mealNormalIconURL, YES);
    }else {
        callback (mealObj.mealNormalIconURL, NO);
    }
}

-(void) getHighlightIcon:(NSInteger)mealIndex andCallback:(void (^)(id result, BOOL bLocal)) callback {
    MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:mealIndex];
    if ( mealObj.bFromLocal ) {
        callback (mealObj.mealHighlightIconURL, YES);
    }else {
        callback (mealObj.mealHighlightIconURL, NO);
    }
}

-(BOOL)isFoodIdExist:(NSString*)foodId {
    
    BOOL flag = NO;
    for (int i=0; i<[self.mealTypes count]; i++) {
        MealTypeObject* mealObj = (MealTypeObject*)[self.mealTypes objectAtIndex:i];
        
        if ([mealObj.mealTitle isEqualToString:foodId]) {
            flag = YES;
            break;
        }
    }
    
    return flag;
}

@end
