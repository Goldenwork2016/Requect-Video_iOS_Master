//
//  MyCustomAnnotation.h
//  Request Video
//
//  Created by NTechnosoft on 25/07/17.
//  Copyright © 2017 GoldenWork Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface MyCustomAnnotation : NSObject<MKAnnotation>
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSDictionary *dict;

- (id)initWithTitle:(NSString *)newTitle Location:(CLLocationCoordinate2D)location Dictionary:(NSDictionary *)newDict;

@end
