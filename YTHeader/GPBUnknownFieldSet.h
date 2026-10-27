#import "GPBUnknownField.h"

@interface GPBUnknownFieldSet : NSObject <NSCopying>
- (BOOL)hasField:(int32_t)number;
- (GPBUnknownField *)getField:(int32_t)number;
- (NSUInteger)countOfFields;
@end
