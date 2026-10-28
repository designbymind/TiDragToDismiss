#import "DTDCoordinator.h"
#import <objc/runtime.h>
static void *DTDObservation = &DTDObservation;
static void *DTDOwnerKey = &DTDOwnerKey;
@interface DTDWeakOwner : NSObject
@property (nonatomic, weak) DTDCoordinator *value;
@end
@implementation DTDWeakOwner
@end
@interface DTDOverlay : UIView
@property (nonatomic, copy) void (^onRemoved)(void);
@end
@implementation DTDOverlay {
  BOOL _wasInWindow;
}
- (void)didMoveToWindow
{
  [super didMoveToWindow];
  if (self.window) _wasInWindow = YES;
  else if (_wasInWindow && self.onRemoved) self.onRemoved();
}
@end
@implementation DTDCoordinator {
  UIScrollView *_scrollView;
  DTDOverlay *_overlay;
  BOOL _tracking;
  BOOL _eligible;
  BOOL _fired;
  BOOL _originalBounces;
  BOOL _originalAlwaysBounce;
  BOOL _lastDragging;
  BOOL _lastEligible;
  CGFloat _progress;
  CGFloat _distance;
  UISelectionFeedbackGenerator *_feedback;
}
- (instancetype)init
{
  if ((self = [super init])) {
    _threshold = 120;
    _revealDistance = 50;
    _activationDistance = 144;
    _indicatorSize = 55;
    _bottomSpacing = 12;
    _haptics = _enabled = YES;
    _indicator = [[DTDIndicatorView alloc] init];
  }
  return self;
}
- (BOOL)attached { return _scrollView != nil; }
- (CGFloat)progress { return _progress; }
- (CGFloat)bottomOffset
{
  UIEdgeInsets inset = _scrollView.adjustedContentInset;
  return MAX(-inset.top, _scrollView.contentSize.height - _scrollView.bounds.size.height + inset.bottom);
}
- (void)attachToScrollView:(UIScrollView *)scrollView
{
  DTDWeakOwner *existing = objc_getAssociatedObject(scrollView, DTDOwnerKey);
  if (existing.value) [NSException raise:NSInvalidArgumentException format:@"Only one ti.dragtodismiss gesture can attach to a scroll view. Detach the previous gesture first."];
  _scrollView = scrollView;
  DTDWeakOwner *owner = [[DTDWeakOwner alloc] init];
  owner.value = self;
  objc_setAssociatedObject(scrollView, DTDOwnerKey, owner, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  _originalBounces = scrollView.bounces;
  _originalAlwaysBounce = scrollView.alwaysBounceVertical;
  if (_enabled) scrollView.bounces = scrollView.alwaysBounceVertical = YES;
  _feedback = [[UISelectionFeedbackGenerator alloc] init];
  _overlay = [[DTDOverlay alloc] init];
  _overlay.userInteractionEnabled = NO;
  _overlay.clipsToBounds = YES;
  [_overlay addSubview:_indicator];
  __weak DTDCoordinator *weakSelf = self;
  _overlay.onRemoved = ^{
    DTDCoordinator *strongSelf = weakSelf;
    void (^callback)(void) = strongSelf.onRemoved;
    [strongSelf detach];
    if (callback) callback();
  };
  [scrollView.superview addSubview:_overlay];
  for (NSString *key in @[@"contentOffset", @"contentSize", @"bounds", @"contentInset", @"adjustedContentInset", @"frame"]) {
    [scrollView addObserver:self forKeyPath:key options:0 context:DTDObservation];
  }
  [scrollView.panGestureRecognizer addTarget:self action:@selector(handlePan:)];
  [self update];
}
- (void)setEnabled:(BOOL)enabled
{
  _enabled = enabled;
  _tracking = _eligible = NO;
  _scrollView.bounces = enabled ? YES : _originalBounces;
  _scrollView.alwaysBounceVertical = enabled ? YES : _originalAlwaysBounce;
  [self update];
}
- (void)handlePan:(UIPanGestureRecognizer *)pan
{
  if (!_enabled || !_scrollView) return;
  if (pan.state == UIGestureRecognizerStateBegan) {
    CGPoint velocity = [pan velocityInView:_scrollView];
    _tracking = YES;
    _fired = NO;
    _eligible = [self bottomOffset] - _scrollView.contentOffset.y <= _activationDistance && fabs(velocity.y) >= fabs(velocity.x);
    if (_eligible && _haptics) [_feedback prepare];
    [self update];
  } else if (pan.state == UIGestureRecognizerStateChanged) {
    [self update];
  } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled || pan.state == UIGestureRecognizerStateFailed) {
    // Freeze the last finger-driven value: momentum must never arm a dismissal.
    BOOL trigger = _tracking && _eligible && !_fired && _progress >= 1 && pan.state == UIGestureRecognizerStateEnded;
    _tracking = NO;
    if (trigger) {
      _fired = YES;
      DTDEventHandler handler = self.eventHandler;
      if (handler) handler(@"trigger", @{ @"progress": @1, @"distance": @(_distance), @"threshold": @(_threshold) });
    }
    [self update];
  }
}
- (void)observeValueForKeyPath:(NSString *)key ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context == DTDObservation) [self update];
  else [super observeValueForKeyPath:key ofObject:object change:change context:context];
}
- (void)update
{
  UIScrollView *scroll = _scrollView;
  if (!scroll) return;
  UIGestureRecognizerState state = scroll.panGestureRecognizer.state;
  if (_tracking && state != UIGestureRecognizerStateBegan && state != UIGestureRecognizerStateChanged) {
    // UIKit can start spring-back before our pan-ended target is called.
    // Preserve the last finger-driven sample until handlePan consumes it, so
    // the displayed progress/ready state and the release decision agree.
    return;
  }
  CGFloat distance = MAX(0, scroll.contentOffset.y - [self bottomOffset]);
  CGFloat next = 0, reveal = 0;
  if (_eligible && _enabled) {
    reveal = MIN(1, distance / _revealDistance);
    next = MIN(1, MAX(0, (distance - _revealDistance) / (_threshold - _revealDistance)));
    if (!_tracking) next = MIN(next, _progress);
  }
  BOOL becameReady = _tracking && next >= 1 && _progress < 1;
  BOOL eligible = _eligible && _enabled;
  BOOL changed = fabs(next - _progress) > 0.00001 || fabs(distance - _distance) > 0.1
      || _tracking != _lastDragging || eligible != _lastEligible;
  _progress = next;
  _distance = distance;
  _lastDragging = _tracking;
  _lastEligible = eligible;
  [_indicator renderProgress:next reveal:reveal];
  UIView *host = scroll.superview;
  if (host && _overlay.superview != host) [host addSubview:_overlay];
  _overlay.frame = [scroll convertRect:scroll.bounds toView:host];
  CGFloat bottomInset = MAX(scroll.adjustedContentInset.bottom, scroll.safeAreaInsets.bottom);
  CGFloat y = _overlay.bounds.size.height - bottomInset - _bottomSpacing - _indicatorSize + _revealDistance * (1 - reveal);
  _indicator.frame = CGRectMake((_overlay.bounds.size.width - _indicatorSize) / 2, y, _indicatorSize, _indicatorSize);
  if (becameReady && _haptics) { [_feedback selectionChanged]; [_feedback prepare]; }
  if (changed && self.eventHandler) {
    self.eventHandler(@"progress", @{ @"progress": @(next), @"distance": @(distance),
        @"ready": [NSNumber numberWithBool:next >= 1], @"dragging": @(_tracking),
        @"eligible": [NSNumber numberWithBool:eligible] });
  }
  if (!_tracking && distance < 0.5) _eligible = NO;
}
- (void)detach
{
  UIScrollView *scroll = _scrollView;
  if (!scroll) return;
  _overlay.onRemoved = nil;
  [scroll.panGestureRecognizer removeTarget:self action:@selector(handlePan:)];
  for (NSString *key in @[@"contentOffset", @"contentSize", @"bounds", @"contentInset", @"adjustedContentInset", @"frame"]) {
    [scroll removeObserver:self forKeyPath:key context:DTDObservation];
  }
  objc_setAssociatedObject(scroll, DTDOwnerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  scroll.bounces = _originalBounces;
  scroll.alwaysBounceVertical = _originalAlwaysBounce;
  [_overlay removeFromSuperview];
  _indicator.customView = nil;
  _overlay = nil;
  _scrollView = nil;
  _feedback = nil;
  _tracking = _eligible = NO;
  _progress = _distance = 0;
  self.eventHandler = nil;
  self.onRemoved = nil;
}
- (void)dealloc { [self detach]; }
@end
