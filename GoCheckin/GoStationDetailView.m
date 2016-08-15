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

// Only exists when ios8
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkinButtonSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *checkinButtonLeftX;

@end

@implementation GoStationDetailView

- (instancetype)init {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
        self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"GoStationDetailView_iOS8" owner:self options:nil] lastObject];
    } else {
        self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"GoStationDetailView" owner:self options:nil] lastObject];
    }
    
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
        
        [self.addressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Address: %@", nil), annotation.subtitle]];
        
        if (self.eta != -1) {
            [self.etaLabel setText:[NSString stringWithFormat:NSLocalizedString(@"About: %lli min", nil), self.eta/60]];
        } else {
            [self.etaLabel setText:@""];
        }
        
        [self.availableTimeLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Opens: %@", nil), annotation.availableTime]];
        
        switch (annotation.status) {
            case GoStationStatusNormal:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_open"]];
                break;
            case GoStationStatusClosed:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_closed"]];
                break;
            case GoStationStatusDeprecated:
            case GoStationStatusConstructing:
            case GoStationStatusPreparing:
                [self.availableStatusImageView setImage:[UIImage imageNamed:@"icon_status_unavailable"]];
                break;
            default:
                self.availableStatusImageView = nil;
                break;
        }
        
        NSString *checkInDate = [NSString stringWithFormat:NSLocalizedString(@"Collected at: %@", nil), @""];
        NSString *checkInTimes= [NSString stringWithFormat:NSLocalizedString(@"Times collected: %lu", nil), 0];
        if (annotation.isCheckIn) {
            checkInDate = [NSString stringWithFormat:NSLocalizedString(@"Collected at: %@", nil), annotation.lastCheckInDate];
            checkInTimes = [NSString stringWithFormat:NSLocalizedString(@"Times collected: %lu", nil), (unsigned long)annotation.checkInTimes];
        }
        
        [self.lastCheckInDateLabel setText:checkInDate];
        [self.checkInTimesLabel setText:checkInTimes];
        
        [self prepareCheckInButtonWithAnnotation:self.annotation];
    }
    
}

- (void)updateEtaLabelWithEta:(long long)eta {
    if (eta != -1) {
        [self.etaLabel setText:[NSString stringWithFormat:NSLocalizedString(@"About: %lli min", nil), eta/60]];
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
    [self.delegate didPressNavigateButtonWithAnnotation:self.annotation];
}

- (void)didMoveToSuperview {
    
    float width = 210;
    CGSize availableTimeSize = [self.availableTimeLabel.text boundingRectWithSize:CGSizeMake(136, 17) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0]} context:nil].size;
    CGFloat perferredWidth = availableTimeSize.width + self.availableStatusImageView.frame.size.width + 5;
    width = perferredWidth > width ? perferredWidth : width;
    
    float height = 220;
    
    if (self.annotation) {
        UIFont *titleFont = [UIFont systemFontOfSize:17.0f];
        CGSize titleSize = [self.annotation.title boundingRectWithSize:CGSizeMake(300, 21) options:NSStringDrawingTruncatesLastVisibleLine attributes:@{NSFontAttributeName:titleFont} context:nil].size;
        
        width = titleSize.width > width ? titleSize.width : width;
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
    
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_unavailable"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateDisabled];
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_checkin"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
    [self.checkInBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_checkin_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateHighlighted];
    [self.checkInBtn setTitleColor:[UIColor greenGoCheckinColor] forState:UIControlStateHighlighted];
    [self.checkInBtn setTitle:@"UNAVAILABLE" forState:UIControlStateDisabled];
    
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_unavailable"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateDisabled];
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_remove"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
    [self.removeBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_remove_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateHighlighted];
    [self.removeBtn setTitleColor:[UIColor redGoCheckinColor] forState:UIControlStateHighlighted];
    
    [self.checkInBtn setEnabled:NO];
    [self.removeBtn setEnabled:NO];
    
    if (annotation) {
        
        [self.removeBtn setHidden:YES];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
            self.checkinButtonSpace.priority = 500;
            self.checkinButtonLeftX.priority = 999;
        }
        
        if (annotation.status == GoStationStatusNormal || annotation.status == GoStationStatusClosed) {
            [self.checkInBtn setEnabled:YES];
            
            if (annotation.isCheckIn && annotation.checkInTimes > 0) {
                [self.removeBtn setHidden:NO];
                [self.removeBtn setEnabled:YES];
                if ([[[UIDevice currentDevice] systemVersion] floatValue] < 9.0) {
                    self.checkinButtonSpace.priority = 999;
                    self.checkinButtonLeftX.priority = 500;
                }
            }
        }
    }
    
}

@end
