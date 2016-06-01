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
    [self updateUserInfo];
}

- (void)updateUserInfo {
    
    NSUInteger workingCount = [[APIManager sharedInstance] getWorkingGoStationCount];
    NSUInteger closedCount = [[APIManager sharedInstance] getClosedGoStationCount];
    NSUInteger constructingCount = [[APIManager sharedInstance] getConstructingGoStationCount];
    NSUInteger checkedinCount = [[APIManager sharedInstance] getTotalCheckedInCount];
    
    self.workingNumberLabel.text = [NSString stringWithFormat:@"%lu", workingCount + closedCount];
    self.constructingNumberLabel.text = [NSString stringWithFormat:@"%lu", constructingCount];
    self.checkinNumberLabel.text = [NSString stringWithFormat:@"%lu", checkedinCount];
    self.accomplishPercentageLabel.text = [NSString stringWithFormat:@"%02.1f%%", 100.0f * checkedinCount / (workingCount + closedCount)];
    
    NSDate *firstCheckinDate = [[APIManager sharedInstance] getFirstCheckinDate];
    NSDate *latestCheckinDate = [[APIManager sharedInstance] getLatestCheckinDate];
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
