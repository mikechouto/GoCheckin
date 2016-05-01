//
//  GoStationDetailView.m
//  GoCheckin
//
//  Created by Mike Chou on 4/22/16.
//
//

#import "GoStationDetailView.h"
#import <MapKit/MapKit.h>
#import "APIManager.h"
#import "UIColor+GoCheckin.h"

@interface GoStationDetailView()

@property (strong, nonatomic) GoStationAnnotation *annotation;
@property (assign, nonatomic) long long eta;
@property (strong, nonatomic) CLLocation *userLocation;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;
@property (weak, nonatomic) IBOutlet UILabel *availableTimeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *availableStatusImageView;
@property (weak, nonatomic) IBOutlet UILabel *lastCheckInDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkInTimesLabel;
@property (weak, nonatomic) IBOutlet UIButton *navigationBtn;
@property (weak, nonatomic) IBOutlet UIButton *checkInBtn;
@property (weak, nonatomic) IBOutlet UIButton *removeBtn;

@end

@implementation GoStationDetailView

- (instancetype)init {
    self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"GoStationDetailView" owner:self options:nil] lastObject];
    if (self) {
        self.eta = -1;
    }
    return self;
}

- (void)setAnnotation:(GoStationAnnotation *)annotation UserLocation:(CLLocation *)userLocation {
    self.annotation = annotation;
    self.userLocation = userLocation;
    
    if (self.annotation) {
        if (userLocation) {
            [self calculateETAWithAnnotation:annotation UserLocation:userLocation];
        }
    }
    [self loadViewWithAnnotation:annotation];
}

- (void)loadViewWithAnnotation:(GoStationAnnotation *)annotation {
    
    if (annotation) {
        
        [self.addressLabel setText:[NSString stringWithFormat:@"地址: %@", annotation.subtitle]];
        
        if (self.eta != -1) {
            [self.etaLabel setText:[NSString stringWithFormat:@"約: %lli 分鐘 ", self.eta/60]];
        } else {
            [self.etaLabel setText:@""];
        }
        
        [self.availableTimeLabel setText:[NSString stringWithFormat:@"營業時間: %@", annotation.availableTime]];
        
        switch (annotation.state) {
            case GoStationStateNormal:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_open"]];
                break;
            case GoStationStateClosed:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_closed"]];
                break;
            case GoStationStateConstructing:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_unavailable"]];
                break;
            default:
                self.availableStatusImageView = nil;
                break;
        }
        
        if (annotation.isCheckIn) {
            
            [self.lastCheckInDateLabel setText:[NSString stringWithFormat:@"收集時間: %@", annotation.lastCheckInDate]];
            [self.checkInTimesLabel setText:[NSString stringWithFormat:@"收集次數: %lu", (unsigned long)annotation.checkInTimes]];
        }
        
        [self prepareCheckInButtonWithAnnotation:self.annotation];
    }
    
}

- (void)updateEtaLabelWithEta:(long long)eta {
    if (eta != -1) {
        [self.etaLabel setText:[NSString stringWithFormat:@"約: %lli 分鐘 ", eta/60]];
    } else {
        [self.etaLabel setText:@""];
    }
}

- (IBAction)checkInBtnPressed:(id)sender {
    [self.delegate didPressCheckInButttonWithAnnotation:self.annotation];
}

- (IBAction)removeBtnPressed:(id)sender {
    [self.delegate didPressRemoveButttonWithAnnotation:self.annotation];
}

- (IBAction)navigateToGoStation:(id)sender {
    
    // google map
    NSString* url = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f",self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude, self.annotation.latitude, self.annotation.longitude];
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
    /*
    // apple map
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(self.annotation.latitude, self.annotation.longitude);
    MKPlacemark* placeMark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
    MKMapItem* destination =  [[MKMapItem alloc] initWithPlacemark:placeMark];
    [destination setName:self.annotation.title];
    if([destination respondsToSelector:@selector(openInMapsWithLaunchOptions:)])
    {
        [destination openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving}];
        
    }
     */
}

- (void)didMoveToSuperview {
    
    float width = 210;
    float height = 220;
    
    if (self.annotation) {
        UIFont *titleFont = [UIFont systemFontOfSize:17.0f];
        CGSize titleSize = [self.annotation.title boundingRectWithSize:CGSizeMake(300, 21) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:titleFont} context:nil].size;
        width = titleSize.width > 210.0 ? titleSize.width : 210;
        [self.addressLabel setPreferredMaxLayoutWidth:width];
    }
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height]];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
}

- (void)calculateETAWithAnnotation:(GoStationAnnotation *)annotation UserLocation:(CLLocation *)location {
    
    MKPlacemark *userPlacemark = [[MKPlacemark alloc] initWithCoordinate:location.coordinate addressDictionary:nil];
    MKPlacemark *destinationPlacemark = [[MKPlacemark alloc] initWithCoordinate:CLLocationCoordinate2DMake(annotation.latitude, annotation.longitude) addressDictionary:nil];;
    
    MKMapItem *sourceItem = [[MKMapItem alloc] initWithPlacemark:userPlacemark];
    MKMapItem *destinationItem = [[MKMapItem alloc] initWithPlacemark:destinationPlacemark];
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
    request.source = sourceItem;
    request.destination = destinationItem;
    [request setRequestsAlternateRoutes:NO];
    [request setTransportType:MKDirectionsTransportTypeAutomobile];
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateETAWithCompletionHandler:^(MKETAResponse * _Nullable response, NSError * _Nullable error) {
        if (!error) {
            self.eta = response.expectedTravelTime;
            [self updateEtaLabelWithEta:self.eta];
        }
    }];
}

- (void)prepareCheckInButtonWithAnnotation:(GoStationAnnotation *)annotation {
    
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_unavailable_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateDisabled];
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_checkin_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_checkin_highlight_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateHighlighted];
    [self.checkInBtn setTitleColor:[UIColor greenGoCheckinColor] forState:UIControlStateHighlighted];
    [self.checkInBtn setTitle:@"UNAVAILABLE" forState:UIControlStateDisabled];
    
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_unavailable_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateDisabled];
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_remove_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_remove_highlight_btn"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateHighlighted];
    [self.removeBtn setTitleColor:[UIColor redGoCheckinColor] forState:UIControlStateHighlighted];
    
    [self.checkInBtn setEnabled:NO];
    [self.removeBtn setEnabled:NO];
    
    if (annotation) {
        
        if (annotation.state == GoStationStateNormal) {
            [self.checkInBtn setEnabled:YES];
        }
        
        if (annotation.isCheckIn && annotation.checkInTimes > 0) {
            [self.removeBtn setEnabled:YES];
        } else {
            [self.removeBtn removeFromSuperview];
        }
        
        
    }
    
}

@end
