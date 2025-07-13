//
//  ViewController.h
//  BrpLinksAppClip
//
//  Created by Thusitha Darshana Welagedara on 2025-07-01.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIButton *installButton;
@property (strong, nonatomic) UIImageView *logoView;
@property (strong, nonatomic) NSLayoutConstraint *logoAspectRatioConstraint;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIVisualEffectView *contentWithBlurView;

@property (strong, nonatomic) UIView *errorView;
@property (strong, nonatomic) UIVisualEffectView *errorWithBlurView;
@property (strong, nonatomic) UILabel *errorLabel;

@property (strong, nonatomic) CAGradientLayer *gradient;

@end

