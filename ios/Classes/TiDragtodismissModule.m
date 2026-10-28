#import "TiDragtodismissModule.h"
#import "TiDragtodismissGestureProxy.h"
#import "TiUtils.h"
@implementation TiDragtodismissModule
- (id)moduleGUID { return @"eec13487-1a6c-4568-8f1b-84c5170146ee"; }
- (NSString *)moduleId { return @"ti.dragtodismiss"; }
- (id)createGesture:(id)args
{
  ENSURE_UI_THREAD_1_ARG(args);
  ENSURE_SINGLE_ARG(args, NSDictionary);
  TiDragtodismissGestureProxy *gesture = [[TiDragtodismissGestureProxy alloc] _initWithPageContext:[self executionContext]];
  [gesture configure:args];
  return gesture;
}
@end
