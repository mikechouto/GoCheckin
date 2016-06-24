//
//  MKMapView+GoCheckin.h
//  ASMapViewSample
//
//  Created by Mike Chou on 6/23/16.
//  Copyright © 2016 AssembleLabs. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface MKMapView (GoCheckin)

@property (nonatomic, readonly, assign) BOOL isSingleHandControlEnable;

- (void)setSingleHandControlEnable:(BOOL)isEnable;

@end
