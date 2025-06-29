#import "BRPPasteControlTarget.h"
#import <React/RCTViewManager.h>

@interface BRPPasteControlManager : RCTViewManager
@end

@implementation BRPPasteControlManager

RCT_EXPORT_MODULE(BRPPasteControl)

- (UIView *)view
{
  BRPPasteControlTarget *target = [[BRPPasteControlTarget alloc] init];
  
  if (@available(iOS 16.0, *)) {
    target.pasteConfiguration = [[UIPasteConfiguration alloc] initWithTypeIdentifiersForAcceptingClass:[NSString class]];
    
    UIPasteControlConfiguration *controlConfig = [[UIPasteControlConfiguration alloc] init];
//    controlConfig.baseBackgroundColor = [UIColor redColor];
//    controlConfig.baseForegroundColor = [UIColor magentaColor];
    controlConfig.cornerStyle = UIButtonConfigurationCornerStyleCapsule;
    controlConfig.displayMode = UIPasteControlDisplayModeLabelOnly;
    
    UIPasteControl *pasteButton = [[UIPasteControl alloc] initWithConfiguration:controlConfig];
//    pasteButton.frame = CGRectMake(100, 200, 100, 40);
    
    pasteButton.target = target;
    
    [pasteButton addSubview:target];
    
    return pasteButton;
//    [target addSubview:pasteButton];
  }
  
  return target;
}

@end
