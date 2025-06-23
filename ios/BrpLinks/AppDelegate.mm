#import "AppDelegate.h"

#import <React/RCTBundleURLProvider.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  NSString *codeFromPasteboard = [self extractBrpLinkFromPasteboard];
  if (codeFromPasteboard) {
    [self showVisitCodeAlert:codeFromPasteboard afterDelay:5.0];
  } else {
    [self callTheAPI];
  }
  
  self.moduleName = @"BrpLinks";
  // You can add your custom initial props in the dictionary below.
  // They will be passed down to the ViewController used by React Native.
  self.initialProps = @{};
  
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (NSURL *)sourceURLForBridge:(RCTBridge *)bridge
{
  return [self getBundleURL];
}

- (NSURL *)getBundleURL
{
#if DEBUG
  return [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index"];
#else
  return [[NSBundle mainBundle] URLForResource:@"main" withExtension:@"jsbundle"];
#endif
}

- (void)callTheAPI
{
  NSURL *url = [NSURL URLWithString:@"https://fbd-links.rootcode.software/api/visits/latest"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];
  
  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
        dataTaskWithRequest:request
                                    completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
    if (error) {
      NSLog(@"API Call Failed: %@", error.localizedDescription);
      return;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    if (httpResponse.statusCode != 200) {
      NSLog(@"Unexpected status code: %ld", (long)httpResponse.statusCode);
      return;
    }
    
    NSError *jsonError;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
    if (jsonError) {
      NSLog(@"JSON parsing failed");
      return;
    }
    
    BOOL success = [json[@"success"] boolValue];
    if (success) {
      NSDictionary *latestVisit = json[@"latestVisit"];
      NSString *code = latestVisit[@"code"];
      if (code) {
        NSLog(@"Visit code: %@", code);
        [self showVisitCodeAlert:code afterDelay:5.0];
      } else {
        NSLog(@"Code could not found in the latestVisit");
      }
    } else {
      NSLog(@"API response indicates failure");
    }
  }
  ];
  
  [dataTask resume];
}

- (NSString *)extractBrpLinkFromPasteboard
{
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  
  NSString *pasteString = pasteboard.string;

  if (!pasteString) return nil;

  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"brplink::\\S+"
                                                                         options:0
                                                                           error:&error];

  NSTextCheckingResult *match = [regex firstMatchInString:pasteString options:0 range:NSMakeRange(0, pasteString.length)];

  if (match) {
    NSString *matchedString = [pasteString substringWithRange:match.range];
    NSLog(@"Matched brplink: %@", matchedString);
    return matchedString;
  }

  return nil;
}

- (void)showVisitCodeAlert:(NSString *)code afterDelay:(NSTimeInterval)delay
{
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Visit Code"
                                                                   message:code
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                       style:UIAlertActionStyleDefault
                                                     handler:nil];
    [alert addAction:okAction];

    UIViewController *rootVC = self.window.rootViewController;
    [rootVC presentViewController:alert animated:YES completion:nil];
  });
}

@end
