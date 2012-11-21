#import <Foundation/Foundation.h>

@class GMMapView;

@interface GMOverlay : NSObject

@property (nonatomic) NSUInteger version;

@property (nonatomic) GMCoordinate coordinate;

@property (nonatomic) GMMapPoint mapPoint;
@property (nonatomic) GMMapBounds mapBounds;

/**
 Overlay visibility.

 +1: always visible
  0: the map view decides when the overlay is visible (default value)
 -1: hidden
 */
@property (nonatomic) int visibility;

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale;
- (void)updateBounds;

@end
