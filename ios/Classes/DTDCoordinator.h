#import <UIKit/UIKit.h>
#import "DTDIndicatorView.h"
typedef void (^DTDEventHandler)(NSString *name, NSDictionary *event);
/// Observes the existing pan recognizer and geometry without replacing its delegate.
@interface DTDCoordinator : NSObject
@property (nonatomic) CGFloat threshold;
@property (nonatomic) CGFloat revealDistance;
@property (nonatomic) CGFloat activationDistance;
@property (nonatomic) CGFloat indicatorSize;
@property (nonatomic) CGFloat bottomSpacing;
@property (nonatomic) BOOL haptics;
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property (nonatomic, readonly) CGFloat progress;
@property (nonatomic, readonly) BOOL attached;
@property (nonatomic, readonly) DTDIndicatorView *indicator;
@property (nonatomic, copy) DTDEventHandler eventHandler;
@property (nonatomic, copy) void (^onRemoved)(void);
- (void)attachToScrollView:(UIScrollView *)scrollView;
- (void)detach;
@end
