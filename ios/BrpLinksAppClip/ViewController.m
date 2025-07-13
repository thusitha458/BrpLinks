#import "ViewController.h"
#import "ProviderCodeDataModel.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self setupUI];
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProviderCodeReceival:) name:@"PROVIDER_CODE_RECEIVED" object:nil];
  
  ProviderCodeDataModel *dataModel = [ProviderCodeDataModel getInstance];
  NSString *providerCode = dataModel.providerCode;
  
  if ([self isFullAppInstalled]) {
    self.contentWithBlurView.hidden = YES;
    self.errorWithBlurView.hidden = NO;
    self.errorLabel.text = @"The full app is already installed.";
    [self.gradient removeFromSuperlayer];
    self.gradient = [self addGradientBackground];
    
    NSURL *fullAppUrl = providerCode ? [NSURL URLWithString:[NSString stringWithFormat:@"brplinkstest://providers/%@", providerCode]] : [NSURL URLWithString:@"brplinkstest://"];
    [[UIApplication sharedApplication] openURL:fullAppUrl options:@{} completionHandler:nil];
    return;
  }
  
  if (providerCode) {
    [self fetchInfoAndUpdateUI:providerCode];
  } else {
    // cannot find a provider code in the url, so install the app without the provider code
    self.contentWithBlurView.hidden = NO;
    self.errorWithBlurView.hidden = YES;
    self.logoView.hidden = YES;
    self.titleLabel.text = @"Get the app!";
    [self.gradient removeFromSuperlayer];
    self.gradient = [self addGradientBackground];
    self.installButton.backgroundColor = [self colorFromHexString:@"#2191F2"];
  }
}

- (BOOL)isFullAppInstalled {
  NSURL *fullAppUrl = [NSURL URLWithString:@"brplinkstest://"];
  if ([[UIApplication sharedApplication] canOpenURL:fullAppUrl]) {
    return YES;
  }
  return NO;
}

- (void)onPressInstall {
  NSURL *url = [NSURL URLWithString:@"https://testflight.apple.com/"];
  if ([[UIApplication sharedApplication] canOpenURL:url]) {
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
  }
  
  ProviderCodeDataModel *dataModel = [ProviderCodeDataModel getInstance];
  NSString *providerCode = dataModel.providerCode;
  
  if (providerCode) {
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.se.brpsystems.brplinks"];
    if (sharedDefaults) {
      [sharedDefaults setObject:providerCode forKey:@"provider_code"];
    }
  }
}

- (void)handleProviderCodeReceival:(NSNotification *)notification {
  NSString *providerCode = notification.userInfo[@"providerCode"];
  if (providerCode) {
    if ([self isFullAppInstalled]) {
      self.contentWithBlurView.hidden = YES;
      self.errorWithBlurView.hidden = NO;
      self.errorLabel.text = @"The full app is already installed.";
      [self.gradient removeFromSuperlayer];
      self.gradient = [self addGradientBackground];
      
      NSURL *fullAppUrl = [NSURL URLWithString:[NSString stringWithFormat:@"brplinkstest://providers/%@", providerCode]];
      [[UIApplication sharedApplication] openURL:fullAppUrl options:@{} completionHandler:nil];
      return;
    }
    
    [self fetchInfoAndUpdateUI:providerCode];
  }
}

- (void)fetchInfoAndUpdateUI:(NSString *)providerCode
{
  if (!providerCode) {
    return;
  }
  
  dispatch_async(dispatch_get_main_queue(), ^{
      self.contentWithBlurView.hidden = YES;
      self.errorWithBlurView.hidden = YES;
      [self showLoader];
  });
  
  [self fetchAppIdAndApiUrlWithCode:providerCode withCallback:^(int appId, NSString * _Nullable api3Url, NSError * _Nullable error) {
    if (!appId || !api3Url || error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLoader];
        self.contentWithBlurView.hidden = YES;
        self.errorWithBlurView.hidden = NO;
        self.errorLabel.text = @"Oops! Failed to load content.";
        [self.gradient removeFromSuperlayer];
        self.gradient = [self addGradientBackground];
      });
      return;
    }
    
    [self fetchAppInfo:appId withApi3Url:api3Url withCallback:^(NSString * _Nullable appName, NSString * _Nullable logo, NSNumber * _Nullable logoHeight, NSNumber * _Nullable logoWidth, NSString * _Nullable primaryColor, NSError * _Nullable error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self hideLoader];
          self.contentWithBlurView.hidden = YES;
          self.errorWithBlurView.hidden = NO;
          self.errorLabel.text = @"Oops! Failed to load content.";
          [self.gradient removeFromSuperlayer];
          self.gradient = [self addGradientBackground];
        });
        return;
      }
      
      if (logo && logoHeight > 0 && logoWidth > 0) {
        NSURLSessionDataTask *downloadImageTask = [[NSURLSession sharedSession]
          dataTaskWithURL:[NSURL URLWithString:logo]
          completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

              if (error == nil && data != nil) {
                  UIImage *image = [UIImage imageWithData:data];
                  if (image) {
                      dispatch_async(dispatch_get_main_queue(), ^{
                        [self hideLoader];
                        self.contentWithBlurView.hidden = NO;
                        self.errorWithBlurView.hidden = YES;
                        self.titleLabel.text = [NSString stringWithFormat:@"Get the %@ app!", appName];
                        [self.gradient removeFromSuperlayer];
                        self.gradient = primaryColor ? [self addGradientBackgroundWithColor:primaryColor] : [self addGradientBackground];
                        self.installButton.backgroundColor = primaryColor ? [self colorFromHexString:primaryColor] : [self colorFromHexString:@"#2191F2"];
                        
                        self.logoView.image = image;
                        if (self.logoAspectRatioConstraint) {
                          [self.logoView removeConstraint:self.logoAspectRatioConstraint];
                        }
                        
                        self.logoAspectRatioConstraint = [NSLayoutConstraint constraintWithItem:self.logoView
                                                                                       attribute:NSLayoutAttributeWidth
                                                                                       relatedBy:NSLayoutRelationEqual
                                                                                          toItem:self.logoView
                                                                                       attribute:NSLayoutAttributeHeight
                                                                                     multiplier:([logoWidth doubleValue]/[logoHeight doubleValue])
                                                                                        constant:0];
                        [self.logoView addConstraint:self.logoAspectRatioConstraint];
                      });
                  }
              } else {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    [self hideLoader];
                    self.contentWithBlurView.hidden = NO;
                    self.errorWithBlurView.hidden = YES;
                    self.titleLabel.text = [NSString stringWithFormat:@"Get the %@ app!", appName];
                    [self.gradient removeFromSuperlayer];
                    self.gradient = [self addGradientBackground];
                    self.installButton.backgroundColor = [self colorFromHexString:@"#2191F2"];
                  });
                  NSLog(@"Failed to load image: %@", error.localizedDescription);
              }
        }];

        [downloadImageTask resume];
      } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self hideLoader];
          self.contentWithBlurView.hidden = NO;
          self.errorWithBlurView.hidden = YES;
          
          self.titleLabel.text = [NSString stringWithFormat:@"Get the %@ app!", appName];
          
          [self.gradient removeFromSuperlayer];
          self.gradient = [self addGradientBackground];
          
          self.installButton.backgroundColor = [self colorFromHexString:@"#2191F2"];
        });
      }
    }];
  }];
}

- (void)showLoader {
    // Create activity indicator
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.center = self.view.center;
    self.activityIndicator.hidesWhenStopped = YES;
    
    // Add to view and start animating
    [self.view addSubview:self.activityIndicator];
    [self.activityIndicator startAnimating];
}

- (void)hideLoader {
    [self.activityIndicator stopAnimating];
    [self.activityIndicator removeFromSuperview];
}

- (void)fetchAppIdAndApiUrlWithCode:(NSString *)providerCode
                   withCallback: (void (^)(int appId, NSString * _Nullable api3Url, NSError * _Nullable error))callback
{
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://appservice.brpsystems.net/apps?appCode=%@", providerCode]];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
    dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
          callback(0, nil, error);
          return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
          NSError *statusError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                     code:httpResponse.statusCode
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected status code"}];
          callback(0, nil, statusError);
          return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          callback(0, nil, jsonError);
          return;
        }
    
        NSArray *jsonArray = (NSArray *)json;
        if (jsonArray.count == 0) {
          NSError *responseError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                   code:999
                                               userInfo:@{NSLocalizedDescriptionKey: @"Could not find app info"}];
          callback(0, nil, responseError);
          return;
        }
    
        NSDictionary *firstObject = jsonArray[0];
        NSNumber *appIdAsNumber = firstObject[@"appId"];
        int appId = appIdAsNumber ? [appIdAsNumber intValue] : 0;
        NSString *api3Url = firstObject[@"api3Url"];
        
        if (appId != 0 && api3Url) {
          callback(appId, api3Url, nil);
        } else {
          NSError *responseError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                   code:999
                                               userInfo:@{NSLocalizedDescriptionKey: @"Could not find app info"}];
          callback(0, nil, responseError);
        }
  }];

  [dataTask resume];
}

- (void)fetchAppInfo:(int)appId
                   withApi3Url:(NSString *)api3Url
                   withCallback: (void (^)(NSString * _Nullable appName, NSString * _Nullable logo, NSNumber * _Nullable logoHeight, NSNumber * _Nullable logoWidth, NSString * _Nullable primaryColor, NSError * _Nullable error))callback
{
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/ver3/apps/%d", api3Url, appId]];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
    dataTaskWithRequest:request
    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
          callback(nil, nil, nil, nil, nil, error);
          return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
          NSError *statusError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                     code:httpResponse.statusCode
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected status code"}];
          callback(nil, nil, nil, nil, nil, statusError);
          return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          callback(nil, nil, nil, nil, nil, jsonError);
          return;
        }
    
        NSString *appName = json[@"appName"];
    
        NSString *darkLogo = nil;
        NSString *lightLogo = nil;
        NSNumber *darkLogoHeight = nil;
        NSNumber *darkLogoWidth = nil;
        NSNumber *lightLogoHeight = nil;
        NSNumber *lightLogoWidth = nil;
        NSArray *assets = json[@"assets"];
        for (int i = 0; i < [assets count]; i++) {
          NSString *type = assets[i][@"type"];
          NSString *theme = assets[i][@"theme"];
          if (type && [type isEqual:@"LOGO"] && theme && [theme isEqual:@"light"]) {
            lightLogo = assets[i][@"contentUrl"];
            lightLogoHeight = assets[i][@"imageHeight"];
            lightLogoWidth = assets[i][@"imageWidth"];
          }
          if (type && [type isEqual:@"LOGO"] && theme && [theme isEqual:@"dark"]) {
            darkLogo = assets[i][@"contentUrl"];
            darkLogoHeight = assets[i][@"imageHeight"];
            darkLogoWidth = assets[i][@"imageWidth"];
          }
        }
    
        NSString *primaryColor = nil;
        NSDictionary *themes = json[@"themes"];
        if (themes) {
          NSDictionary *lightTheme = themes[@"light"];
          NSDictionary *darkTheme = themes[@"dark"];
          
          if (lightTheme && lightTheme[@"primaryColor"]) {
            primaryColor = lightTheme[@"primaryColor"];
          } else if (darkTheme && darkTheme[@"primaryColor"]) {
            primaryColor = darkTheme[@"primaryColor"];
          }
        }
        
        
        if (appName) {
          if (lightLogo) {
            callback(appName, lightLogo, lightLogoHeight, lightLogoWidth, primaryColor, nil);
          } else {
            callback(appName, darkLogo, lightLogoHeight, lightLogoWidth, primaryColor, nil);
          }
        } else {
          NSError *responseError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                   code:999
                                               userInfo:@{NSLocalizedDescriptionKey: @"Could not find app info"}];
          callback(nil, nil, nil, nil, nil, responseError);
        }
  }];

  [dataTask resume];
}

- (void)setupUI {
  self.gradient = [self addGradientBackground];
    self.contentView = [self getContentContainer];
    
    self.logoView = [self getLogo];
    [self.contentView addSubview:self.logoView];
    
    self.titleLabel = [self getTitle];
    [self.contentView addSubview:self.titleLabel];
    
    UILabel *subtitle = [self getSubtitle];
    [self.contentView addSubview:subtitle];
    
    self.installButton = [self getInstallButton];
    [self.contentView addSubview:self.installButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.logoView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:24],
        [self.logoView.bottomAnchor constraintEqualToAnchor:self.titleLabel.topAnchor constant:-24],
        [self.logoView.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
        [self.logoView.heightAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:(1.0/3)],
        [self.logoView.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:(1.0/3)],
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:subtitle.topAnchor constant:-24],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [subtitle.bottomAnchor constraintEqualToAnchor:self.installButton.topAnchor constant:-24],
        [subtitle.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:24],
        [subtitle.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-24],
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.installButton.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-24],
        [self.installButton.centerXAnchor constraintEqualToAnchor:self.contentView.centerXAnchor],
    ]];
  
    self.contentWithBlurView.hidden = YES;
  
    self.errorView = [self getErrorContainer];
    self.errorLabel = [self getErrorLabel];
    [self.errorView addSubview:self.errorLabel];
  
    [NSLayoutConstraint activateConstraints:@[
        [self.errorLabel.topAnchor constraintEqualToAnchor:self.errorView.topAnchor constant:24],
        [self.errorLabel.bottomAnchor constraintEqualToAnchor:self.errorView.bottomAnchor constant:-24],
        [self.errorLabel.leadingAnchor constraintEqualToAnchor:self.errorView.leadingAnchor constant:24],
        [self.errorLabel.trailingAnchor constraintEqualToAnchor:self.errorView.trailingAnchor constant:-24],
    ]];
  
    self.errorWithBlurView.hidden = NO;
}

- (CAGradientLayer *)addGradientBackground {
  return [self addGradientBackgroundWithColor:@"#EDEADE"];
}

- (CAGradientLayer *)addGradientBackgroundWithColor:(NSString *) secondColorAsHex {
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = @[
      (__bridge id)[self colorFromHexString:@"#EDEADE"].CGColor,
      (__bridge id)[self colorFromHexString:secondColorAsHex].CGColor,
    ];

    gradient.locations = @[@0.0, @1.6];
  
    gradient.startPoint = CGPointMake(0.5, 0.0);
    gradient.endPoint = CGPointMake(0.5, 1.0);

    [self.view.layer insertSublayer:gradient atIndex:0];
  
    return gradient;
}

- (UIView *)getContentContainer {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.contentWithBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.contentWithBlurView.translatesAutoresizingMaskIntoConstraints = NO;
    self.contentWithBlurView.layer.cornerRadius = 24;
    self.contentWithBlurView.layer.masksToBounds = YES;
    self.contentWithBlurView.alpha = 1;
    [self.view addSubview:self.contentWithBlurView];
    
    UIView *contentView = [[UIView alloc] init];
    contentView.backgroundColor = [self colorFromHexString:@"#FFFFFF"];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentWithBlurView.contentView addSubview:contentView];
    
    // Blur container constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.contentWithBlurView.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [self.contentWithBlurView.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
        [self.contentWithBlurView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [self.contentWithBlurView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
    ]];
    
    // Content view inside blur
    [NSLayoutConstraint activateConstraints:@[
        [contentView.topAnchor constraintEqualToAnchor:self.contentWithBlurView.contentView.topAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:self.contentWithBlurView.contentView.bottomAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:self.contentWithBlurView.contentView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:self.contentWithBlurView.contentView.trailingAnchor],
    ]];
    
    return contentView;
}

- (UIImageView *)getLogo {
    UIImageView *logo = [[UIImageView alloc] init];
    logo.translatesAutoresizingMaskIntoConstraints = NO;
    logo.contentMode = UIViewContentModeScaleAspectFit;
    logo.clipsToBounds = YES;
    
    return logo;
}

- (UILabel *)getTitle {
    UILabel *title = [[UILabel alloc] init];
    title.text = @"";
    title.textColor = [UIColor blackColor];
    title.numberOfLines = 0;
    title.textAlignment = NSTextAlignmentCenter;
    title.font = [UIFont boldSystemFontOfSize:24];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    
    return title;
}

- (UILabel *)getSubtitle {
    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"Click the button below to install the app on your device.";
    subtitle.textColor = [UIColor blackColor];
    subtitle.numberOfLines = 0;
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.font = [UIFont systemFontOfSize:16];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    
    return subtitle;
}

- (UIButton *)getInstallButton {
    UIButton *installButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [installButton setTitle:@"📲 Install the app" forState:UIControlStateNormal];
    installButton.backgroundColor = [self colorFromHexString:@"#2191F2"];
    installButton.titleLabel.font = [UIFont boldSystemFontOfSize:18];
    [installButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [installButton setTitleShadowColor:[UIColor grayColor] forState:UIControlStateNormal];
    [installButton.titleLabel setShadowOffset:CGSizeMake(0.2, 0.2)];
    installButton.layer.cornerRadius = 12;
    installButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIEdgeInsets padding = UIEdgeInsetsMake(10, 20, 10, 20);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    installButton.contentEdgeInsets = padding;
#pragma clang diagnostic pop
    [installButton addTarget:self action:@selector(onPressInstall) forControlEvents:UIControlEventTouchUpInside];
    
    return installButton;
}

- (UIView *)getErrorContainer {
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    self.errorWithBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    self.errorWithBlurView.translatesAutoresizingMaskIntoConstraints = NO;
    self.errorWithBlurView.layer.cornerRadius = 24;
    self.errorWithBlurView.layer.masksToBounds = YES;
    self.errorWithBlurView.alpha = 0.85;
    [self.view addSubview:self.errorWithBlurView];
    
    UIView *errorView = [[UIView alloc] init];
    errorView.backgroundColor = [self colorFromHexString:@"#FFFFFF"];
    errorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.errorWithBlurView.contentView addSubview:errorView];
    
    // Blur container constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.errorWithBlurView.centerXAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerXAnchor],
        [self.errorWithBlurView.centerYAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.centerYAnchor],
        [self.errorWithBlurView.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:24],
        [self.errorWithBlurView.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-24],
    ]];
    
    // Content view inside blur
    [NSLayoutConstraint activateConstraints:@[
        [errorView.topAnchor constraintEqualToAnchor:self.errorWithBlurView.contentView.topAnchor],
        [errorView.bottomAnchor constraintEqualToAnchor:self.errorWithBlurView.contentView.bottomAnchor],
        [errorView.leadingAnchor constraintEqualToAnchor:self.errorWithBlurView.contentView.leadingAnchor],
        [errorView.trailingAnchor constraintEqualToAnchor:self.errorWithBlurView.contentView.trailingAnchor],
    ]];
    
    return errorView;
}

- (UILabel *)getErrorLabel {
    UILabel *errorLabel = [[UILabel alloc] init];
    errorLabel.text = @"";
    errorLabel.textColor = [UIColor blackColor];
    errorLabel.numberOfLines = 0;
    errorLabel.textAlignment = NSTextAlignmentCenter;
    errorLabel.font = [UIFont systemFontOfSize:16];
    errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    return errorLabel;
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    NSString *cleanHexString = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];

    if (cleanHexString.length == 3) {
        NSString *r = [cleanHexString substringWithRange:NSMakeRange(0, 1)];
        NSString *g = [cleanHexString substringWithRange:NSMakeRange(1, 1)];
        NSString *b = [cleanHexString substringWithRange:NSMakeRange(2, 1)];
        cleanHexString = [NSString stringWithFormat:@"%@%@%@%@%@%@", r, r, g, g, b, b];
    }

    // Ensure the string is 6 characters long (RRGGBB) after potential expansion
    if (cleanHexString.length != 6) {
        NSLog(@"Invalid hex string length: %@", hexString);
        return [UIColor clearColor];
    }

    unsigned int rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:cleanHexString];
    [scanner scanHexInt:&rgbValue];

    CGFloat red = ((rgbValue & 0xFF0000) >> 16) / 255.0;
    CGFloat green = ((rgbValue & 0x00FF00) >> 8) / 255.0;
    CGFloat blue = (rgbValue & 0x0000FF) / 255.0;

    return [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
