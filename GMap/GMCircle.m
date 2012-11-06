#import "GMCircle.h"

@interface GMCircle ()

- (void)updateBounds;

@end

@implementation GMCircle

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{
    CGRect ctxRect = CGContextGetClipBoundingBox(ctx);

    if (!self.strokeColor && !self.fillColor)
        return;

    CGRect bounds = self.bounds;

    bounds.origin.x *= scale;
    bounds.origin.y *= scale;

    bounds.size.width *= scale;
    bounds.size.height *= scale;

    bounds.origin.x -= offset.x;
    bounds.origin.y -= offset.y;

    bounds.origin.y = ctxRect.size.height - bounds.origin.y - bounds.size.height;

    if (self.fillColor)
    {
        CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);

        CGContextFillEllipseInRect(ctx, bounds);
    }

    if (self.strokeColor && self.lineWidth > 0)
    {
        CGContextSetLineWidth(ctx, self.lineWidth);
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);

        CGContextStrokeEllipseInRect(ctx, bounds);
    }

    if (self.centerPointColor && self.centerPointSize > 0)
    {
        CGFloat w = self.centerPointSize;
        CGRect centerRect = CGRectMake(bounds.origin.x + bounds.size.width / 2 - w / 2.0,
                                       bounds.origin.y + bounds.size.height / 2 - w / 2.0,
                                       w, w);
        CGContextSetFillColorWithColor(ctx, self.centerPointColor.CGColor);

        CGContextFillEllipseInRect(ctx, centerRect);
    }
}

- (void)setRadius:(CGFloat)radius
{
    _radius = radius;
    [self updateBounds];
}

- (void)updateBounds
{
    CGPoint centerPoint = self.mapPoint;
    CGFloat normalizedRadius = self.radius / kEquatorLength;
    self.bounds = CGRectMake(centerPoint.x - normalizedRadius / 2.0, centerPoint.y - normalizedRadius / 2.0,
                             normalizedRadius, normalizedRadius);
}

@end
