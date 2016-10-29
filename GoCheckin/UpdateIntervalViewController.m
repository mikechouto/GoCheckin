//
//  UpdateIntervalViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 8/11/16.
//
//

#import "UpdateIntervalViewController.h"
#import "UIColor+GoCheckin.h"
#import "APIManager.h"

@interface UpdateIntervalViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray *updateIntervals;
@property (assign, nonatomic) NSInteger currentInterval;

@end

@implementation UpdateIntervalViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.updateIntervals = @[@(1), @(3), @(6)];
    self.currentInterval = [[APIManager sharedInstance] updateInterval];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.updateIntervals.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *updateIntervalIdentifier = @"intervalIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:updateIntervalIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:updateIntervalIdentifier];
    }
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"Every %@ hour", nil), [self.updateIntervals objectAtIndex:indexPath.row]];
    [cell.textLabel setText:title];
    
    if ([[self.updateIntervals objectAtIndex:indexPath.row] integerValue] == self.currentInterval) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[APIManager sharedInstance] changeUpdateInterval:[[self.updateIntervals objectAtIndex:indexPath.row] integerValue]];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

@end
