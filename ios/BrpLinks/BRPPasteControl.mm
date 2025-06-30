#import "BRPPasteControlTarget.h"
#import "BRPPasteControlView.h"
#import <React/RCTViewManager.h>

@interface BRPPasteControlManager : RCTViewManager
@end

@implementation BRPPasteControlManager

RCT_EXPORT_MODULE(BRPPasteControlManager)
RCT_EXPORT_VIEW_PROPERTY(onTextPasted, RCTBubblingEventBlock)

- (UIView *)view
{
  BRPPasteControlTarget *target = [[BRPPasteControlTarget alloc] init];
  
  if (@available(iOS 16.0, *)) {
    target.pasteConfiguration = [[UIPasteConfiguration alloc] initWithTypeIdentifiersForAcceptingClass:[NSString class]];
    
    UIPasteControlConfiguration *controlConfig = [[UIPasteControlConfiguration alloc] init];
    controlConfig.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    controlConfig.displayMode = UIPasteControlDisplayModeLabelOnly;
    
    BRPPasteControlView *pasteButton = [[BRPPasteControlView alloc] initWithConfiguration:controlConfig];
    
    pasteButton.target = target;
    
    [pasteButton addSubview:target];
    
    target.onTextPasted = ^(NSString *text) {
      if (pasteButton.onTextPasted) {
        pasteButton.onTextPasted(@{
          @"value": text,
        });
      }
    };
    
    return pasteButton;
  }
  
  return target;
}

@end
