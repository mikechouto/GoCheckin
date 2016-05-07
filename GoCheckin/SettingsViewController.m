//
//  SettingsViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/28/16.
//
//

#import "SettingsViewController.h"
#import "UIColor+GoCheckin.m"
#import "MapOption.h"

@interface SettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray<MapOption *> *supportedMapApplication;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareNavigationBar];
    
    self.supportedMapApplication = @[[[MapOption alloc] initWithName:@"Apple Map" MapType:MapTypeApple],
                           [[MapOption alloc] initWithName:@"Google Map" MapType:MapTypeGoogle]];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareNavigationBar {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [self.navigationController.navigationBar.backItem setTitle:@""];
    [self.navigationController.navigationBar setBackIndicatorImage:[UIImage imageNamed:@"icon_nav_item_back"]];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:[UIImage imageNamed:@"icon_nav_item_back"]];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor blueGoCheckinColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"Arial-BoldMT" size:20], NSForegroundColorAttributeName:[UIColor whiteColor]}];
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rows;
    
    switch (section) {
        case 0:
            rows = self.supportedMapApplication.count;
            break;
        case 1:
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
    
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        case 0:
            cell = [tableView dequeueReusableCellWithIdentifier:selectionIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:selectionIdentifier];
            }
            [cell.textLabel setText:[self.supportedMapApplication objectAtIndex:indexPath.row].name];
            break;
        case 1:
            cell = [tableView dequeueReusableCellWithIdentifier:clickableIdentifier];
            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:clickableIdentifier];
            }
            
            [cell.textLabel setText:@"Contact Us"];
            break;
        default:
            break;
    }
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *sectionTitle;
    switch (section) {
        case 0:
            sectionTitle = @"Map Selection";
            break;
        case 1:
            sectionTitle = @"Get Help";
            break;
        default:
            sectionTitle = @"";
            break;
    }
    
    return sectionTitle;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

@end
