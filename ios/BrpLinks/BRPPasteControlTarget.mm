#import "BRPPasteControlTarget.h"

@implementation BRPPasteControlTarget

- (void)pasteItemProviders:(NSArray<NSItemProvider *> *)itemProviders
{
  for (NSItemProvider *provider in itemProviders) {
      if ([provider canLoadObjectOfClass:[NSString class]]) {
          [provider loadObjectOfClass:[NSString class] completionHandler:^(NSString *string, NSError * _Nullable error) {
              if (string) {
                  dispatch_async(dispatch_get_main_queue(), ^{
                      if (self.onTextPasted) {
                        self.onTextPasted(string);
                      }
                  });
              }
          }];
      }
  }
}

@end
