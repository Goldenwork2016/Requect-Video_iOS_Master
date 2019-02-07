//
//  SearchViewController.h
//  Request Video
//
//  Created by MEHUL on 22/11/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SearchDelegate <NSObject>
-(void)SearchViewControllerDismissed:(NSDictionary *)stream;
@end

@interface SearchViewController : UIViewController{
    id Delegate;
}

@property (nonatomic, assign) id<SearchDelegate> Delegate;

@end
