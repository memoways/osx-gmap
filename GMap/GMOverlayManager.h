#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMOverlayManager : NSObject

@property (readonly, nonatomic) NSArray *overlays;

- (void)addOverlay:(GMOverlay *)anOverlay;
- (void)removeOverlay:(GMOverlay *)anOverlay;

@end
