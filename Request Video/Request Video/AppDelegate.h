//
//  AppDelegate.h
//  Request Video
//
//  Created by Golden Work on 7/14/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (retain, nonatomic) NSMutableDictionary *user;

@property (readonly, strong) NSPersistentContainer *persistentContainer;

- (void)saveContext;
+ (AppDelegate *)shared;

@end

