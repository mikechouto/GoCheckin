//
//  SwitchableTableViewCell.m
//  GoCheckin
//
//  Created by Mike Chou on 8/11/16.
//
//

#import "SwitchableTableViewCell.h"
#import "APIManager.h"

@interface SwitchableTableViewCell()

@property (weak, nonatomic) IBOutlet UILabel *optionTitle;
@property (weak, nonatomic) IBOutlet UISwitch *optionSwitch;

@end

@implementation SwitchableTableViewCell

- (void)setTitle:(NSString *)title {
    [self.optionTitle setText:title];
    [self.optionSwitch setOn:[[APIManager sharedInstance] isShowDeprecatedStation]];
}

- (IBAction)_onOptionSwitchChanged:(UISwitch *)sender {
    [[APIManager sharedInstance] showDeprecatedStation:sender.isOn];
}

@end
