//
//  ViewController.h
//  BrpLinksAppClip
//
//  Created by Thusitha Darshana Welagedara on 2025-07-01.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UILabel *welcomeLabel;
@property (weak, nonatomic) IBOutlet UIButton *installButton;
@property (weak, nonatomic) IBOutlet UIImageView *logoImage;

@end

