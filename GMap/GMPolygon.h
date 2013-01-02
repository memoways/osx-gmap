#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMPolygon : GMOverlay

- (void)addPointAtCoordinate:(GMCoordinate)coordinate;
- (void)addPointsAtCoordinates:(GMCoordinate *)coordinates count:(NSUInteger)coordinateCount;

- (void)removeAllPoints;

@property (nonatomic) BOOL shouldClose;
@property (nonatomic) NSColor *fillColor;

@property (nonatomic) GMFloat lineWidth;
@property (nonatomic) NSColor *strokeColor;

@end
