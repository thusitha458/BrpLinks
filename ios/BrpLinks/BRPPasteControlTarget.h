#import <UIKit/UIKit.h>

@interface BRPPasteControlTarget : UIView
    @property (nonatomic, copy) void (^onTextPasted)(NSString *text);
@end
