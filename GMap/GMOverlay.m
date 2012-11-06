#import "GMOverlay.h"
#import "GMMapView.h"

@implementation GMOverlay

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{

}

- (void)setCoordinate:(GMCoordinate)coordinate
{
    _coordinate = coordinate;
    _mapPoint = GMCoordinateToMapPoint(coordinate);
    [self updateBounds];
}

- (void)setMapPoint:(GMMapPoint)mapPoint
{
    _coordinate = GMMapPointToCoordinate(mapPoint);
    _mapPoint = mapPoint;
    [self updateBounds];
}

- (void)updateBounds
{
    self.mapBounds = GMMapBoundsMakeWithMapPoints(_mapPoint, _mapPoint);
}

@end
