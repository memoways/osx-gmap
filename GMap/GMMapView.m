#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMTileManager.h"

@interface GMMapView ()


@end

@implementation GMMapView


- (id)initWithFrame:(NSRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.tileManager = [GMTileManager new];

    [self addObserver:self forKeyPath:@"zoomLevel" options:0 context:nil];
    [self addObserver:self forKeyPath:@"centerCoordinate" options:0 context:nil];


    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(CGRect)rect
{
    CGFloat kTileSize = 256.0;

    CGContextRef ctx = NSGraphicsContext.currentContext.graphicsPort;
    CGPoint center = GMCoordinateToPoint(self.centerCoordinate);

    CGSize size = self.frame.size;
    CGFloat scale = pow(2, self.zoomLevel);
    NSInteger level = ceil(self.zoomLevel);
    NSInteger n = 1 << level;

    CGFloat worldSize = kTileSize * scale;

    CGPoint centerPoint = CGPointMake(center.x * scale, center.y * scale);
    CGFloat tileScale = scale / (CGFloat)n;
    CGFloat tileSize = tileScale * kTileSize;

    CGPoint worldOffset = CGPointMake(centerPoint.x * kTileSize,
                                      worldSize - centerPoint.y * kTileSize);


    NSInteger centralTileX = floor(center.x * n);
    NSInteger centralTileY = floor(center.y * n);

    CGPoint centralTilePoint = CGPointMake((CGFloat)centralTileX * tileSize,
                                           worldSize - (CGFloat)centralTileY * tileSize - tileSize);

    CGPoint centralTileOrigin = CGPointMake(size.width / 2 + centralTilePoint.x - worldOffset.x,
                                            size.height / 2 + centralTilePoint.y - worldOffset.y);


    NSInteger offsetX = -ceil((size.width / 2.0) / tileSize);
    NSInteger offsetY = -ceil((size.height / 2.0) / tileSize);

    NSInteger maxOffsetX = -offsetX;
    NSInteger maxOffsetY = -offsetY;



    while (offsetY <= maxOffsetY)
    {
        offsetX = -maxOffsetX;

        while (offsetX <= maxOffsetX)
        {

            NSInteger tileX = centralTileX + offsetX;
            NSInteger tileY = centralTileY + offsetY;

            if (tileX < 0 || tileY < 0 || tileX >= n || tileY >= n)
                goto next;

            CGRect tileRect;
            tileRect.size = CGSizeMake(tileSize, tileSize);
            tileRect.origin = CGPointMake(centralTileOrigin.x + offsetX * tileSize,
                                          centralTileOrigin.y - offsetY * tileSize);

            if (!CGRectIntersectsRect(tileRect, rect))
                goto next;

            CGImageRef image;

            if ((image = [self.tileManager tileImageForX:tileX y:tileY zoomLevel:level]))
            {
                CGContextDrawImage(ctx, tileRect, image);
                CFRelease(image);
            }

next:
            offsetX++;
        }

        offsetY++;
    }
}

@end
