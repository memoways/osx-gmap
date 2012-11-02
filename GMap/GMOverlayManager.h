#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMOverlayManager : NSObject


- (void)addOverlay:(GMOverlay *)anOverlay;
- (void)removeOverlay:(GMOverlay *)anOverlay;

- (NSArray *)overlaysWithinBounds:(CGRect)bounds;

@end

@interface GMOverlayManager (Collection)

@property (readonly, nonatomic) NSArray *overlays;

@end