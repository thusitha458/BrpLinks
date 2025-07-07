//
//  SceneDelegate.m
//  BrpLinksAppClip
//
//  Created by Thusitha Darshana Welagedara on 2025-07-01.
//

#import "SceneDelegate.h"
#import "ProviderCodeDataModel.h"

@interface SceneDelegate ()

@end

@implementation SceneDelegate


- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
    // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
    // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
  
    NSSet<NSUserActivity *> *userActivities = connectionOptions.userActivities;
    for (NSUserActivity *userActivity in userActivities) {
      if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        NSURL *incomingUrl = userActivity.webpageURL;
        if (incomingUrl) {
          NSString *providerCode = [self extractProviderCode:incomingUrl];
          if (providerCode) {
            ProviderCodeDataModel *dataModel = [ProviderCodeDataModel getInstance];
            dataModel.providerCode = providerCode;
          }
          break;
        }
      }
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity {
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    NSURL *url = userActivity.webpageURL;
    if (url) {
      NSString *providerCode = [self extractProviderCode:url];
      if (providerCode) {
        ProviderCodeDataModel *dataModel = [ProviderCodeDataModel getInstance];
        dataModel.providerCode = providerCode;
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PROVIDER_CODE_RECEIVED" object:nil userInfo:@{@"providerCode": providerCode}];
      }
    }
  }
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
}


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
}


- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
}

- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
}

- (NSString *)extractProviderCode:(NSURL *)url {
  if (url && [url.path hasPrefix:@"/providers/"] && [url.lastPathComponent isEqualToString:[url.path stringByReplacingOccurrencesOfString:@"/providers/" withString:@""]]) {
    return url.lastPathComponent;
  }
  return nil;
}

@end
