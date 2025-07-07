#import "ViewController.h"
#import "ProviderCodeDataModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleProviderCodeReceival:) name:@"PROVIDER_CODE_RECEIVED" object:nil];
  
  ProviderCodeDataModel *dataModel = [ProviderCodeDataModel getInstance];
  NSString *providerCode = dataModel.providerCode;
  
  if ([self isFullAppInstalled]) {
    NSURL *fullAppUrl = providerCode ? [NSURL URLWithString:[NSString stringWithFormat:@"brplinkstest://providers/%@", providerCode]] : [NSURL URLWithString:@"brplinkstest://"];
    [[UIApplication sharedApplication] openURL:fullAppUrl options:@{} completionHandler:nil];
    return;
  }
  
  if (providerCode) {
    [self fetchInfoAndUpdateUI:providerCode];
  } else {
    // cannot find a provider code in the url, so install the app without the provider code
    self.welcomeLabel.text = @"Welcome to BRP App";
    self.installButton.enabled = YES;
    self.installButton.hidden = NO;
  }
}

- (BOOL)isFullAppInstalled {
  NSURL *fullAppUrl = [NSURL URLWithString:@"brplinkstest://"];
  if ([[UIApplication sharedApplication] canOpenURL:fullAppUrl]) {
    return YES;
  }
  return NO;
}

- (IBAction)onPressInstall:(id)sender {
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
      [self showLoader];
  });
  
  [self fetchAppIdAndApiUrlWithCode:providerCode withCallback:^(int appId, NSString * _Nullable api3Url, NSError * _Nullable error) {
    if (!appId || !api3Url || error) {
      dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLoader];
        self.welcomeLabel.text = @"Oops! Something is wrong.";
      });
      return;
    }
    
    [self fetchAppInfo:appId withApi3Url:api3Url withCallback:^(NSString * _Nullable appName, NSString * _Nullable darkLogo, NSString * _Nullable lightLogo, NSError * _Nullable error) {
      if (error) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self hideLoader];
          self.welcomeLabel.text = @"Oops! Something is wrong.";
        });
        return;
      }
      
      dispatch_async(dispatch_get_main_queue(), ^{
        [self hideLoader];
        self.welcomeLabel.text = [NSString stringWithFormat:@"Welcome to %@", appName];
        self.installButton.enabled = YES;
        self.installButton.hidden = NO;
      });
      [self setImage:lightLogo];
    }];
  }];
}

- (void)setImage:(NSString *)urlString {
  if (!urlString) {
    return;
  }
  
  NSURL *url = [NSURL URLWithString:urlString];
  
    NSURLSessionDataTask *downloadImageTask = [[NSURLSession sharedSession]
      dataTaskWithURL:url
      completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

          if (error == nil && data != nil) {
              UIImage *image = [UIImage imageWithData:data];
              if (image) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                    self.logoImage.image = image; // assuming self.imageView is your UIImageView
                  });
              }
          } else {
              NSLog(@"Failed to load image: %@", error.localizedDescription);
          }
      }];

  [downloadImageTask resume];
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
                   withCallback: (void (^)(NSString * _Nullable appName, NSString * _Nullable darkLogo, NSString * _Nullable lightLogo, NSError * _Nullable error))callback
{
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/api/ver3/apps/%d", api3Url, appId]];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
    dataTaskWithRequest:request
    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
          callback(nil, nil, nil, error);
          return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
          NSError *statusError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                     code:httpResponse.statusCode
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected status code"}];
          callback(nil, nil, nil, statusError);
          return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          callback(nil, nil, nil, jsonError);
          return;
        }
    
        NSString *appName = json[@"appName"];
    
        NSString *darkLogo = nil;
        NSString *lightLogo = nil;
        NSArray *assets = json[@"assets"];
        for (int i = 0; i < [assets count]; i++) {
          NSString *type = assets[i][@"type"];
          NSString *theme = assets[i][@"theme"];
          if (type && [type isEqual:@"LOGO"] && theme && [theme isEqual:@"light"]) {
            lightLogo = assets[i][@"contentUrl"];
          }
          if (type && [type isEqual:@"LOGO"] && theme && [theme isEqual:@"dark"]) {
            darkLogo = assets[i][@"contentUrl"];
          }
        }
        
        if (appName) {
          callback(appName, darkLogo, lightLogo, nil);
        } else {
          NSError *responseError = [NSError errorWithDomain:@"BrpLinksAppClip"
                                                   code:999
                                               userInfo:@{NSLocalizedDescriptionKey: @"Could not find app info"}];
          callback(nil, nil, nil, responseError);
        }
  }];

  [dataTask resume];
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
