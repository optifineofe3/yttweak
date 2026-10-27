#import <AVKit/AVKit.h>
#import "MLAVPIPPlayerLayerView.h"
#import "MLHAMSBDLSampleBufferRenderingView.h"

@interface MLPIPControllerImpl : NSObject <AVPictureInPictureControllerDelegate, AVPictureInPictureSampleBufferPlaybackDelegate>
@property (nonatomic, strong, readwrite) MLAVPIPPlayerLayerView *AVPlayerView;
@property (nonatomic, strong, readwrite) MLHAMSBDLSampleBufferRenderingView *HAMPlayerView;
- (AVPictureInPictureControllerContentSource *)newContentSource API_AVAILABLE(ios(15.0));
- (BOOL)isPictureInPictureSupported;
- (BOOL)pictureInPictureActive;
- (BOOL)contentSourceNeedsRefresh;
- (void)addPIPControllerObserver:(id)observer;
- (void)activatePiPController;
- (void)deactivatePiPController;
- (void)pictureInPictureControllerStartPlayback;
- (void)pictureInPictureControllerStopPlayback;
- (void)pause;
@end
