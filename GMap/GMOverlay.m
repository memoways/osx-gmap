#import "GMOverlay.h"
#import "GMMapView.h"

@implementation GMOverlay

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{

}

- (void)setCoordinate:(GMCoordinate)coordinate
{
    _coordinate = coordinate;
    _mapPoint = GMCoordinateToPoint(coordinate);
    [self updateBounds];
}

- (void)setMapPoint:(CGPoint)mapPoint
{
    _coordinate = GMPointToCoordinate(mapPoint);
    _mapPoint = mapPoint;
    [self updateBounds];
}

- (void)updateBounds
{
    self.bounds = CGRectMake(_mapPoint.x, _mapPoint.y, 0, 0);
}

@end
