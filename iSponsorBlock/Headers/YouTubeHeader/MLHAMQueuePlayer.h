#import "MLHAMPlayer.h"
#import "MLHAMPlayerItem.h"
#import "MLPlayerDelegate.h"

@interface MLHAMQueuePlayer : MLHAMPlayer
@property (nonatomic, weak, readwrite) id <MLPlayerDelegate> delegate;
- (MLHAMPlayerItem *)currentPlayerItem;
- (void)internalSetRate;
- (void)maybeSwitchToAVPlayer;
@end
