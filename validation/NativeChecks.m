#import <UIKit/UIKit.h>
#import "DTDCoordinator.h"

// Deterministic state/geometry checks against the production UIKit coordinator.
// These synthesize recognizer states, not physical touches or tactile validation.
@interface DTDCoordinator (Testing)
- (void)handlePan:(UIPanGestureRecognizer *)pan;
@end
@interface TestPan : UIPanGestureRecognizer
@property (nonatomic) UIGestureRecognizerState testState;
@end
@implementation TestPan
- (UIGestureRecognizerState)state { return _testState; }
- (CGPoint)velocityInView:(UIView *)view { return CGPointMake(0, -200); }
@end
@interface TestScroll : UIScrollView
@property (nonatomic, strong) TestPan *testPan;
@end
@implementation TestScroll
- (UIPanGestureRecognizer *)panGestureRecognizer { return self.testPan ?: super.panGestureRecognizer; }
@end
@interface CheckScene : UIResponder <UIWindowSceneDelegate>
@end
@interface CheckApp : UIResponder <UIApplicationDelegate>
@property (nonatomic, strong) UIWindow *window;
@end
@implementation CheckApp
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)options
{
  return YES;
}
- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options
{
  UISceneConfiguration *configuration = [[UISceneConfiguration alloc] initWithName:@"Checks" sessionRole:session.role];
  configuration.delegateClass = CheckScene.class;
  return configuration;
}
- (void)runChecks
{
  NSMutableArray *results = [NSMutableArray array];
  void (^check)(BOOL, NSString *) = ^(BOOL ok, NSString *label) {
    [results addObject:@{ @"passed": @(ok), @"label": label }];
    NSLog(@"DTD %@: %@", ok ? @"PASS" : @"FAIL", label);
  };
  @try {
    UIImage *smallSymbol = [DTDIndicatorView symbolImageWithOptions:@{ @"systemImage": @"arrow.uturn.backward", @"size": @12 }];
    UIImage *boldSymbol = [DTDIndicatorView symbolImageWithOptions:@{ @"systemImage": @"arrow.uturn.backward", @"size": @24, @"weight": @"bold" }];
    UIImage *largeSymbol = [DTDIndicatorView symbolImageWithOptions:@{ @"systemImage": @"arrow.uturn.backward", @"size": @40, @"weight": @"light" }];
    check(boldSymbol.size.height > smallSymbol.size.height && largeSymbol.size.height > boldSymbol.size.height, @"SF Symbol point size changes the rendered glyph size");
    BOOL allWeights = YES;
    for (NSString *weight in @[@"ultraLight", @"thin", @"light", @"regular", @"medium", @"semibold", @"bold", @"heavy", @"black", @"BOLD"]) {
      allWeights = allWeights && [DTDIndicatorView symbolImageWithOptions:@{ @"systemImage": @"arrow.uturn.backward", @"weight": weight }] != nil;
    }
    check(allWeights, @"all documented symbol weights are accepted");
    UIGraphicsImageRenderer *glyphRenderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(64, 64)];
    UIImage *regularSymbol = [DTDIndicatorView symbolImageWithOptions:@{ @"systemImage": @"arrow.uturn.backward", @"size": @24, @"weight": @"regular" }];
    UIImage *regularPixels = [glyphRenderer imageWithActions:^(UIGraphicsImageRendererContext *context) { [regularSymbol drawAtPoint:CGPointMake(8, 8)]; }];
    UIImage *boldPixels = [glyphRenderer imageWithActions:^(UIGraphicsImageRendererContext *context) { [boldSymbol drawAtPoint:CGPointMake(8, 8)]; }];
    check(![UIImagePNGRepresentation(regularPixels) isEqual:UIImagePNGRepresentation(boldPixels)], @"bold weight changes rendered pixels from regular");
    NSArray *invalidSymbols = @[
      @{ @"systemImage": @"arrow.uturn.backward", @"size": @0 },
      @{ @"systemImage": @"arrow.uturn.backward", @"size": @(-1) },
      @{ @"systemImage": @"arrow.uturn.backward", @"size": @"24" },
      @{ @"systemImage": @"arrow.uturn.backward", @"size": @(NAN) },
      @{ @"systemImage": @"arrow.uturn.backward", @"size": @(INFINITY) },
      @{ @"systemImage": @"arrow.uturn.backward", @"weight": @"invalid" },
      @{ @"systemImage": @"arrow.uturn.backward", @"weight": @24 },
      @{ @"systemImage": @"not.a.real.symbol.name" }
    ];
    BOOL rejectedInvalidSymbols = YES;
    for (NSDictionary *options in invalidSymbols) {
      BOOL rejected = NO;
      @try { [DTDIndicatorView symbolImageWithOptions:options]; }
      @catch (NSException *exception) { rejected = YES; }
      rejectedInvalidSymbols = rejectedInvalidSymbols && rejected;
    }
    check(rejectedInvalidSymbols, @"invalid sizes, weights, and symbol names are rejected");
    DTDIndicatorView *symbolIndicator = [[DTDIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 55, 55)];
    symbolIndicator.icon = boldSymbol;
    symbolIndicator.usesIntrinsicIconSize = YES;
    [symbolIndicator layoutIfNeeded];
    UIImageView *iconView;
    for (UIView *child in symbolIndicator.subviews) if ([child isKindOfClass:UIImageView.class]) iconView = (UIImageView *)child;
    check(CGSizeEqualToSize(iconView.bounds.size, boldSymbol.size), @"explicit point size is not squeezed into the legacy icon box");
    symbolIndicator.usesIntrinsicIconSize = NO;
    [symbolIndicator setNeedsLayout];
    [symbolIndicator layoutIfNeeded];
    check(fabs(iconView.bounds.size.width - 55 * 0.36) < 0.001, @"omitted symbol size preserves legacy icon bounds");
    UIColor *blue = [UIColor colorWithRed:0 green:122.0/255 blue:1 alpha:1];
    UIColor *orange = UIColor.systemOrangeColor;
    symbolIndicator.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    [symbolIndicator renderProgress:0.65 reveal:1];
    symbolIndicator.indicatorColor = blue;
    CAShapeLayer *arc;
    for (CALayer *layer in symbolIndicator.layer.sublayers) if ([layer isKindOfClass:CAShapeLayer.class]) { arc = (CAShapeLayer *)layer; break; }
    check(CGColorEqualToColor(arc.strokeColor, blue.CGColor) && [iconView.tintColor isEqual:blue], @"runtime color immediately repaints stationary ring and symbol");
    [symbolIndicator renderProgress:1 reveal:1];
    symbolIndicator.indicatorColor = orange;
    UIView *fill = symbolIndicator.subviews.firstObject;
    check([fill.backgroundColor isEqual:[orange resolvedColorWithTraitCollection:symbolIndicator.traitCollection]] && CGColorEqualToColor(arc.strokeColor, [orange resolvedColorWithTraitCollection:symbolIndicator.traitCollection].CGColor), @"runtime color immediately repaints a fully armed indicator");
    symbolIndicator.indicatorColor = nil;
    check(CGColorEqualToColor(arc.strokeColor, [UIColor.labelColor resolvedColorWithTraitCollection:symbolIndicator.traitCollection].CGColor), @"nil restores automatic semantic color immediately");
    // Render theme/color changes without another progress or geometry update.
    UIGraphicsImageRenderer *colorRenderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(480, 110)];
    UIImage *colorPreview = [colorRenderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
      NSArray *colors = @[blue, orange, NSNull.null, NSNull.null];
      NSArray *captions = @[@"Light / blue", @"Dark / orange", @"Auto / light", @"Auto / dark"];
      DTDIndicatorView *view = [[DTDIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 55, 55)];
      view.icon = boldSymbol;
      view.usesIntrinsicIconSize = YES;
      view.rotatesIcon = NO;
      [self.window.rootViewController.view addSubview:view];
      [view renderProgress:0.65 reveal:1];
      [view layoutIfNeeded];
      for (NSUInteger index = 0; index < colors.count; index++) {
        BOOL dark = index == 1 || index == 3;
        view.overrideUserInterfaceStyle = dark ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
        if (index != 3) view.indicatorColor = colors[index] == NSNull.null ? nil : colors[index];
        UIColor *background = dark ? UIColor.blackColor : UIColor.whiteColor;
        [background setFill];
        UIRectFill(CGRectMake(index * 120, 0, 120, 110));
        CGContextSaveGState(context.CGContext);
        CGContextTranslateCTM(context.CGContext, index * 120 + 32.5, 12.5);
        [view.layer renderInContext:context.CGContext];
        CGContextRestoreGState(context.CGContext);
        [captions[index] drawAtPoint:CGPointMake(index * 120 + 12, 88) withAttributes:@{
          NSFontAttributeName: [UIFont systemFontOfSize:12], NSForegroundColorAttributeName: dark ? UIColor.whiteColor : UIColor.blackColor }];
        if (index >= 2) {
          UIColor *expected = [UIColor.labelColor resolvedColorWithTraitCollection:view.traitCollection];
          CAShapeLayer *viewArc;
          for (CALayer *layer in view.layer.sublayers) if ([layer isKindOfClass:CAShapeLayer.class]) { viewArc = (CAShapeLayer *)layer; break; }
          check(CGColorEqualToColor(viewArc.strokeColor, expected.CGColor), dark ? @"automatic color resolves correctly in dark mode" : @"automatic color resolves correctly in light mode");
        }
      }
      [view removeFromSuperview];
    }];
    NSString *colorPreviewPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"color-preview.png"];
    [UIImagePNGRepresentation(colorPreview) writeToFile:colorPreviewPath atomically:YES];
    // Render the actual production indicator so sizing/weight can be inspected visually.
    UIGraphicsImageRenderer *previewRenderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(360, 110)];
    UIImage *preview = [previewRenderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
      [UIColor.whiteColor setFill];
      UIRectFill(CGRectMake(0, 0, 360, 110));
      NSArray *images = @[[UIImage systemImageNamed:@"arrow.uturn.backward"], boldSymbol, largeSymbol];
      NSArray *captions = @[@"Default", @"24 pt bold", @"40 pt light"];
      for (NSUInteger index = 0; index < images.count; index++) {
        DTDIndicatorView *view = [[DTDIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 55, 55)];
        view.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        view.indicatorColor = UIColor.blackColor;
        view.rotatesIcon = NO;
        view.icon = images[index];
        view.usesIntrinsicIconSize = index != 0;
        [view renderProgress:0.65 reveal:1];
        [view layoutIfNeeded];
        CGContextSaveGState(context.CGContext);
        CGContextTranslateCTM(context.CGContext, index * 120 + 32.5, 12.5);
        [view.layer renderInContext:context.CGContext];
        CGContextRestoreGState(context.CGContext);
        [captions[index] drawAtPoint:CGPointMake(index * 120 + 20, 88)
            withAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:13], NSForegroundColorAttributeName: UIColor.blackColor }];
      }
    }];
    NSString *previewPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"symbol-preview.png"];
    [UIImagePNGRepresentation(preview) writeToFile:previewPath atomically:YES];
    UIView *host = self.window.rootViewController.view;
    TestScroll *scroll = [[TestScroll alloc] initWithFrame:CGRectMake(0, 0, 390, 600)];
    scroll.testPan = [[TestPan alloc] init];
    scroll.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    scroll.contentSize = CGSizeMake(390, 1200);
    scroll.contentInset = UIEdgeInsetsMake(20, 0, 30, 0);
    scroll.bounces = NO;
    scroll.alwaysBounceVertical = NO;
    [host addSubview:scroll];
    id originalDelegate = scroll.delegate;
    DTDCoordinator *coordinator = [[DTDCoordinator alloc] init];
    coordinator.haptics = NO;
    __block NSInteger triggers = 0;
    __block NSDictionary *lastEvent;
    coordinator.eventHandler = ^(NSString *name, NSDictionary *event) {
      if ([name isEqual:@"trigger"]) triggers++;
      else lastEvent = event;
    };
    [coordinator attachToScrollView:scroll];
    check(coordinator.attached && scroll.bounces && scroll.alwaysBounceVertical, @"attach enables vertical bounce");
    check(scroll.delegate == originalDelegate, @"preserves original scroll delegate");
    TestPan *pan = scroll.testPan;
    void (^begin)(CGFloat) = ^(CGFloat offset) {
      scroll.contentOffset = CGPointMake(0, offset);
      pan.testState = UIGestureRecognizerStateBegan;
      [coordinator handlePan:pan];
    };
    void (^move)(CGFloat) = ^(CGFloat offset) {
      pan.testState = UIGestureRecognizerStateChanged;
      scroll.contentOffset = CGPointMake(0, offset);
      [coordinator handlePan:pan];
    };
    void (^end)(UIGestureRecognizerState) = ^(UIGestureRecognizerState state) {
      pan.testState = state;
      [coordinator handlePan:pan];
    };
    CGFloat bottom = 630;
    // UIKit can begin bounce-back after changing the pan state to Ended but
    // before invoking our added target. The displayed ready sample must win.
    begin(bottom);
    move(bottom + 122);
    check([lastEvent[@"ready"] boolValue] && coordinator.progress == 1, @"just beyond threshold reports ready");
    pan.testState = UIGestureRecognizerStateEnded;
    scroll.contentOffset = CGPointMake(0, bottom + 117);
    check(coordinator.progress == 1, @"terminal-state geometry cannot overwrite the displayed ready sample");
    end(UIGestureRecognizerStateEnded);
    check(triggers == 1, @"ready release triggers despite bounce-back arriving before the release target");
    scroll.contentOffset = CGPointMake(0, bottom);
    begin(bottom);
    move(bottom + 122);
    move(bottom + 117);
    check(![lastEvent[@"ready"] boolValue] && coordinator.progress < 1, @"real finger reversal below threshold disarms");
    pan.testState = UIGestureRecognizerStateEnded;
    scroll.contentOffset = CGPointMake(0, bottom + 130);
    end(UIGestureRecognizerStateEnded);
    check(triggers == 1, @"post-release geometry cannot rearm a deliberately cancelled pull");
    scroll.contentOffset = CGPointMake(0, bottom);
    triggers = 0;
    begin(bottom);
    move(bottom + 50);
    check(coordinator.progress == 0, @"first 50 points reveal without filling");
    move(bottom + 85);
    check(fabs(coordinator.progress - 0.5) < 0.001, @"85 point pull gives progress 0.5");
    move(bottom + 120);
    check(coordinator.progress == 1 && triggers == 0, @"full threshold arms without triggering while held");
    move(bottom + 85);
    check(fabs(coordinator.progress - 0.5) < 0.001, @"reverse drag reduces progress from 1 to 0.5");
    end(UIGestureRecognizerStateEnded);
    check(triggers == 0, @"release after backing off cancels");
    scroll.contentOffset = CGPointMake(0, bottom);
    check(coordinator.progress == 0, @"bounce back resets progress to zero");
    begin(bottom);
    move(bottom + 120);
    end(UIGestureRecognizerStateEnded);
    check(triggers == 1, @"release while armed triggers exactly once");
    end(UIGestureRecognizerStateEnded);
    check(triggers == 1, @"duplicate release does not retrigger");
    scroll.contentOffset = CGPointMake(0, bottom);
    begin(bottom);
    move(bottom + 140);
    end(UIGestureRecognizerStateCancelled);
    check(triggers == 1, @"system cancellation never triggers");
    scroll.contentOffset = CGPointMake(0, bottom);
    begin(100);
    move(bottom + 150);
    end(UIGestureRecognizerStateEnded);
    check(triggers == 1 && coordinator.progress == 0, @"long fling from far above bottom is ineligible");
    scroll.contentOffset = CGPointMake(0, bottom);
    begin(bottom);
    move(bottom + 70);
    end(UIGestureRecognizerStateEnded);
    scroll.contentOffset = CGPointMake(0, bottom + 180);
    check(triggers == 1 && coordinator.progress < 1, @"post-release momentum cannot arm or trigger");
    scroll.contentOffset = CGPointMake(0, bottom);
    begin(bottom - 100);
    move(bottom + 120);
    end(UIGestureRecognizerStateEnded);
    check(triggers == 2, @"gesture may begin within the near-bottom activation distance");
    coordinator.enabled = NO;
    check(!scroll.bounces && !scroll.alwaysBounceVertical, @"disable restores original bounce policy");
    begin(bottom);
    move(bottom + 150);
    end(UIGestureRecognizerStateEnded);
    check(triggers == 2 && coordinator.progress == 0, @"disabled gestures cannot trigger");
    coordinator.enabled = YES;
    scroll.contentSize = CGSizeMake(390, 100);
    // Short content rests at -top inset, not contentHeight - viewportHeight.
    begin(-20);
    move(100);
    check(coordinator.progress == 1, @"short content uses adjusted top as bottom boundary");
    end(UIGestureRecognizerStateEnded);
    check(triggers == 3, @"short table can trigger");
    DTDCoordinator *second = [[DTDCoordinator alloc] init];
    BOOL duplicateRejected = NO;
    @try { [second attachToScrollView:scroll]; }
    @catch (NSException *exception) { duplicateRejected = YES; }
    check(duplicateRejected, @"rejects a second attachment to the same scroll view");
    [coordinator detach];
    [coordinator detach];
    check(!coordinator.attached && !scroll.bounces && !scroll.alwaysBounceVertical, @"detach is idempotent and restores policy");
    scroll.contentOffset = CGPointMake(0, 0);
    check(coordinator.progress == 0, @"detached geometry mutations have no callbacks");
    [second attachToScrollView:scroll];
    check(second.attached, @"reattaches after previous owner detaches");
    [second detach];
    DTDCoordinator *automatic = [[DTDCoordinator alloc] init];
    [automatic attachToScrollView:scroll];
    [host removeFromSuperview];
    self.window.hidden = YES;
    check(!automatic.attached, @"leaving the window automatically removes observations");
    check([lastEvent[@"progress"] doubleValue] >= 0 && [lastEvent[@"progress"] doubleValue] <= 1, @"event progress stays within 0 to 1");
  } @catch (NSException *exception) {
    check(NO, exception.description);
  }
  NSData *data = [NSJSONSerialization dataWithJSONObject:results options:NSJSONWritingPrettyPrinted error:nil];
  NSString *file = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"checks.json"];
  [data writeToFile:file atomically:YES];
  NSLog(@"DTD checks written to %@", file);
}
@end
@implementation CheckScene
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)options
{
  CheckApp *app = (CheckApp *)UIApplication.sharedApplication.delegate;
  app.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
  app.window.rootViewController = [[UIViewController alloc] init];
  [app.window makeKeyAndVisible];
  dispatch_async(dispatch_get_main_queue(), ^{ [app runChecks]; });
}
@end
int main(int argc, char *argv[]) {
  @autoreleasepool { return UIApplicationMain(argc, argv, nil, NSStringFromClass(CheckApp.class)); }
}
