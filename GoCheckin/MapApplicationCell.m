//
//  MapApplicationCell.m
//  GoCheckin
//
//  Created by Mike Chou on 5/11/16.
//
//

#import "MapApplicationCell.h"
#import "MapOption.h"

@interface MapApplicationCell()

@property (weak, nonatomic) IBOutlet UILabel *applicationNameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *applicationStatusImageView;

@end

@implementation MapApplicationCell

- (void)setMapOption:(MapOption *)option {
    
    [self.applicationNameLabel setText:option.name];
    
    if (option.isDefault) {
        [self.applicationStatusImageView setImage:[UIImage imageNamed:@"icon_checkbox_checked"]];
    } else {
        [self.applicationStatusImageView setImage:[UIImage imageNamed:@"icon_checkbox_uncheck"]];
    }
    
    if (option.type != AppleMap) {
        // TODO: Maybe check is the other map applications are installed or not for users.
    }
    
}

@end
