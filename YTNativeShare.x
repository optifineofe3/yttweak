#import <UIKit/UIActivityViewController.h>
#import "YouTubePlus.h"
#import "YTHeader/GPBDescriptor.h"
#import "YTHeader/GPBMessage.h"
#import "YTHeader/GPBUnknownField.h"
#import "YTHeader/GPBUnknownFieldSet.h"
#import "YTHeader/ELMPBShowActionSheetCommand.h"

@interface ELMPBCommand : GPBMessage
@end

@interface GPBUnknownFieldSet (NativeShare)
- (BOOL)hasField:(int32_t)number;
- (GPBUnknownField *)getField:(int32_t)number;
@end

@interface YTIUpdateShareSheetCommand : GPBMessage
@property (nonatomic, assign, readwrite) BOOL hasSerializedShareEntity;
@property (nonatomic, copy, readwrite) NSString *serializedShareEntity;
+ (GPBExtensionDescriptor*)updateShareSheetCommand;
@end

@interface YTIInnertubeCommandExtensionRoot : NSObject
+ (GPBExtensionDescriptor*)innertubeCommand;
@end

typedef NS_ENUM(int32_t, ShareEntityType) {
    ShareEntityFieldVideo = 1,
    ShareEntityFieldPlaylist = 2,
    ShareEntityFieldChannel = 3,
    ShareEntityFieldClip = 8
};

static inline NSString* extractIdWithFormat(GPBUnknownFieldSet *fields, int32_t fieldNumber, NSString *format) {
    if (![fields hasField:fieldNumber])
        return nil;
    GPBUnknownField *idField = [fields getField:fieldNumber];
    if ([idField.lengthDelimitedList count] != 1)
        return nil;
    NSString *id = [[NSString alloc] initWithData:[idField.lengthDelimitedList firstObject] encoding:NSUTF8StringEncoding];
    return [NSString stringWithFormat:format, id];
}

%hook ELMPBShowActionSheetCommand
- (void)executeWithCommandContext:(id)_context handler:(id)_handler {
    if (!ytlBool(@"nativeShare"))
        return %orig;

    if (!self.hasOnAppear)
        return %orig;
    GPBExtensionDescriptor *innertubeCommandDescriptor = [%c(YTIInnertubeCommandExtensionRoot) innertubeCommand];
    if (![self.onAppear hasExtension:innertubeCommandDescriptor])
        return %orig;
    YTICommand *innertubeCommand = [self.onAppear getExtension:innertubeCommandDescriptor];
    GPBExtensionDescriptor *updateShareSheetCommandDescriptor = [%c(YTIUpdateShareSheetCommand) updateShareSheetCommand];
    if(![innertubeCommand hasExtension:updateShareSheetCommandDescriptor])
        return %orig;
    YTIUpdateShareSheetCommand *updateShareSheetCommand = [innertubeCommand getExtension:updateShareSheetCommandDescriptor];
    if (!updateShareSheetCommand.hasSerializedShareEntity)
        return %orig;

    GPBMessage *shareEntity = [%c(GPBMessage) deserializeFromString:updateShareSheetCommand.serializedShareEntity];
    GPBUnknownFieldSet *fields = shareEntity.unknownFields;
    NSString *shareUrl;

    if ([fields hasField:ShareEntityFieldClip]) {
        GPBUnknownField *shareEntityClip = [fields getField:ShareEntityFieldClip];
        if ([shareEntityClip.lengthDelimitedList count] != 1)
            return %orig;
        GPBMessage *clipMessage = [%c(GPBMessage) parseFromData:[shareEntityClip.lengthDelimitedList firstObject] error:nil];
        shareUrl = extractIdWithFormat(clipMessage.unknownFields, 1, @"https://youtube.com/clip/%@");
    }

    if (!shareUrl)
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldChannel, @"https://youtube.com/channel/%@");

    if (!shareUrl) {
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldPlaylist, @"%@");
        if (shareUrl) {
            if (![shareUrl hasPrefix:@"PL"] && ![shareUrl hasPrefix:@"FL"])
                shareUrl = [shareUrl stringByAppendingString:@"&playnext=1"];
            shareUrl = [@"https://youtube.com/playlist?list=" stringByAppendingString:shareUrl];
        }
    }

    if (!shareUrl)
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldVideo, @"https://youtube.com/watch?v=%@");

    if (!shareUrl)
        return %orig;

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareUrl] applicationActivities:nil];
    [[%c(YTUIUtils) topViewControllerForPresenting] presentViewController:activityViewController animated:YES completion:^{}];
}
%end
