#import <Foundation/Foundation.h>

@class GMMapView;

@interface GMOverlay : NSObject

@property (nonatomic) NSUInteger version;

@property (nonatomic) id representedObject;

@property (nonatomic) GMCoordinate coordinate;

@property (nonatomic) GMMapPoint mapPoint;
@property (nonatomic) GMMapBounds mapBounds;

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale;
- (void)updateBounds;

@end
