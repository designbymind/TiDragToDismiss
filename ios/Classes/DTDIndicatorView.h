#import <UIKit/UIKit.h>
/// Noninteractive rendering of pull distance and armed state.
@interface DTDIndicatorView : UIView
+ (UIImage *)symbolImageWithOptions:(NSDictionary *)options;
@property (nonatomic, strong) UIImage *icon;
@property (nonatomic) BOOL usesIntrinsicIconSize;
@property (nonatomic) BOOL templateIcon;
@property (nonatomic) BOOL rotatesIcon;
@property (nonatomic, strong) UIColor *indicatorColor;
@property (nonatomic, strong) UIView *customView;
- (void)renderProgress:(CGFloat)progress reveal:(CGFloat)reveal;
@end
