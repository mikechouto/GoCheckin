//
//  ViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import <MapKit/MapKit.h>
#import "ViewController.h"
#import "UIColor+GoCheckin.h"
#import "APIManager.h"
#import "SVPulsingAnnotationView.h"
#import "GoStationDetailView.h"
#import "UserInfoDetailView.h"
#import "MapOption.h" // Uses MapType so must import


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, GoStationDetailViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView * bottomView;
@property (weak, nonatomic) IBOutlet UIButton *detailInfoButton;
@property (strong, nonnull) NSTimer *detailInfoUpdateTimer;
@property (strong, nonatomic) UserInfoDetailView *detailInfoView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSArray *GoStations;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.bottomView setBackgroundColor:[UIColor blueGoCheckinColor]];
    
    [self.mapView setShowsScale:NO];
    [self.mapView setShowsCompass:NO];
    
    [self stopAndResetDetailInfoButtonTitle];
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestLocation];
    
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:23.7 longitude:120.9];
    [self centerMapOnLocation:initialLocation Distance:550000];
    
    // Create the observe before calling update station.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinStationLocation:) name:@"GoStationUpdateFinishNotification" object:nil];
    [[APIManager sharedInstance] updateGoStationIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self prepareCustomNavigationBar];
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAndResetDetailInfoButtonTitle];
}

- (void)centerMapOnLocation:(CLLocation *)location Distance:(CLLocationDistance) regionRadius{
    
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius);
    [_mapView setRegion:coordinateRegion animated:YES];
}

- (IBAction)refreshGoStationData:(id)sender {
    [[APIManager sharedInstance] updateGoStation];
}

- (IBAction)centerMapToUserLocation:(id)sender {
    if (self.userLocation) {
        [self centerMapOnLocation:self.userLocation Distance:5000];
    }
}

- (IBAction)showHideDetailInfoView:(id)sender {
    
    if (self.detailInfoUpdateTimer.isValid) {
        
        [self stopAndResetDetailInfoButtonTitle];
        
        self.detailInfoView = [[UserInfoDetailView alloc] init];
        [self.detailInfoView setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
        [self.view addSubview:self.detailInfoView];
        [UIView animateWithDuration:0.1 animations:^{self.detailInfoView.alpha = 1.0;}];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = @[@0.01f, @1.1f, @0.8f, @1.0f];
        bounceAnimation.keyTimes = @[@0.0f, @0.5f, @0.75f, @1.0f];
        bounceAnimation.duration = 0.5;
        [self.detailInfoView.layer addAnimation:bounceAnimation forKey:@"bounce"];
        
    } else {
        
        if (self.detailInfoView) {
            [self.detailInfoView removeFromSuperview];
            self.detailInfoView = nil;
        }
        
        [self startDetailInfoButtonTimmer];
    }
}

- (void)updateDetailInfoButtonTitle {

    NSUInteger workingCount = [[APIManager sharedInstance] getWorkingGoStationCount];
    NSUInteger closedCount = [[APIManager sharedInstance] getClosedGoStationCount];
    NSUInteger constructingCount = [[APIManager sharedInstance] getConstructingGoStationCount];
    NSUInteger checkedinCount = [[APIManager sharedInstance] getTotalCheckedInCount];
    
    NSString *newTitle;
    NSInteger newTag;
    
    switch (self.detailInfoButton.tag) {
        case 100:
            newTitle = [NSString stringWithFormat:NSLocalizedString(@"Collected: %02.1f", nil), 100.0f * checkedinCount / (workingCount + closedCount)];
            newTag = 101;
            break;
        case 101:
            newTitle = [NSString stringWithFormat:NSLocalizedString(@"Working: %d", nil), workingCount+closedCount];
            newTag = 102;
            break;
        case 102:
            newTitle = [NSString stringWithFormat:NSLocalizedString(@"Building: %d", nil), constructingCount];
            newTag = 103;
            break;
        case 103:
        default:
            newTitle = NSLocalizedString(@"More", nil);
            newTag = 100;
            break;
    }
    
    [self.detailInfoButton setTag:newTag];
    [UIView transitionWithView:self.detailInfoButton.titleLabel duration:1 options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
        [self.detailInfoButton setTitle:newTitle forState:UIControlStateNormal];
    } completion:nil];
}

- (void)startDetailInfoButtonTimmer {
    [self stopAndResetDetailInfoButtonTitle];
    self.detailInfoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(updateDetailInfoButtonTitle) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.detailInfoUpdateTimer forMode:NSRunLoopCommonModes];
}

- (void)stopAndResetDetailInfoButtonTitle {
    
    if (self.detailInfoUpdateTimer) {
        [self.detailInfoUpdateTimer invalidate];
    }
    
    [self.detailInfoButton setTitle:NSLocalizedString(@"More", nil) forState:UIControlStateNormal];
    [self.detailInfoButton setTitle:NSLocalizedString(@"More", nil) forState:UIControlStateHighlighted];
    [self.detailInfoButton setTag:100];
    [self.detailInfoButton setTitleColor:[UIColor blueGoCheckinColor] forState:UIControlStateHighlighted];
}

- (void)prepareCustomNavigationBar {
    
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueGoCheckinColor], NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:21]}];

}

- (void)pinStationLocation:(id)sender {

    // 1. Pin GoStations
    self.GoStations = [[APIManager sharedInstance] getGoStations];
    if (self.mapView.annotations) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    [self.mapView addAnnotations:self.GoStations];
    
    // 2. Begin to rotate detail
    [self startDetailInfoButtonTimmer];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count > 0) {
        self.userLocation = [locations firstObject];
        [self centerMapOnLocation:self.userLocation Distance:5000];
        
        if (!self.mapView.showsUserLocation) {
            [self.mapView setShowsUserLocation:YES];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error finding location: %@", error.localizedDescription);
}

- (UIImage *)imageForAnnotation:(id<MKAnnotation>)annotation {
    
    UIImage *pinImage = [UIImage imageNamed:@"pin_station_constructing"];
    
    if ([annotation isKindOfClass:[GoStationAnnotation class]]) {
        GoStationAnnotation *station = annotation;
        switch (station.status) {
            case GoStationStatusNormal:
                if (station.isCheckIn) {
                    pinImage = [UIImage imageNamed:@"pin_station_checkin_normal"];
                } else {
                    pinImage = [UIImage imageNamed:@"pin_station_normal"];
                }
                break;
            case GoStationStatusClosed:
                if (station.isCheckIn) {
                    pinImage = [UIImage imageNamed:@"pin_station_checkin_closed"];
                } else {
                    pinImage = [UIImage imageNamed:@"pin_station_closed"];
                }
                break;
            case GoStationStatusConstructing:
            case GoStationStatusComingSoon:
            case GoStationStatusUnknown:
                pinImage = [UIImage imageNamed:@"pin_station_constructing"];
                break;
            default:
                break;
        }
    }
    return pinImage;
}

#pragma mark GoStationDetailViewDelegate
- (void)didPressCheckInButttonWithAnnotation:(GoStationAnnotation *)annotation {
    GoStationAnnotation *updatedStation = [[APIManager sharedInstance] updateCheckInDataWithStationUUID:annotation.uuid];
    
    if (updatedStation) {
        [self.mapView removeAnnotation:annotation];
        [self.mapView addAnnotation:updatedStation];
        // TBD: Show or not show annotation view after it's updated
//        [self.mapView selectAnnotation:updatedStation animated:NO];
    }
    
}

- (void)didPressRemoveButttonWithAnnotation:(GoStationAnnotation *)annotation {
    GoStationAnnotation *updatedStation = [[APIManager sharedInstance] removeCheckInDataWithStationUUID:annotation.uuid];
    
    if (updatedStation) {
        [self.mapView removeAnnotation:annotation];
        [self.mapView addAnnotation:updatedStation];
    }
}

- (void)didPressNavigateButtonWithAnnotation:(GoStationAnnotation *)annotation {
    MapType defaultType = [[APIManager sharedInstance] currentDefaultMapApplication];
    
    if (defaultType == MapTypeGoogle) {
        // google map
        NSString* url = [NSString stringWithFormat:@"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f",self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude, annotation.latitude, annotation.longitude];
        [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
    } else {
        // apple map
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(annotation.latitude, annotation.longitude);
        MKPlacemark* placeMark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem* destination =  [[MKMapItem alloc] initWithPlacemark:placeMark];
        [destination setName:annotation.title];
        if([destination respondsToSelector:@selector(openInMapsWithLaunchOptions:)])
        {
            [destination openInMapsWithLaunchOptions:@{MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving}];
            
        }
    }
}

#pragma mark MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    MKAnnotationView *annotationView;
    
    if (annotation == mapView.userLocation)
    {
        // We can return nil to let the MapView handle the default annotation view (blue dot):
        // return nil;
        
        // Or instead, we can create our own blue dot and even configure it:
        static NSString *identifier = @"currentLocation";
        annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[SVPulsingAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
            ((SVPulsingAnnotationView *)annotationView).annotationColor = [UIColor blueGoCheckinColor];
        }
    
    } else {
        
        static NSString* AnnotationIdentifier = @"AnnotationIdentifier";
        
        annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
        
        if(annotationView == nil) {
            
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:AnnotationIdentifier];
        }
        
        annotationView.image = [self imageForAnnotation:annotation];
        
        annotationView.detailCalloutAccessoryView = nil;
        GoStationDetailView *detailView = [[GoStationDetailView alloc] init];
        annotationView.detailCalloutAccessoryView = detailView;
        annotationView.canShowCallout = YES;
        annotationView.centerOffset = CGPointMake(0, -25.0f);
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        annView.alpha = 0;
        [UIView animateWithDuration:0.1 animations:^{annView.alpha = 1.0;}];
        
        CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        bounceAnimation.values = @[@0.01f, @1.1f, @0.8f, @1.0f];
        bounceAnimation.keyTimes = @[@0.0f, @0.5f, @0.75f, @1.0f];
        bounceAnimation.duration = 0.5;
        [annView.layer addAnimation:bounceAnimation forKey:@"bounce"];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounceAnimation.values = @[@0.8f, @1.1f, @0.8f, @1.0f];
    bounceAnimation.keyTimes = @[@0.0f, @0.5f, @0.75f, @1.0f];
    bounceAnimation.duration = 0.5;
    [view.layer addAnimation:bounceAnimation forKey:@"bounce"];
    
    // Center the annotation so that the detailView will not be covered by the title text.
    CGPoint annotationCenter=CGPointMake(view.frame.origin.x + (view.frame.size.width/2),
                                         view.frame.origin.y - (view.frame.size.height/2) - 40);
    
    CLLocationCoordinate2D newCenter=[mapView convertPoint:annotationCenter toCoordinateFromView:view.superview];
    [mapView setCenterCoordinate:newCenter animated:YES];
    
    if ([view.detailCalloutAccessoryView isKindOfClass:[GoStationDetailView class]]) {
        GoStationDetailView *detailView = (GoStationDetailView *)view.detailCalloutAccessoryView;
        detailView.delegate = self;
        [detailView setAnnotation:view.annotation UserLocation:self.userLocation];
        
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([view.detailCalloutAccessoryView isKindOfClass:[GoStationDetailView class]]) {
        GoStationDetailView *detailView = (GoStationDetailView *)view.detailCalloutAccessoryView;
        detailView.delegate = nil;
    }
}

@end
