//
//  GoChargerDetailView.h
//  GoCheckin
//
//  Created by Mike Chou on 8/31/16.
//
//

#import <UIKit/UIKit.h>
#import "GoChargerAnnotation.h"

IB_DESIGNABLE
@protocol GoChargerDetailViewDelegate <NSObject>

@required
- (void)didPressSupportButttonWithAnnotation:(GoChargerAnnotation *)annotation;
- (void)didPressNavigateButtonWithAnnotation:(id<MKAnnotation>)annotation;

@end

@interface GoChargerDetailView : UIView

@property (weak, nonatomic) id<GoChargerDetailViewDelegate> delegate;
- (void)setAnnotation:(GoChargerAnnotation *)annotation UserLocation:(CLLocation *)userLocation;

@end
