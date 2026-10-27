#import "NSBundle+YouTubePlus.h"

#if __has_include(<roothide.h>)
#import <roothide.h>
#endif

#ifndef jbroot
#define jbroot(path) path
#endif

@implementation NSBundle (YouTubePlus)

+ (NSBundle *)ytp_defaultBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:@"YouTubePlus" ofType:@"bundle"];
        NSString *kBundlePath = jbroot(@"/Library/Application Support/YouTubePlus.bundle");
        NSString *rootlessBundlePath = @"/var/jb/Library/Application Support/YouTubePlus.bundle";

        bundle = [NSBundle bundleWithPath:tweakBundlePath ?: ([[NSFileManager defaultManager] fileExistsAtPath:rootlessBundlePath] ? rootlessBundlePath : kBundlePath)];
    });

    return bundle;
}

+ (NSBundle *)ytl_defaultBundle {
    return [self ytp_defaultBundle];
}

@end
