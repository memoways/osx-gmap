#import "GMOverlay.h"
#import "GMMapView.h"

@implementation GMOverlay

+ (NSSet *)keyPathsForValuesAffectingVersion
{
    return [NSSet setWithObjects:@"bounds", @"coordinate", @"mapPoint", @"mapBounds", nil];
}

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{

}

- (void)setCoordinate:(GMCoordinate)coordinate
{
    _coordinate = coordinate;
    [self willChangeValueForKey:@"mapPoint"];
    _mapPoint = GMCoordinateToMapPoint(coordinate);
    [self didChangeValueForKey:@"mapPoint"];
    [self updateBounds];
}

- (void)setMapPoint:(GMMapPoint)mapPoint
{
    [self willChangeValueForKey:@"coordinate"];
    _coordinate = GMMapPointToCoordinate(mapPoint);
    [self didChangeValueForKey:@"coordinate"];
    _mapPoint = mapPoint;
    [self updateBounds];
}

- (void)updateBounds
{
    self.mapBounds = GMMapBoundsMakeWithMapPoints(_mapPoint, _mapPoint);
}


@end
