#import "GMPolygon.h"

@implementation GMPolygon

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.points = NSMutableArray.new;

    return self;
}

- (void)addPointAtCoordinate:(GMCoordinate)coordinate
{
    CGPoint pt = GMCoordinateToPoint(coordinate);

    CGRect rect = CGRectMake(pt.x, pt.y, 0, 0);

    if (self.points.count)
        self.bounds = CGRectUnion(self.bounds, rect);
    else
        self.bounds = rect;

    [self.points addObject:[NSValue valueWithPoint:pt]];
}

@end
