#import "DTDIndicatorView.h"
@implementation DTDIndicatorView {
  CAShapeLayer *_leftArc;
  CAShapeLayer *_rightArc;
  UIView *_fill;
  UIImageView *_image;
  CGFloat _progress;
  CGFloat _reveal;
}
+ (UIImage *)symbolImageWithOptions:(NSDictionary *)options
{
  NSString *name = options[@"systemImage"];
  if (![name isKindOfClass:NSString.class]) {
    [NSException raise:NSInvalidArgumentException format:@"icon.systemImage must be an SF Symbol name."];
  }
  UIImageSymbolConfiguration *configuration = nil;
  id size = options[@"size"];
  if (size) {
    if (![size isKindOfClass:NSNumber.class] || !isfinite([size doubleValue]) || [size doubleValue] < 1) {
      [NSException raise:NSInvalidArgumentException format:@"icon.size must be a finite number >= 1 point."];
    }
    configuration = [UIImageSymbolConfiguration configurationWithPointSize:[size doubleValue]];
  }
  id weight = options[@"weight"];
  if (weight) {
    NSDictionary *weights = @{
      @"ultralight": @(UIImageSymbolWeightUltraLight), @"thin": @(UIImageSymbolWeightThin),
      @"light": @(UIImageSymbolWeightLight), @"regular": @(UIImageSymbolWeightRegular),
      @"medium": @(UIImageSymbolWeightMedium), @"semibold": @(UIImageSymbolWeightSemibold),
      @"bold": @(UIImageSymbolWeightBold), @"heavy": @(UIImageSymbolWeightHeavy),
      @"black": @(UIImageSymbolWeightBlack)
    };
    NSNumber *nativeWeight = [weight isKindOfClass:NSString.class] ? weights[[weight lowercaseString]] : nil;
    if (!nativeWeight) {
      [NSException raise:NSInvalidArgumentException format:@"icon.weight must be ultraLight, thin, light, regular, medium, semibold, bold, heavy, or black."];
    }
    UIImageSymbolConfiguration *weightConfiguration = [UIImageSymbolConfiguration configurationWithWeight:nativeWeight.integerValue];
    configuration = configuration ? [configuration configurationByApplyingConfiguration:weightConfiguration] : weightConfiguration;
  }
  UIImage *image = configuration ? [UIImage systemImageNamed:name withConfiguration:configuration] : [UIImage systemImageNamed:name];
  if (!image) [NSException raise:NSInvalidArgumentException format:@"Unknown SF Symbol: %@", name];
  return image;
}
- (instancetype)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    self.userInteractionEnabled = NO;
    self.accessibilityElementsHidden = YES;
    _templateIcon = _rotatesIcon = YES;
    _fill = [[UIView alloc] init];
    [self addSubview:_fill];
    _leftArc = [CAShapeLayer layer];
    _rightArc = [CAShapeLayer layer];
    for (CAShapeLayer *arc in @[_leftArc, _rightArc]) {
      arc.fillColor = UIColor.clearColor.CGColor;
      arc.lineWidth = 3;
      arc.lineCap = kCALineCapRound;
      [self.layer addSublayer:arc];
    }
    _image = [[UIImageView alloc] init];
    _image.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_image];
    _icon = [UIImage systemImageNamed:@"chevron.down"];
    [self registerForTraitChanges:@[UITraitUserInterfaceStyle.class, UITraitAccessibilityContrast.class]
        withHandler:^(__kindof DTDIndicatorView *view, UITraitCollection *previous) {
          [view renderProgress:view->_progress reveal:view->_reveal];
        }];
  }
  return self;
}
- (void)setIndicatorColor:(UIColor *)color
{
  _indicatorColor = color;
  // Theme changes must repaint a stationary or fully armed indicator as well.
  [self renderProgress:_progress reveal:_reveal];
}
- (void)setCustomView:(UIView *)view
{
  if (_customView == view) return;
  [_customView removeFromSuperview];
  _customView = view;
  if (view) [self addSubview:view];
  [self setNeedsLayout];
}
- (void)layoutSubviews
{
  [super layoutSubviews];
  CGFloat size = MIN(self.bounds.size.width, self.bounds.size.height);
  _fill.frame = self.bounds;
  _fill.layer.cornerRadius = size / 2;
  CGSize iconSize = _usesIntrinsicIconSize ? _icon.size : CGSizeMake(size * 0.36, size * 0.36);
  _image.bounds = (CGRect){ CGPointZero, iconSize };
  _image.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  _customView.frame = self.bounds;
  CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
  CGFloat radius = MAX(0, size / 2 - 5);
  _leftArc.path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:M_PI_2 endAngle:M_PI_2 + M_PI clockwise:YES].CGPath;
  _rightArc.path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:M_PI_2 endAngle:M_PI_2 - M_PI clockwise:NO].CGPath;
  [self renderProgress:_progress reveal:_reveal];
}
- (void)renderProgress:(CGFloat)progress reveal:(CGFloat)reveal
{
  BOOL becameReady = progress >= 1 && _progress < 1;
  _progress = progress;
  _reveal = reveal;
  self.alpha = reveal;
  BOOL custom = _customView != nil;
  UIColor *color = [(_indicatorColor ?: UIColor.labelColor) resolvedColorWithTraitCollection:self.traitCollection];
  [CATransaction begin];
  [CATransaction setDisableActions:YES];
  _leftArc.hidden = _rightArc.hidden = custom;
  _leftArc.strokeEnd = _rightArc.strokeEnd = progress;
  _leftArc.strokeColor = _rightArc.strokeColor = color.CGColor;
  _fill.backgroundColor = color;
  _fill.hidden = custom || progress < 1;
  _image.hidden = custom;
  _image.image = [_icon imageWithRenderingMode:_templateIcon ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal];
  _image.tintColor = progress >= 1 ? UIColor.systemBackgroundColor : color;
  _image.transform = CGAffineTransformMakeRotation(_rotatesIcon ? progress * M_PI_2 : 0);
  [CATransaction commit];
  if (becameReady && !UIAccessibilityIsReduceMotionEnabled()) {
    CAKeyframeAnimation *bounce = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    bounce.values = @[@1, @1.1, @1];
    bounce.duration = 0.3;
    [self.layer addAnimation:bounce forKey:@"ready"];
  }
}
@end
