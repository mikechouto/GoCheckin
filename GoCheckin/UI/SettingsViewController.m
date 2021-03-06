//
//  SettingsViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/28/16.
//
//

#import <MessageUI/MessageUI.h>
#import <sys/utsname.h>
#import "SettingsViewController.h"
#import "UIColor+GoCheckin.h"
#import "MapOption.h"
#import "MapApplicationCell.h"
#import "APIManager.h"
#import "SwitchableTableViewCell.h"
#import "UpdateIntervalTableViewCell.h"

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (strong, nonatomic) NSArray<MapOption *> *supportedMaps;
@property (strong, nonatomic) NSArray *sectionTitles;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self _prepareNavigationBar];
    [self.versionLabel setText:[NSString stringWithFormat:NSLocalizedString(@"Version: %@", nil), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]];
    
    self.sectionTitles = @[NSLocalizedString(@"General", nil),
                           NSLocalizedString(@"Map Selection", nil),
                           NSLocalizedString(@"Get Help", nil)];
    
    self.supportedMaps = @[[[MapOption alloc] initWithName:@"Apple Map" MapType:AppleMap],
                           [[MapOption alloc] initWithName:@"Google Map" MapType:GoogleMap]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)_prepareNavigationBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = backItem;
    
    [self.navigationController.navigationBar.backItem setTitle:@""];
    [self.navigationController.navigationBar setBackIndicatorImage:[UIImage imageNamed:@"icon_nav_item_back"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"icon_nav_item_back"]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor blueGoCheckinColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:20], NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

- (void)_sendFeedbackMail {
    // Email Subject
    NSString *emailTitle = @"GoCheckin Feedback";
    // Email Body
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
    NSString *messageBody = [NSString stringWithFormat:@"GoCheckin %@\n%@-%@:\n%@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"], [self _deviceModel], iOSVersion, [self _deviceUniqueIdentifier]];
    // To address
    NSArray *toRecipents = [NSArray arrayWithObject:@"mikechouto@gmail.com"];
    
    MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
    mailComposeViewController.mailComposeDelegate = self;
    [mailComposeViewController setSubject:emailTitle];
    [mailComposeViewController setMessageBody:messageBody isHTML:NO];
    [mailComposeViewController setToRecipients:toRecipents];
    
    // Present mail view controller on screen
    [self presentViewController:mailComposeViewController animated:YES completion:NULL];
}

- (void)_deselectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)_deviceModel {
    struct utsname systemInfo;
    uname(&systemInfo);
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

- (NSString *)_deviceUniqueIdentifier {
    NSString *uniqueIdentifier = [[[[UIDevice currentDevice] identifierForVendor] UUIDString] lowercaseString];
    return [uniqueIdentifier stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rows;
    
    switch (section) {
        case 0:
            rows = 2;
            break;
        case 1:
            rows = self.supportedMaps.count;
            break;
        case 2:
            rows = 1;
            break;
        default:
            rows = 0;
            break;
    }
    
    return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *selectionIdentifier = @"SelectionCell";
    static NSString *clickableIdentifier = @"ClickableCell";
    static NSString *switchableIdentifier = @"SwitchableCell";
    static NSString *intervalPageIdentifier = @"IntervalPageCell";
    
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case 0:
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:intervalPageIdentifier];
                if (cell == nil) {
                    cell = [[UpdateIntervalTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:intervalPageIdentifier];
                }
                [[(UpdateIntervalTableViewCell *)cell titleLabel] setText:NSLocalizedString(@"Update Stations", nil)];
                NSString *detailString = [NSString stringWithFormat:NSLocalizedString(@"Every %@ hour", nil), @([[APIManager sharedInstance] updateInterval])];
                [[(UpdateIntervalTableViewCell *)cell detailLabel] setText:detailString];
            }
            
            if (indexPath.row == 1) {
                cell = [tableView dequeueReusableCellWithIdentifier:switchableIdentifier];
                if (cell == nil) {
                    cell = [[SwitchableTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:switchableIdentifier];
                }
                [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
                [(SwitchableTableViewCell *)cell setTitle:NSLocalizedString(@"Show Deprecated Stations", nil)];
            }
            break;
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:selectionIdentifier];
            if (cell == nil) {
                cell = [[MapApplicationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:selectionIdentifier];
            }
            
            if ([cell isKindOfClass:[MapApplicationCell class]]) {
                
                [(MapApplicationCell *)cell setMapOption:[self.supportedMaps objectAtIndex:indexPath.row]];
            }
            break;
        case 2:
            cell = [tableView dequeueReusableCellWithIdentifier:clickableIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:clickableIdentifier];
            }
            
            [cell.textLabel setText:NSLocalizedString(@"Contact us", nil)];
            break;
        default:
            break;
    }
    
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setLayoutMargins:UIEdgeInsetsZero];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case 0:
            break;
        case 1:
            [[self.supportedMaps objectAtIndex:indexPath.row] setToDefault];
            [tableView reloadData];
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            break;
        case 2:
            [self _sendFeedbackMail];
            break;
        default:
            break;
    }

    [self performSelector:@selector(_deselectRowAtIndexPath:) withObject:indexPath afterDelay:0.05];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.sectionTitles objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

#pragma mark MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    
    switch (result) {
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultFailed:
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
