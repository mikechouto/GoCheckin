//
//  GoStationDetailView.h
//  GoCheckin
//
//  Created by Mike Chou on 4/22/16.
//
//

#import <UIKit/UIKit.h>
#import "GoStationAnnotation.h"

IB_DESIGNABLE
@protocol GoStationDetailViewDelegate <NSObject>

@required
- (void)didPressCheckInButttonWithAnnotation:(GoStationAnnotation *)annotation;
- (void)didPressRemoveButttonWithAnnotation:(GoStationAnnotation *)annotation;
- (void)didPressNavigateButtonWithAnnotation:(GoStationAnnotation *)annotation;

@end

@interface GoStationDetailView : UIView

@property (weak, nonatomic) id<GoStationDetailViewDelegate> delegate;
- (void)setAnnotation:(GoStationAnnotation *)annotation UserLocation:(CLLocation *)userLocation;

@end
