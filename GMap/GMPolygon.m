#import "GMPolygon.h"

@implementation GMPolygon

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.points = NSMutableArray.new;
    self.lineWidth = 5;

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


- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{
    CGRect ctxRect = CGContextGetClipBoundingBox(ctx);

    if (!self.strokeColor && !self.fillColor)
        return;

    CGMutablePathRef path = CGPathCreateMutable();

    BOOL first = YES;

    for (NSValue *point in self.points)
    {
        CGPoint pt;
        [point getValue:&pt];


        pt.x *= scale;
        pt.y *= scale;

        pt.x -= offset.x;
        pt.y -= offset.y;

        pt.y = ctxRect.size.height - pt.y;

        if (first)
            CGPathMoveToPoint(path, nil, pt.x, pt.y);
        else
            CGPathAddLineToPoint(path, nil, pt.x, pt.y);

        first = NO;
    }

    CGContextSetLineJoin(ctx, kCGLineJoinRound);
    CGContextSetLineCap(ctx, kCGLineCapRound);

    if (self.fillColor)
    {
        CGContextAddPath(ctx, path);
        CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);

        CGContextFillPath(ctx);
    }

    if (self.strokeColor && self.lineWidth > 0)
    {
        CGContextAddPath(ctx, path);

        if (self.shouldClose)
            CGContextClosePath(ctx);

        CGContextSetLineWidth(ctx, self.lineWidth);
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);

        CGContextStrokePath(ctx);
    }

    CGPathRelease(path);
}


@end
