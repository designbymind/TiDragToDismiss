#import "TiDragtodismissGestureProxy.h"
#import "DTDCoordinator.h"
#import "TiViewProxy.h"
#import "TiUIView.h"
#import "TiUtils.h"
@protocol DTDScrollingView <NSObject>
- (UIScrollView *)tableView;
- (UIScrollView *)scrollView;
@end
static UIScrollView *DTDScrollView(UIView *view)
{
  if ([view isKindOfClass:UIScrollView.class]) return (UIScrollView *)view;
  // Titanium creates its underlying table lazily; it may not be in subviews yet
  // when Window.open is dispatched during a navigation push.
  if ([view respondsToSelector:@selector(tableView)]) {
    id table = [(id<DTDScrollingView>)view tableView];
    if ([table isKindOfClass:UIScrollView.class]) return table;
  }
  if ([view respondsToSelector:@selector(scrollView)]) {
    id scroll = [(id<DTDScrollingView>)view scrollView];
    if ([scroll isKindOfClass:UIScrollView.class]) return scroll;
  }
  for (UIView *child in view.subviews) {
    UIScrollView *scroll = DTDScrollView(child);
    if (scroll) return scroll;
  }
  return nil;
}
static CGFloat DTDNumber(NSDictionary *options, NSString *key, CGFloat fallback, CGFloat minimum)
{
  id value = options[key];
  if (!value) return fallback;
  if (![value isKindOfClass:NSNumber.class] || !isfinite([value doubleValue]) || [value doubleValue] < minimum)
    [NSException raise:NSInvalidArgumentException format:@"%@ must be a finite number >= %g", key, minimum];
  return [value doubleValue];
}
@implementation TiDragtodismissGestureProxy {
  DTDCoordinator *_coordinator;
  TiViewProxy *_target;
  TiViewProxy *_customIndicator;
  id _icon;
  id _indicatorColorValue;
}
- (void)configure:(NSDictionary *)options
{
  id target = options[@"scrollView"];
  if (![target isKindOfClass:TiViewProxy.class])
    [NSException raise:NSInvalidArgumentException format:@"scrollView must be a Titanium TableView, ListView, or vertical ScrollView."];
  UIView *targetView = [(TiViewProxy *)target view];
  [targetView layoutIfNeeded];
  UIScrollView *scroll = DTDScrollView(targetView);
  if (!scroll || !scroll.superview)
    [NSException raise:NSInvalidArgumentException format:@"scrollView must expose a native scrolling view. Create the gesture in Window.open after adding the view to its window."];
  _coordinator = [[DTDCoordinator alloc] init];
  _coordinator.threshold = DTDNumber(options, @"threshold", 120, 1);
  _coordinator.revealDistance = DTDNumber(options, @"revealDistance", 50, 1);
  if (_coordinator.threshold <= _coordinator.revealDistance)
    [NSException raise:NSInvalidArgumentException format:@"threshold must be greater than revealDistance."];
  _coordinator.activationDistance = DTDNumber(options, @"activationDistance", _coordinator.threshold * 1.2, 0);
  _coordinator.indicatorSize = DTDNumber(options, @"indicatorSize", 55, 20);
  _coordinator.bottomSpacing = DTDNumber(options, @"bottomSpacing", 12, 0);
  _coordinator.haptics = [TiUtils boolValue:options[@"haptics"] def:YES];
  _coordinator.enabled = [TiUtils boolValue:options[@"enabled"] def:YES];
  _coordinator.indicator.rotatesIcon = [TiUtils boolValue:options[@"rotatesIcon"] def:YES];
  [self setIndicatorColor:options[@"indicatorColor"] ?: NSNull.null];
  [self setIcon:options[@"icon"] ?: NSNull.null];
  id custom = options[@"indicatorView"];
  if (custom && custom != NSNull.null) {
    if (![custom isKindOfClass:TiViewProxy.class] || [(TiViewProxy *)custom view].superview)
      [NSException raise:NSInvalidArgumentException format:@"indicatorView must be an unattached Titanium View."];
    if (custom == target) [NSException raise:NSInvalidArgumentException format:@"indicatorView cannot be the scrollView."];
    _customIndicator = custom;
    [self rememberProxy:_customIndicator];
    _coordinator.indicator.customView = [_customIndicator view];
  }
  __weak TiDragtodismissGestureProxy *weakSelf = self;
  _coordinator.eventHandler = ^(NSString *name, NSDictionary *event) {
    TiDragtodismissGestureProxy *strongSelf = weakSelf;
    if ([strongSelf _hasListeners:name]) [strongSelf fireEvent:name withObject:event];
  };
  _coordinator.onRemoved = ^{ [weakSelf detach:nil]; };
  [_coordinator attachToScrollView:scroll];
  _target = target;
  [self rememberProxy:_target];
  if (_customIndicator) {
    [_coordinator.indicator layoutIfNeeded];
    [_customIndicator parentSizeWillChange];
  }
}
- (NSNumber *)progress { return @(_coordinator.progress); }
- (id)indicatorColor { return _indicatorColorValue ?: NSNull.null; }
- (void)setIndicatorColor:(id)value
{
  ENSURE_UI_THREAD_1_ARG(value);
  UIColor *color = nil;
  if (value && value != NSNull.null) {
    color = [[TiUtils colorValue:value] _color];
    if (!color) [NSException raise:NSInvalidArgumentException format:@"indicatorColor must be a valid Titanium color or null."];
  }
  _indicatorColorValue = value;
  _coordinator.indicator.indicatorColor = color;
}
- (NSNumber *)attached { return @(_coordinator.attached); }
- (NSNumber *)enabled { return @(_coordinator.enabled); }
- (void)setEnabled:(id)value
{
  ENSURE_UI_THREAD_1_ARG(value);
  _coordinator.enabled = [TiUtils boolValue:value];
}
- (id)icon { return _icon ?: NSNull.null; }
- (void)setIcon:(id)value
{
  ENSURE_UI_THREAD_1_ARG(value);
  UIImage *image = nil;
  BOOL template = YES;
  BOOL intrinsicSize = NO;
  if (!value || value == NSNull.null) image = [UIImage systemImageNamed:@"chevron.down"];
  else if ([value isKindOfClass:NSDictionary.class] && value[@"systemImage"]) {
    image = [DTDIndicatorView symbolImageWithOptions:value];
    intrinsicSize = value[@"size"] != nil;
  } else {
    if ([value isKindOfClass:NSString.class] && ([value hasPrefix:@"http:"] || [value hasPrefix:@"https:"]))
      [NSException raise:NSInvalidArgumentException format:@"icon accepts a local image path or Blob; download remote images before assigning them."];
    image = [TiUtils image:value proxy:self];
    template = NO;
    if (!image) [NSException raise:NSInvalidArgumentException format:@"icon must be a local image path, Blob, or { systemImage: 'symbol.name' }."];
  }
  _icon = value;
  _coordinator.indicator.icon = image;
  _coordinator.indicator.templateIcon = template;
  _coordinator.indicator.usesIntrinsicIconSize = intrinsicSize;
  [_coordinator.indicator setNeedsLayout];
}
- (void)detach:(id)unused
{
  ENSURE_UI_THREAD_0_ARGS;
  [_coordinator detach];
  if (_target) [self forgetProxy:_target];
  if (_customIndicator) [self forgetProxy:_customIndicator];
  _target = _customIndicator = nil;
}
- (void)_destroy
{
  [self detach:nil];
  [super _destroy];
}
@end
