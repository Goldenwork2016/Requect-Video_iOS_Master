//
//  MyVideoCell.h
//  Request Video
//
//  Created by NTechnosoft on 26/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyVideoCell : UITableViewCell
@property (nonatomic, weak)IBOutlet UILabel *name, *time;
@property (nonatomic, weak)IBOutlet UIImageView *videoThumb;
@property (nonatomic, weak)IBOutlet UIButton *report;
@end
