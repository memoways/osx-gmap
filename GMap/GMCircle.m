#import "GMCircle.h"

@interface GMCircle ()

- (void)updateBounds;

@end

@implementation GMCircle

+ (NSSet *)keyPathsForValuesAffectingVersion
{
    NSMutableSet *set = [NSMutableSet setWithSet:super.keyPathsForValuesAffectingVersion];

    return [set setByAddingObjectsFromArray:@[@"radius", @"fillColor", @"lineWidth", @"strokeColor", @"centerPointSize", @"centerPointColor"]];
}

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{
    CGRect ctxRect = CGContextGetClipBoundingBox(ctx);

    if (!self.strokeColor && !self.fillColor)
        return;

    GMMapBounds bounds = self.mapBounds;

    CGRect rect = CGRectMake(bounds.topLeft.x, bounds.topLeft.y,
                             bounds.bottomRight.x - bounds.topLeft.x, bounds.bottomRight.y - bounds.topLeft.y);

    rect.origin.x *= scale;
    rect.origin.y *= scale;

    rect.size.width *= scale;
    rect.size.height *= scale;

    rect.origin.x -= offset.x;
    rect.origin.y -= offset.y;

    rect.origin.y = ctxRect.size.height - rect.origin.y - rect.size.height;

    if (self.fillColor)
    {
        CGContextSetFillColorWithColor(ctx, self.fillColor.CGColor);

        CGContextFillEllipseInRect(ctx, rect);
    }

    if (self.strokeColor && self.lineWidth > 0)
    {
        CGContextSetLineWidth(ctx, self.lineWidth);
        CGContextSetStrokeColorWithColor(ctx, self.strokeColor.CGColor);

        CGContextStrokeEllipseInRect(ctx, rect);
    }

    if (self.centerPointColor && self.centerPointSize > 0)
    {
        CGFloat w = self.centerPointSize;
        CGRect centerRect = CGRectMake(rect.origin.x + rect.size.width / 2 - w / 2.0,
                                       rect.origin.y + rect.size.height / 2 - w / 2.0,
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
    GMMapPoint centerPoint = self.mapPoint;
    CGFloat normalizedHalfRadius = self.radius / kEquatorLength / 2.0;

    self.mapBounds = GMMapBoundsMake(centerPoint.x - normalizedHalfRadius, centerPoint.y - normalizedHalfRadius,
                                     centerPoint.x + normalizedHalfRadius, centerPoint.y + normalizedHalfRadius);
}

@end
