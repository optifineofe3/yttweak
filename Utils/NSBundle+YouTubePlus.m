#import "NSBundle+YouTubePlus.h"

@implementation NSBundle (YouTubePlus)

+ (NSBundle *)ytp_defaultBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YouTubePlus" ofType:@"bundle"];
        NSString *kBundlePath = jbroot(@"/Library/Application Support/YouTubePlus.bundle");

        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: kBundlePath];
    });

    return bundle;
}

+ (NSBundle *)ytl_defaultBundle {
    return [self ytp_defaultBundle];
}

@end
