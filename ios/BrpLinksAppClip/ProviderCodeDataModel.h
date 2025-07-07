#import <UIKit/UIKit.h>

@interface ProviderCodeDataModel : NSObject

@property (nonatomic, strong) NSString *providerCode;

+ (instancetype)getInstance; // Singleton accessor

@end
