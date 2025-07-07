#import "ProviderCodeDataModel.h"

@implementation ProviderCodeDataModel

+ (instancetype)getInstance {
    static ProviderCodeDataModel *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    return self;
}

@end
