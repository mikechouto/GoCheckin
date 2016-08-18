//
//  ViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import <MapKit/MapKit.h>
#import "ViewController.h"
#import "MKMapView+GoCheckin.h"
#import "APIManager.h"

#import "SVPulsingAnnotationView.h"
#import "GoStationDetailView.h"
#import "UserInfoDetailView.h"
#import "MapOption.h" // Uses MapType so must import

#import "UIColor+GoCheckin.h"

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, GoStationDetailViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView * bottomView;
@property (weak, nonatomic) IBOutlet UIButton *detailInfoButton;

@property (strong, nonnull) NSTimer *detailInfoTimer;
@property (strong, nonatomic) UserInfoDetailView *detailInfoView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSArray *GoStations;

@property (nonatomic, assign) BOOL hasCentered;
@property (nonatomic, assign) BOOL dataReady;

@property (nonatomic, strong) CAKeyframeAnimation *animationAdd;
@property (nonatomic, strong) CAKeyframeAnimation *animationSelect;

@end

@implementation ViewController

- (void)awakeFromNib {
    [super awakeFromNib];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    // Create the observe before calling update station.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinStationLocation:) name:@"GoStationUpdateFinishNotification" object:nil];
    self.dataReady = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.bottomView setBackgroundColor:[UIColor blueGoCheckinColor]];
    
    // Added to check if device is below iOS9
    if ([self.mapView respondsToSelector:@selector(setShowsScale:)]) {
        [self.mapView setShowsScale:NO];
        [self.mapView setShowsCompass:NO];
    }
    
    [self.mapView setSingleHandControlEnable:YES];
    
    [self stopAnimatingDetailInfoButton];
    
    // Set the map retion directly so the centerMapOnLocation: doesn't get messed up.
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:23.7 longitude:120.9];
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 550000, 550000);
    [_mapView setRegion:coordinateRegion animated:YES];
    
    [[APIManager sharedInstance] updateGoStationIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self prepareCustomNavigationBar];
    [super viewWillAppear:animated];
    
    [self startRequestingUserLocation];
    
    if (self.dataReady) {
        [self pinStationLocation:nil];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    if (self.locationManager) {
        [self.locationManager setDelegate:nil];
        self.locationManager = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopAnimatingDetailInfoButton];
}

#pragma mark - Private Functions
- (void)appWillResignActive:(id)sender {
    [self stopRequestingUserLocation];
}

- (void)appWillEnterForeground:(id)sender {
    [self startRequestingUserLocation];
}

- (void)prepareCustomNavigationBar {
    
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueGoCheckinColor], NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:21]}];
}

- (IBAction)refreshGoStationData:(id)sender {
    [[APIManager sharedInstance] updateGoStation];
}

- (IBAction)centerMapToUserLocation:(id)sender {
    
    if (self.userLocation) {
        self.hasCentered = NO;
        [self centerMapOnLocation:self.userLocation Distance:5000];
    }
}

- (IBAction)showHideDetailInfoView:(id)sender {
    
    if (self.detailInfoTimer.isValid) {
        
        [self stopAnimatingDetailInfoButton];
        
        self.detailInfoView = [[UserInfoDetailView alloc] init];
        [self.detailInfoView setCenter:CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height / 2)];
        [self.view addSubview:self.detailInfoView];
        
        // Use getter to get animationAdd due to override getter at end.
        [self.detailInfoView.layer addAnimation:self.animationAdd forKey:@"bounce"];
        
    } else {
        
        if (self.detailInfoView) {
            [self.detailInfoView removeFromSuperview];
            self.detailInfoView = nil;
        }
        
        [self animateDetailInfoButton];
    }
}

#pragma mark - Deatil Info Button
- (void)animateDetailInfoButton {
    [self stopAnimatingDetailInfoButton];
    self.detailInfoTimer = [NSTimer scheduledTimerWithTimeInterval:2.5 target:self selector:@selector(updateDetailInfoButtonTitle) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.detailInfoTimer forMode:NSRunLoopCommonModes];
}

- (void)updateDetailInfoButtonTitle {

    NSUInteger workingCount = [[APIManager sharedInstance] getWorkingGoStationCount];
    NSUInteger closedCount = [[APIManager sharedInstance] getClosedGoStationCount];
    NSUInteger constructingCount = [[APIManager sharedInstance] getConstructingGoStationCount];
    NSUInteger checkedinCount = [[APIManager sharedInstance] getTotalCheckedInCount];
    
    NSString *newTitle;
    NSInteger newTag;
    double accomplishPercentage = 100.0f * checkedinCount / (workingCount + closedCount);
    
    switch (self.detailInfoButton.tag) {
        case 100:
            newTitle = [NSString stringWithFormat:NSLocalizedString(@"Collected: %02.1f", nil), accomplishPercentage < 100.0 ? accomplishPercentage : 100.0];
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

- (void)stopAnimatingDetailInfoButton {
    
    if (self.detailInfoTimer) {
        [self.detailInfoTimer invalidate];
    }
    
    [self.detailInfoButton setTitle:NSLocalizedString(@"More", nil) forState:UIControlStateNormal];
    [self.detailInfoButton setTitle:NSLocalizedString(@"More", nil) forState:UIControlStateHighlighted];
    [self.detailInfoButton setTag:100];
    [self.detailInfoButton setTitleColor:[UIColor blueGoCheckinColor] forState:UIControlStateHighlighted];
}

#pragma mark - Map & Location Functions
- (void)startRequestingUserLocation {
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        [self.locationManager setDelegate:self];
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    }
    [self.locationManager startUpdatingLocation];
}

- (void)stopRequestingUserLocation {
    if (self.locationManager) {
        [self.locationManager stopUpdatingLocation];
    }
}

- (void)centerMapOnLocation:(CLLocation *)location Distance:(CLLocationDistance) regionRadius{
    
    if (!self.hasCentered) {
        
        MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius);
        [_mapView setRegion:coordinateRegion animated:YES];
        
        self.hasCentered = YES;
    }
}

- (void)pinStationLocation:(id)sender {
    
    // 1. Update status GoStations
    if (!self.dataReady) {
        self.dataReady = YES;
    }

    // 2. Pin GoStations
    self.GoStations = [[APIManager sharedInstance] getGoStations];
    if (self.mapView.annotations) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    [self.mapView addAnnotations:self.GoStations];
    
    // 3. Begin to rotate detail
    [self animateDetailInfoButton];
}

#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
            [manager requestWhenInUseAuthorization];
            break;
        case kCLAuthorizationStatusAuthorizedWhenInUse:
            [manager startUpdatingLocation];
            break;
        default:
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    if (locations.count > 0) {
        
        CLLocationDistance distanceThreshold = 500; //Meter
        if (!self.userLocation || [self.userLocation distanceFromLocation:[locations firstObject]] > distanceThreshold) {
            
            self.userLocation = [locations firstObject];
            [self centerMapOnLocation:self.userLocation Distance:5000];
        }

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
            case GoStationStatusDeprecated:
                if (station.isCheckIn) {
                    pinImage = [UIImage imageNamed:@"pin_station_checkin_retired"];
                } else {
                    pinImage = [UIImage imageNamed:@"pin_station_retired"];
                }
                break;
            case GoStationStatusConstructing:
            case GoStationStatusPreparing:
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
    MapType defaultType = [[APIManager sharedInstance] currentMapApplication];
    
    if (defaultType == MapTypeGoogle) {
        // google map
        NSString* url = [NSString stringWithFormat:@"comgooglemaps://?saddr=%f,%f&daddr=%f,%f",self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude, annotation.latitude, annotation.longitude];
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
            annotationView.detailCalloutAccessoryView = nil;
            GoStationDetailView *detailView = [[GoStationDetailView alloc] init];
            annotationView.detailCalloutAccessoryView = detailView;
            
            annotationView.canShowCallout = YES;
            annotationView.centerOffset = CGPointMake(0, -25.0f);
        }
        
        annotationView.image = [self imageForAnnotation:annotation];
    }
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)annotationViews
{
    for (MKAnnotationView *annView in annotationViews)
    {
        annView.alpha = 0;
        [UIView animateWithDuration:0.1 animations:^{
            annView.alpha = 1.0;
        }];
        [annView.layer addAnimation:self.animationAdd forKey:@"bounce"];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    [view.layer addAnimation:self.animationSelect forKey:@"bounce"];
    // Center the annotation so that the detailView will not be covered by the title text.
    CGPoint annotationCenter=CGPointMake(view.frame.origin.x + (view.frame.size.width/2),
                                         view.frame.origin.y - (view.frame.size.height/2) - 40);
    
    CLLocationCoordinate2D newCenter = [mapView convertPoint:annotationCenter toCoordinateFromView:view.superview];
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

#pragma mark - Touches handeling
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.detailInfoView) {
        [self showHideDetailInfoView:nil];
    }
}

- (CAKeyframeAnimation *)animationAdd {
    
    // Override bounceAnimation setter
    if (!_animationAdd) {
        _animationAdd = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        _animationAdd.values = @[@0.01f, @1.1f, @0.8f, @1.0f];
        _animationAdd.keyTimes = @[@0.0f, @0.5f, @0.75f, @1.0f];
        _animationAdd.duration = 0.5;
    }
    return _animationAdd;
}

- (CAKeyframeAnimation *)animationSelect {
    // Override animationSelect setter
    if (!_animationSelect) {
        _animationSelect = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
        _animationSelect.values = @[@0.8f, @1.1f, @0.8f, @1.0f];
        _animationSelect.keyTimes = @[@0.0f, @0.5f, @0.75f, @1.0f];
        _animationSelect.duration = 0.5;
    }
    return _animationSelect;
    
}

@end
