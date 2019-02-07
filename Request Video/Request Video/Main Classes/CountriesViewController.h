//
//  CountriesViewController.h
//  Request Video
//
//  Created by NTechnosoft on 28/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CountriesDelegate <NSObject>
-(void)CountriesViewControllerDismissed:(NSDictionary *)country;
@end

@interface CountriesViewController : UIViewController{
    id Delegate;
}

@property (nonatomic, assign) id<CountriesDelegate> Delegate;

@end
