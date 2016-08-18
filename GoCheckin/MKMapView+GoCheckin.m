//
//  MKMapView+GoCheckin.m
//  ASMapViewSample
//
//  Created by Mike Chou on 6/23/16.
//  Copyright © 2016 AssembleLabs. All rights reserved.
//

#import "MKMapView+GoCheckin.h"
#import <objc/runtime.h>

typedef NS_ENUM(NSInteger, GCIMapViewTouchState) {
    GCIMapViewTouchStateNormal,
    GCIMapViewTouchStateZoomMode
};

dispatch_source_t CreateGestureWatchDog(double interval, dispatch_block_t block)
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    if (timer) {
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (800 * NSEC_PER_MSEC));
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

#pragma mark - MKMapView(GoCheckinPrivate) implementation

@interface MKMapView (GoCheckinPrivate)<UIGestureRecognizerDelegate>

@property (nonatomic, assign) GCIMapViewTouchState zoomTouchState;
@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;
@property (nonatomic, strong) dispatch_source_t gestureWatchdog;

@end

NSString * const kZoomTouchState = @"kZoomTouchState";
NSString * const kTapRecognizer = @"kTapRecognizer";
NSString * const kLongPressRecognizer = @"kLongPressRecognizer";
NSString * const kGestureWatchdog = @"kGestureWatchdog";

@implementation MKMapView (GoCheckinPrivate)

- (void)setGestureWatchdog:(dispatch_source_t)gestureWatchdog {
    objc_setAssociatedObject(self, (__bridge const void*)(kGestureWatchdog), gestureWatchdog, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setTapRecognizer:(UITapGestureRecognizer *)tapRecognizer {
    objc_setAssociatedObject(self, (__bridge const void*)(kTapRecognizer), tapRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setLongPressRecognizer:(UILongPressGestureRecognizer *)longPressRecognizer {
    objc_setAssociatedObject(self, (__bridge const void*)(kLongPressRecognizer), longPressRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setZoomTouchState:(GCIMapViewTouchState)zoomTouchState {
    NSNumber *val = @(zoomTouchState);
    objc_setAssociatedObject(self, (__bridge const void*)(kZoomTouchState), val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_source_t)gestureWatchdog {
    id val = objc_getAssociatedObject(self, (__bridge const void*)kGestureWatchdog);
    return val;
}

- (UITapGestureRecognizer *)tapRecognizer {
    id val = objc_getAssociatedObject(self, (__bridge const void*)kTapRecognizer);
    return val;
}

- (UILongPressGestureRecognizer *)longPressRecognizer {
    id val = objc_getAssociatedObject(self, (__bridge const void*)kLongPressRecognizer);
    return val;
}

- (GCIMapViewTouchState)zoomTouchState {
    
    id val = objc_getAssociatedObject(self, (__bridge const void*)kZoomTouchState);
    
    if ([val isKindOfClass:[NSNumber class]]) {
        return [val integerValue];
    } else {
        return GCIMapViewTouchStateNormal;
    }
}

@end

#pragma mark - MKMapView(GoCheckin) implementation
NSString * const kIsSingleHandControlEnable = @"kIsSingleHandControlEnable";

@implementation MKMapView (GoCheckin)

- (void)setIsSingleHandControlEnable:(BOOL)isSingleHandControlEnable {
    NSNumber *val = @(isSingleHandControlEnable);
    objc_setAssociatedObject(self, (__bridge const void*)(kIsSingleHandControlEnable), val, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isSingleHandControlEnable {
    id val = objc_getAssociatedObject(self, (__bridge const void*)kIsSingleHandControlEnable);
    
    if ([val isKindOfClass:[NSNumber class]]) {
        return [val boolValue];
    } else {
        return NO;
    }
}

- (void)setSingleHandControlEnable:(BOOL)isEnable {
    
    self.isSingleHandControlEnable = isEnable;
    
    if (self.isSingleHandControlEnable) {
        self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        self.tapRecognizer.numberOfTapsRequired = 1;
        self.tapRecognizer.cancelsTouchesInView = NO; // Make sure to pass the touch even if the recognizer has already recongizerd the touch.
        self.tapRecognizer.delegate = self;
        [self addGestureRecognizer:self.tapRecognizer];
        
        self.longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        self.longPressRecognizer.minimumPressDuration = 0.01;
        self.longPressRecognizer.cancelsTouchesInView = NO;
        self.longPressRecognizer.delegate = self;
        
    } else {
        
        if (self.tapRecognizer) {
            [self removeGestureRecognizer:self.tapRecognizer];
            self.tapRecognizer.delegate = nil;
            self.tapRecognizer = nil;
        }
        
        if (self.longPressRecognizer) {
            [self removeGestureRecognizer:self.longPressRecognizer];
            self.longPressRecognizer.delegate = nil;
            self.longPressRecognizer = nil;
        }
    }
}

- (void)resetGestureRecognizers {
    [self removeGestureRecognizer:self.longPressRecognizer];
    [self setZoomTouchState:GCIMapViewTouchStateNormal];
}

#pragma mark - Handle Touches
- (void)handleGesture:(id)sender {
    if (![sender isKindOfClass:[UIGestureRecognizer class]]) {
        return;
    }
    
    UIGestureRecognizer *recognizer = sender;
    
    if (recognizer == self.tapRecognizer) {
        
        double timeoutInterval = 0.200f;
        self.gestureWatchdog = CreateGestureWatchDog(timeoutInterval, ^{
            dispatch_source_cancel(self.gestureWatchdog);
            [self resetGestureRecognizers];
        });
        
        [self addGestureRecognizer:self.longPressRecognizer];
    }
    
    if (recognizer == self.longPressRecognizer) {
        
        switch (recognizer.state) {
            case UIGestureRecognizerStateBegan:
                
                if (self.gestureWatchdog) {
                    dispatch_source_cancel(self.gestureWatchdog);
                    self.gestureWatchdog = nil;
                }
                
                if (self.zoomTouchState == GCIMapViewTouchStateNormal) {
                    [self setZoomTouchState:GCIMapViewTouchStateZoomMode];
                }
                
                break;
            
            case UIGestureRecognizerStateEnded:
                [self resetGestureRecognizers];
                break;
                
            default:
                break;
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if ([touches count] > 0 && self.zoomTouchState == GCIMapViewTouchStateZoomMode) {
        UITouch* touch = [[touches allObjects] firstObject];
        CGPoint prevLocation = [touch previousLocationInView:self];
        CGPoint newLocation = [touch locationInView:self];
        CGFloat deltaYPoint = newLocation.y - prevLocation.y;
        
        if (deltaYPoint < 0) {
            [self zoomOutWithDelta:deltaYPoint];
        }
        else {
            [self zoomInWithDelta:deltaYPoint];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

/*
 * Returns yes to make sure the touches gets passed through so the 
 * original gesture won't fail to function.
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark - Zoom controls

- (void)zoomInWithDelta:(CGFloat)delta {
    [self applyZoom:YES delta:delta];
}

- (void)zoomOutWithDelta:(CGFloat)delta {
    [self applyZoom:NO delta:delta];
}

- (void)applyZoom:(BOOL)isZoom delta:(CGFloat)delta {
    CGFloat currentWidth = [self bounds].size.width;
    CGFloat currentHeight = [self bounds].size.height;
    
    MKCoordinateRegion currentRegion = [self region];
    double latitudePerPoint = currentRegion.span.latitudeDelta / currentWidth;
    double longitudePerPoint = currentRegion.span.longitudeDelta / currentHeight;
    
    //zoom factor is calculated by the movement of the touch at each level
    double zoomFactor = fabs(delta)/100.0 + 1.0;
    
    double newLatitudePerPoint;
    double newLongitudePerPoint;
    
    if (isZoom) {
        newLatitudePerPoint = latitudePerPoint / zoomFactor;
        newLongitudePerPoint = longitudePerPoint / zoomFactor;
    } else {
        newLatitudePerPoint = latitudePerPoint * zoomFactor;
        newLongitudePerPoint = longitudePerPoint * zoomFactor;
    }
    
    CLLocationDegrees newLatitudeDelta = newLatitudePerPoint * currentWidth;
    CLLocationDegrees newLongitudeDelta = newLongitudePerPoint * currentHeight;
    
    if (newLatitudeDelta <= 90 && newLongitudeDelta <= 90) {
        MKCoordinateRegion mapRegion;
        mapRegion.center = self.centerCoordinate;
        mapRegion.span.latitudeDelta = newLatitudeDelta;
        mapRegion.span.longitudeDelta = newLongitudeDelta;
        [self setRegion:mapRegion animated:NO];
    }
}

@end
