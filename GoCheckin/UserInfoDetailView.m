//
//  UserInfoDetailView.m
//  GoCheckin
//
//  Created by Mike Chou on 5/27/16.
//
//

#import "UserInfoDetailView.h"
#import "UIColor+GoCheckin.h"
#import "APIManager.h"

@interface UserInfoDetailView()

@property (weak, nonatomic) IBOutlet UINavigationBar *topBar;

@property (weak, nonatomic) IBOutlet UILabel *workingNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *constructingNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *checkinNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *accomplishPercentageLabel;
@property (weak, nonatomic) IBOutlet UILabel *firstCheckinDateLabel;
@property (weak, nonatomic) IBOutlet UILabel *latestCheckinDateLabel;

@end

@implementation UserInfoDetailView

- (instancetype)init {
    self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:@"UserInfoDetailView" owner:self options:nil] lastObject];
    
    if (self) {
        [_topBar setTintColor:[UIColor whiteColor]];
        [_topBar setBarTintColor:[UIColor blueGoCheckinColor]];
        [_topBar setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:18]}];
        
        UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:_topBar.frame];
        [_topBar.layer setShadowColor:[UIColor darkGrayColor].CGColor];
        [_topBar.layer setShadowOffset:CGSizeMake(0, 3)];
        [_topBar.layer setShadowOpacity:0.5];
        [_topBar.layer setShadowPath:shadowPath.CGPath];
        
        [self setBackgroundColor:[UIColor colorWithRed:250/255.0f green:255/255.0f blue:253/255.0f alpha:0.9]];
    }
    return self;
}

- (void)didMoveToSuperview {
    [self _updateUserInfo];
}

- (void)_updateUserInfo {
    
    NSUInteger workingCount = [[APIManager sharedInstance] workingGoStationCount];
    NSUInteger closedCount = [[APIManager sharedInstance] closedGoStationCount];
    NSUInteger constructingCount = [[APIManager sharedInstance] constructingGoStationCount];
    NSUInteger checkedinCount = [[APIManager sharedInstance] totalCheckedInCount];
    
    self.workingNumberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)workingCount + closedCount];
    self.constructingNumberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)constructingCount];
    self.checkinNumberLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)checkedinCount];
    double accomplishPercentage = 100.0f * checkedinCount / (workingCount + closedCount);
    self.accomplishPercentageLabel.text = [NSString stringWithFormat:@"%02.1f%%", accomplishPercentage < 100.0 ? accomplishPercentage : 100.0];
    
    NSDate *firstCheckinDate = [[APIManager sharedInstance] firstCheckinDate];
    NSDate *latestCheckinDate = [[APIManager sharedInstance] latestCheckinDate];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy/MM/dd"];
    if (firstCheckinDate) {
        self.firstCheckinDateLabel.text = [dateFormatter stringFromDate:firstCheckinDate];
    }

    if (latestCheckinDate) {
        self.latestCheckinDateLabel.text = [dateFormatter stringFromDate:latestCheckinDate];
    }
}

@end
