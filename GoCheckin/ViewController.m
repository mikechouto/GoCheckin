//
//  ViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import "SGMapView.h"
#import "ViewController.h"
#import "APIManager.h"
#import "GoUtility.h"

#import "SVPulsingAnnotationView.h"
#import "GoStationDetailView.h"
#import "GoChargerDetailView.h"
#import "UserInfoDetailView.h"
#import "MapOption.h" // Uses MapType so must import

#import "UIColor+GoCheckin.h"

@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, GoStationDetailViewDelegate, GoChargerDetailViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet SGMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIButton *detailInfoButton;

@property (strong, nonatomic) NSTimer *detailInfoTimer;
@property (strong, nonatomic) UserInfoDetailView *detailInfoView;
@property (strong, nonatomic) GoStationDetailView *stationAnnotationView;
@property (strong, nonatomic) GoChargerDetailView *chargerAnnotationView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinEnergyNetworkLocations:) name:@"GoStationUpdateFinishNotification" object:nil];
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
    
    [self.mapView setEnableSingleHandControl:YES];
    
    [self stopAnimatingDetailInfoButton];
    
    // Set the map retion directly so the centerMapOnLocation: doesn't get messed up.
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:23.7 longitude:120.9];
    MKCoordinateRegion coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, 550000, 550000);
    [_mapView setRegion:coordinateRegion animated:YES];
    
    [[APIManager sharedInstance] updateEnergyNetworkIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self prepareCustomNavigationBar];
    [super viewWillAppear:animated];
    
    [self startRequestingUserLocation];
    
    if (self.dataReady) {
        [self pinEnergyNetworkLocations:nil];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Remove timer here instead of dealloc to prevent retain cycle
    [self stopAnimatingDetailInfoButton];
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
    
    if (self.stationAnnotationView) {
        [self.stationAnnotationView setDelegate:nil];
        self.stationAnnotationView = nil;
    }
    
    if (self.chargerAnnotationView) {
        [self.chargerAnnotationView setDelegate:nil];
        self.chargerAnnotationView = nil;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (IBAction)refreshEnergyNetworkData:(id)sender {
    [[APIManager sharedInstance] updateEnergyNetwork];
}

- (IBAction)centerMapToUserLocation:(id)sender {
    
    if (self.userLocation) {
        self.hasCentered = NO;
        [self centerMapOnLocation:self.userLocation Distance:5000];
    }
}

- (IBAction)detailInfoViewStateSwitch:(id)sender {
    
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
        self.detailInfoTimer = nil;
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

- (void)pinEnergyNetworkLocations:(id)sender {
    
    // 1. Update status GoStations
    if (!self.dataReady) {
        self.dataReady = YES;
    }
    
    if (self.mapView.annotations) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    
    // 2-1. Pin GoStations
    [self pinStationsLocation:nil];
    // 2-1. Pin GoChargers
    [self pinChargersLocation:nil];
    
    // 3. Begin to rotate detail
    [self animateDetailInfoButton];
}

- (void)pinStationsLocation:(id)sender {
    NSArray *stations = [[APIManager sharedInstance] getGoStations];
    [self.mapView addAnnotations:stations];
}

- (void)pinChargersLocation:(id)sender {
    NSArray *chargers = [[APIManager sharedInstance] getGoChargers];
    [self.mapView addAnnotations:chargers];
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

#pragma mark GoStationDetailViewDelegate & GoChargerDetailViewDelegate
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

- (void)didPressSupportButttonWithAnnotation:(GoChargerAnnotation *)annotation {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:annotation.homepage]];
}

- (void)didPressNavigateButtonWithAnnotation:(id<MKAnnotation>)annotation {
    MapType defaultType = [[APIManager sharedInstance] currentMapApplication];
    
    if (defaultType == MapTypeGoogle) {
        // google map
        NSString* url = [NSString stringWithFormat:@"comgooglemaps://?saddr=%f,%f&daddr=%f,%f&dirflg=h,t",self.userLocation.coordinate.latitude, self.userLocation.coordinate.longitude, annotation.coordinate.latitude, annotation.coordinate.longitude];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString: url]];
    } else {
        // apple map
        MKPlacemark* placeMark = [[MKPlacemark alloc] initWithCoordinate:annotation.coordinate addressDictionary:nil];
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
        } completion:^(BOOL finished) {
            MKAnnotationView *userAnnotation = [mapView viewForAnnotation:mapView.userLocation];
            [userAnnotation.superview bringSubviewToFront:userAnnotation];
        }];
        [annView.layer addAnimation:self.animationAdd forKey:@"bounce"];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
    
    if (view.annotation == mapView.userLocation) {
        [mapView deselectAnnotation:view.annotation animated:NO];
    } else {
        [view.layer addAnimation:self.animationSelect forKey:@"bounce"];
        // Center the annotation so that the detailView will not be covered by the title text.
        CGPoint annotationCenter = CGPointMake(view.frame.origin.x + (view.frame.size.width/2),
                                             view.frame.origin.y - (view.frame.size.height/2) - 40);
        
        CLLocationCoordinate2D newCenter = [mapView convertPoint:annotationCenter toCoordinateFromView:view.superview];
        [mapView setCenterCoordinate:newCenter animated:YES];
        
        if ([view.annotation isKindOfClass:[GoStationAnnotation class]]) {
            if (!self.stationAnnotationView) {
                self.stationAnnotationView = [[GoStationDetailView alloc] init];
                self.stationAnnotationView.delegate = self;
            }
            
            [self.stationAnnotationView setAnnotation:view.annotation UserLocation:self.userLocation];
            view.detailCalloutAccessoryView = self.stationAnnotationView;
            
        } else if ([view.annotation isKindOfClass:[GoChargerAnnotation class]]) {
            if (!self.chargerAnnotationView) {
                self.chargerAnnotationView = [[GoChargerDetailView alloc] init];
                self.chargerAnnotationView.delegate = self;
            }
            
            [self.chargerAnnotationView setAnnotation:view.annotation UserLocation:self.userLocation];
            view.detailCalloutAccessoryView = self.chargerAnnotationView;
        }
    }
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    MKAnnotationView *userAnnotation = [mapView viewForAnnotation:mapView.userLocation];
    [userAnnotation.superview bringSubviewToFront:userAnnotation];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    MKAnnotationView *userAnnotation = [mapView viewForAnnotation:mapView.userLocation];
    [userAnnotation.superview bringSubviewToFront:userAnnotation];
}

- (UIImage *)imageForAnnotation:(id<MKAnnotation>)annotation {
    
    UIImage *pinImage;
    
    if ([annotation isKindOfClass:[GoStationAnnotation class]]) {
        GoStationAnnotation *station = annotation;
        switch (station.status) {
            case GoStationStatusNormal:
                if (station.isCheckIn) {
                    pinImage = [GoUtility normalCheckinImage];
                } else {
                    pinImage = [GoUtility normalImage];
                }
                break;
            case GoStationStatusClosed:
                if (station.isCheckIn) {
                    pinImage = [GoUtility closedCheckinImage];
                } else {
                    pinImage = [GoUtility closedImage];
                }
                break;
            case GoStationStatusDeprecated:
                if (station.isCheckIn) {
                    pinImage = [GoUtility deprecatedCheckinImage];
                } else {
                    pinImage = [GoUtility deprecatedImage];
                }
                break;
            case GoStationStatusConstructing:
            case GoStationStatusPreparing:
            case GoStationStatusUnknown:
            default:
                pinImage = [GoUtility constructingImage];
                break;
        }
    } else if ([annotation isKindOfClass:[GoChargerAnnotation class]]) {
        pinImage = [GoUtility chargerImage];
    }
    
    return pinImage;
}

#pragma mark - Touches handeling
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (self.detailInfoView) {
        [self detailInfoViewStateSwitch:nil];
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
