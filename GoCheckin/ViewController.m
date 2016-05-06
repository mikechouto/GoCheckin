//
//  ViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/7/16.
//
//

#import "ViewController.h"
#import <MapKit/MapKit.h>
#import "APIManager.h"
#import "SVPulsingAnnotationView.h"
#import "GoStationDetailView.h"
#import "UIColor+GoCheckin.h"


@interface ViewController () <MKMapViewDelegate, CLLocationManagerDelegate, GoStationDetailViewDelegate>

@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *openedStationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *closedStationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *constructingStationLabel;
@property (weak, nonatomic) IBOutlet UIView * bottomView;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSArray *GoStations;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //    NSLog(@"%@", [[NSLocale currentLocale] localeIdentifier]);
    //    NSLog(@"%@", [[NSLocale preferredLanguages] objectAtIndex:0]);
    [self.bottomView setBackgroundColor:[UIColor blueGoCheckinColor]];
    
    [self.mapView setShowsScale:NO];
    [self.mapView setShowsCompass:NO];
    
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager requestLocation];
    
    CLLocation *initialLocation = [[CLLocation alloc] initWithLatitude:23.7 longitude:120.9];
    [self centerMapOnLocation:initialLocation Distance:550000];
    
    // Create the observe before calling update station.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pinStationLocation:) name:@"GoStationUpdateFinishNotification" object:nil];
    
    [[APIManager sharedInstance] updateGoStationIfNeeded ];
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

- (void)prepareCustomNavigationBar {
    
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationBar.shadowImage = [UIImage new];
    self.navigationBar.translucent = YES;
    [self.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor blueGoCheckinColor], NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:21]}];

}

- (void)pinStationLocation:(id)sender {

    self.GoStations = [[APIManager sharedInstance] getGoStations];
    
    NSUInteger openCount = 0, closedCount = 0, constructingCount = 0;
    for (GoStationAnnotation *station in self.GoStations) {
        switch (station.state) {
            case GoStationStateNormal:
                openCount++;
                break;
            case GoStationStateClosed:
                closedCount++;
                break;
            case GoStationStateConstructing:
                constructingCount++;
                break;
            default:
                constructingCount++;
                break;
        }
    }
    
    [self.openedStationsLabel setText:[NSString stringWithFormat:@"%ld", (unsigned long)openCount]];
    [self.closedStationsLabel setText:[NSString stringWithFormat:@"%ld", (unsigned long)closedCount]];
    [self.constructingStationLabel setText:[NSString stringWithFormat:@"%ld", (unsigned long)constructingCount]];
    
    if (self.mapView.annotations) {
        [self.mapView removeAnnotations:self.mapView.annotations];
    }
    [self.mapView addAnnotations:self.GoStations];

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
        switch (station.state) {
            case GoStationStateNormal:
                if (station.isCheckIn) {
                    pinImage = [UIImage imageNamed:@"pin_station_checkin_normal"];
                } else {
                    pinImage = [UIImage imageNamed:@"pin_station_normal"];
                }
                break;
            case GoStationStateClosed:
                if (station.isCheckIn) {
                    pinImage = [UIImage imageNamed:@"pin_station_checkin_closed"];
                } else {
                    pinImage = [UIImage imageNamed:@"pin_station_closed"];
                }
                break;
            case GoStationStateConstructing:
            case GoStationStateUnknown:
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
