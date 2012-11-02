#import "GMOverlay.h"
#import "GMMapView.h"

@implementation GMOverlay

- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale
{


    CGRect ctxRect = CGContextGetClipBoundingBox(ctx);

    CGRect rect = self.bounds;

    rect.origin.x *= scale;
    rect.origin.y *= scale;

    rect.size.width *= scale;
    rect.size.height *= scale;

    rect.origin.x -= offset.x;
    rect.origin.y -= offset.y;

    rect.origin.x = round(rect.origin.x);
    rect.origin.y = round(rect.origin.y);
    
    rect.size.width = round(rect.size.width);
    rect.size.height = round(rect.size.height);

    rect.origin.y = ctxRect.size.height - rect.origin.y - rect.size.height;


    CGContextSetLineWidth(ctx, 5);
    CGContextSetStrokeColorWithColor(ctx, [NSColor redColor].CGColor);
    CGContextStrokeRect(ctx, rect);
}

@end
