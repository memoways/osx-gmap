#import <Foundation/Foundation.h>

@class GMMapView;

@interface GMOverlay : NSObject

@property (nonatomic) GMCoordinate coordinate;

@property (nonatomic) CGPoint mapPoint;
@property (nonatomic) CGRect bounds;

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale;
- (void)updateBounds;

@end
