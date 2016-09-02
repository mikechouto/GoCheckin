//
//  GoChargerDetailView.m
//  GoCheckin
//
//  Created by Mike Chou on 8/31/16.
//
//

#import "GoChargerDetailView.h"
#import "UIColor+GoCheckin.h"

@interface GoChargerDetailView()

@property (strong, nonatomic) GoChargerAnnotation *annotation;
@property (assign, nonatomic) long long eta;
@property (strong, nonatomic) CLLocation *userLocation;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UILabel *etaLabel;
@property (weak, nonatomic) IBOutlet UITextView *phoneTextView;
@property (weak, nonatomic) IBOutlet UIButton *navigationBtn;
@property (weak, nonatomic) IBOutlet UIButton *supportBtn;

@end

@implementation GoChargerDetailView

- (instancetype)init {
    self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"GoChargerDetailView" owner:self options:nil] lastObject];
    
    if (self) {
        self.eta = -1;
        self.phoneTextView.textContainer.lineFragmentPadding = 0;
        self.phoneTextView.textContainerInset = UIEdgeInsetsZero;
    }
    return self;
}

- (void)dealloc {
    _delegate = nil;
}

- (void)setAnnotation:(GoChargerAnnotation *)annotation UserLocation:(CLLocation *)userLocation {
    self.annotation = annotation;
    self.userLocation = userLocation;
    
    if (self.annotation) {
        if (userLocation) {
            [self calculateETAWithAnnotation:annotation UserLocation:userLocation];
        }
    }
    [self loadViewWithAnnotation:annotation];
}

- (void)loadViewWithAnnotation:(GoChargerAnnotation *)annotation {
    
    if (annotation) {
        
        [self.addressLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Address: %@", nil), annotation.subtitle]];
        
        if (self.eta != -1) {
            [self.etaLabel setText:[NSString stringWithFormat:NSLocalizedString(@"About: %lli min", nil), self.eta/60]];
        } else {
            [self.etaLabel setText:@""];
        }

        [self.phoneTextView setText:[NSString stringWithFormat:NSLocalizedString(@"Phone: %@", nil), annotation.phone]];

        [self.supportBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_checkin"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateNormal];
        [self.supportBtn setBackgroundImage:[[UIImage imageNamed:@"icon_btn_checkin_highlight"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 16, 0, 16)] forState:UIControlStateHighlighted];
        [self.supportBtn setTitle:NSLocalizedString(@"SUPPORT", nil) forState:UIControlStateNormal];
        [self.supportBtn setTitleColor:[UIColor greenGoCheckinColor] forState:UIControlStateHighlighted];
    }
}

- (void)updateEtaLabelWithEta:(long long)eta {
    if (eta != -1) {
        [self.etaLabel setText:[NSString stringWithFormat:NSLocalizedString(@"About: %lli min", nil), eta/60]];
    } else {
        [self.etaLabel setText:@""];
    }
}

- (IBAction)supportBtnPressed:(id)sender {
    [self.delegate didPressSupportButttonWithAnnotation:self.annotation];
}

- (IBAction)navigateToGoStation:(id)sender {
    [self.delegate didPressNavigateButtonWithAnnotation:self.annotation];
}

- (void)didMoveToSuperview {
    
    CGFloat width = 210;
    
    CGFloat height = 170;
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:width]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:height]];
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
}

- (void)calculateETAWithAnnotation:(GoChargerAnnotation *)annotation UserLocation:(CLLocation *)location {
    
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

@end
