//
//  SettingsViewController.m
//  GoCheckin
//
//  Created by Mike Chou on 4/28/16.
//
//

#import "SettingsViewController.h"
#import "UIColor+GoCheckin.m"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self prepareNavigationBar];
    
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

@end
