#import "BrpLinksModule.h"
#import <React/RCTLog.h>

@implementation BrpLinksModule

RCT_EXPORT_MODULE();

RCT_REMAP_METHOD(initialize,
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  NSString *codeFromPasteboard = [self extractBrpLinkFromPasteboard];
  if (codeFromPasteboard) {
    resolve(codeFromPasteboard);
    return;
  }
  
  [self callTheAPIWithCompletion:^(NSString * _Nullable code, NSError * _Nullable error) {
      if (error) {
        reject(@"api_error", error.localizedDescription, error);
      } else {
        resolve(code ?: [NSNull null]);
      }
    }];
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

- (void)callTheAPIWithCompletion:(void (^)(NSString * _Nullable code, NSError * _Nullable error))completion
{
  NSURL *url = [NSURL URLWithString:@"https://fbd-links.rootcode.software/api/visits/latest"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"GET"];

  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
    dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
          completion(nil, error);
          return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
          NSError *statusError = [NSError errorWithDomain:@"MyNativeModule"
                                                     code:httpResponse.statusCode
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Unexpected status code"}];
          completion(nil, statusError);
          return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          completion(nil, jsonError);
          return;
        }

        BOOL success = [json[@"success"] boolValue];
        if (success) {
          NSDictionary *latestVisit = json[@"latestVisit"];
          NSString *code = latestVisit[@"code"];
          if (code) {
            completion(code, nil);
          } else {
            NSError *codeError = [NSError errorWithDomain:@"MyNativeModule"
                                                     code:999
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Code not found in latestVisit"}];
            completion(nil, codeError);
          }
        } else {
          NSError *responseError = [NSError errorWithDomain:@"MyNativeModule"
                                                       code:998
                                                   userInfo:@{NSLocalizedDescriptionKey: @"API response indicates failure"}];
          completion(nil, responseError);
        }
  }];

  [dataTask resume];
}

@end
