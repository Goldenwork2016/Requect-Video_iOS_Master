//
//  MyCustomAnnotation.m
//  Request Video
//
//  Created by NTechnosoft on 25/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import "MyCustomAnnotation.h"

@implementation MyCustomAnnotation

- (id)initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D)location Dictionary:(NSDictionary *)newDict{
    self = [super init];
    if (self) {
        _title = newTitle;
        _coordinate = location;
        _dict = newDict;
    }
    return self;
}

@end
