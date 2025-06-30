#import <UIKit/UIKit.h>
#import <React/RCTComponent.h>

@interface BRPPasteControlView : UIPasteControl
    @property (nonatomic, copy) RCTBubblingEventBlock onTextPasted;
@end
