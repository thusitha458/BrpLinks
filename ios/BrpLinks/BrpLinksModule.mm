#import "BrpLinksModule.h"
#import <React/RCTLog.h>

@implementation BrpLinksModule

RCT_EXPORT_MODULE();

RCT_REMAP_METHOD(initialize,
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
  // if the app clip has saved data here, use it
  NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.se.brpsystems.brplinks"];
  NSString *providerCode = [sharedDefaults objectForKey:@"provider_code"];
  
  NSLog(@"Provider code: %@", providerCode);
  if (providerCode != nil && [providerCode length] == 6) {
    [sharedDefaults removeObjectForKey:@"provider_code"];
    resolve(providerCode);
    return;
  }
  
  if (@available(iOS 16.0, *)) {
    [self pasteboardCouldContainAProviderCode:^(NSSet<NSString *> * _Nullable result, NSError * _Nullable error) {
      if (!error && [result containsObject:UIPasteboardDetectionPatternNumber]) {
        resolve(@"__pasteboard_contains_a_number__");
      } else {
        [self getProviderCodeFromAPI:^(NSString * _Nullable code, NSError * _Nullable error) {
          if (error) {
            reject(@"api_error", error.localizedDescription, error);
          } else {
            resolve(code ?: [NSNull null]);
          }
        }];
      }
    }];
  } else {
    NSString *codeFromPasteboard = [self extractBrpLinkFromPasteboard];
    if (codeFromPasteboard) {
      resolve(codeFromPasteboard);
      return;
    }
    
    [self getProviderCodeFromAPI:^(NSString * _Nullable code, NSError * _Nullable error) {
        if (error) {
          reject(@"api_error", error.localizedDescription, error);
        } else {
          resolve(code ?: [NSNull null]);
        }
      }];
  }
}

RCT_REMAP_METHOD(iosContinueWithoutPasting,
                  resolverx:(RCTPromiseResolveBlock)resolve
                  rejecterx:(RCTPromiseRejectBlock)reject)
{
  [self getProviderCodeFromAPI:^(NSString * _Nullable code, NSError * _Nullable error) {
      if (error) {
        reject(@"api_error", error.localizedDescription, error);
      } else {
        resolve(code ?: [NSNull null]);
      }
    }];
}

- (void)pasteboardCouldContainAProviderCode:(void(^)(NSSet<UIPasteboardDetectionPattern> * _Nullable,
                                                     NSError * _Nullable))completion
{
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  
  NSSet *patterns = [NSSet setWithObjects:UIPasteboardDetectionPatternNumber, nil];
  
  [pasteboard detectPatternsForPatterns:patterns completionHandler:completion];
}

- (NSString *)extractBrpLinkFromPasteboard
{
  UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
  
  NSString *pasteString = pasteboard.string;

  if (!pasteString)
  {
    return nil;
  }
  
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  [formatter setNumberStyle:NSNumberFormatterDecimalStyle];

  NSNumber *number = [formatter numberFromString:pasteString];

  if (number != nil && [number doubleValue] >= 1000000 && [number doubleValue] <= 1999999) {
    NSString *modifiedString = [pasteString substringFromIndex:1];
    return modifiedString;
  } else {
    return nil;
  }

  return nil;
}

- (void)getProviderCodeFromAPI:(void (^)(NSString * _Nullable code, NSError * _Nullable error))completion
{
  NSURL *url = [NSURL URLWithString:@"https://fbd-links.rootcode.software/api/ios/record-retrieval"];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:@"POST"];

  NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession]
    dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
          completion(nil, error);
          return;
        }

        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
          NSError *statusError = [NSError errorWithDomain:@"BrpLinksModule"
                                                     code:httpResponse.statusCode
                                                 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Unexpected status code: %ld", static_cast<long>(httpResponse.statusCode)]}];
          completion(nil, statusError);
          return;
        }

        NSError *jsonError;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError) {
          completion(nil, jsonError);
          return;
        }

        NSString *providerCode = json[@"providerCode"];
        if (providerCode) {
          completion(providerCode, nil);
        } else {
          NSError *codeError = [NSError errorWithDomain:@"BrpLinksModule"
                                                     code:999
                                                 userInfo:@{NSLocalizedDescriptionKey: @"Provider code not found"}];
          completion(nil, codeError);
        }
  }];

  [dataTask resume];
}

@end
