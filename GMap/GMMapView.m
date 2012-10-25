#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMTileManager.h"


const CGFloat kTileSize = 256.0;

@interface GMMapView ()

@property (nonatomic) NSInteger renderedZoomLevel;
@property (nonatomic) CALayer *tileLayer;
@property (nonatomic) CGPoint centerPoint;

- (void)updateTileLayerTransform;
- (void)updateTileLayerBounds;

@end

@implementation GMMapView


- (id)initWithFrame:(NSRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.tileManager = GMTileManager.new;

    self.layer = CALayer.new;
    self.wantsLayer = YES;

    self.layer.delegate = self;

    self.tileLayer = CALayer.new;
    self.tileLayer.delegate = self;
    [self.layer addSublayer:self.tileLayer];

    
    [self updateTileLayerBounds];
    [self updateTileLayerTransform];
    [self.tileLayer setNeedsDisplay];

    return self;
}

- (void)setFrame:(CGRect)frame
{
    super.frame = frame;

    if (![self inLiveResize])
        [self updateTileLayerBounds];

    [self updateTileLayerTransform];
}

- (void)viewDidEndLiveResize
{
    [self updateTileLayerBounds];
    [self updateTileLayerTransform];
    [self.tileLayer setNeedsDisplay];
}

- (void)updateTileLayerBounds
{
    self.tileLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)updateTileLayerTransform
{
    CGFloat f = fmod(self.zoomLevel, 1);
    CGFloat scale = pow(2, f);
    CGAffineTransform t = CGAffineTransformIdentity;

    t = CGAffineTransformTranslate(t, self.layer.bounds.size.width / 2.0, self.layer.bounds.size.height / 2.0);
    t = CGAffineTransformScale(t, scale, scale);

    self.tileLayer.affineTransform = t;
}

- (void)setZoomLevel:(CGFloat)zoomLevel
{
    _zoomLevel = MAX(0, MIN(18, zoomLevel));
    
    NSInteger renderZoomLevel = floor(zoomLevel);

    [self updateTileLayerTransform];

    if (renderZoomLevel != self.renderedZoomLevel)
    {
        self.renderedZoomLevel = renderZoomLevel;
        [self.tileLayer setNeedsDisplay];
    }
}

- (void)setCenterCoordinate:(GMCoordinate)coordinate
{
    _centerCoordinate = coordinate;
    self.centerPoint = GMCoordinateToPoint(self.centerCoordinate);
    [self.tileLayer setNeedsDisplay];
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGRect rect = CGContextGetClipBoundingBox(ctx);
/*
    if (layer == self.layer)
    CGContextSetFillColorWithColor(ctx, NSColor.redColor.CGColor);
    else
        CGContextSetFillColorWithColor(ctx, NSColor.greenColor.CGColor);
    CGContextFillRect(ctx, rect);
    return;
 */

    CGPoint center = self.centerPoint;

    CGSize size = layer.bounds.size;
    NSInteger level = floor(self.zoomLevel);
    NSInteger n = 1 << level;

    CGFloat worldSize = kTileSize * n;

    CGPoint centerPoint = CGPointMake(center.x * n, center.y * n);

    CGPoint worldOffset = CGPointMake(centerPoint.x * kTileSize,
                                      worldSize - centerPoint.y * kTileSize);

    NSInteger centralTileX = floor(center.x * n);
    NSInteger centralTileY = floor(center.y * n);

    CGPoint centralTilePoint = CGPointMake((CGFloat)centralTileX * kTileSize,
                                           worldSize - (CGFloat)centralTileY * kTileSize - kTileSize);

    CGPoint centralTileOrigin = CGPointMake(size.width / 2 + centralTilePoint.x - worldOffset.x,
                                            size.height / 2 + centralTilePoint.y - worldOffset.y);


    NSInteger offsetX = -ceil((size.width / 2.0) / kTileSize);
    NSInteger offsetY = -ceil((size.height / 2.0) / kTileSize);

    NSInteger maxOffsetX = -offsetX;
    NSInteger maxOffsetY = -offsetY;

    CGContextSetFillColorWithColor(ctx, NSColor.windowBackgroundColor.CGColor);

    CGContextFillRect(ctx, rect);

    for (; offsetY <= maxOffsetY; offsetY++)
    {
        offsetX = -maxOffsetX;

        for (; offsetX <= maxOffsetX; offsetX++)
        {

            NSInteger tileX = centralTileX + offsetX;
            NSInteger tileY = centralTileY + offsetY;

            if (tileX < 0 || tileY < 0 || tileX >= n || tileY >= n)
                continue;

            CGRect tileRect;
            tileRect.size = CGSizeMake(kTileSize, kTileSize);
            tileRect.origin = CGPointMake(floor(centralTileOrigin.x + offsetX * kTileSize),
                                          floor(centralTileOrigin.y - offsetY * kTileSize));

            if (!CGRectIntersectsRect(rect, tileRect))
                continue;

            CGImageRef image;

            void (^redraw)(void) = ^{
                [self.tileLayer setNeedsDisplayInRect:tileRect];
            };

            if ((image = [self.tileManager createTileImageForX:tileX y:tileY zoomLevel:level completion:redraw]))
            {
                CGContextDrawImage(ctx, tileRect, image);
                CGImageRelease(image);
            }
        }
    }
}


@end


@implementation GMMapView (Events)

- (void)mouseDown:(NSEvent *)evt
{
    NSLog(@"Start panning");
}

- (void)mouseDragged:(NSEvent *)evt
{
    CGFloat scale = pow(2, self.zoomLevel);
    CGPoint point = CGPointMake(evt.deltaX / scale / kTileSize, evt.deltaY / scale / kTileSize);

    _centerPoint.x -= point.x;
    _centerPoint.y -= point.y;

    [self willChangeValueForKey:@"centerCoordinate"];
    _centerCoordinate = GMPointToCoordinate(_centerPoint);
    [self didChangeValueForKey:@"centerCoordinate"];
    
    [self.tileLayer setNeedsDisplay];
}

- (void)scrollWheel:(NSEvent *)evt
{
    self.zoomLevel += evt.scrollingDeltaY / 10.0;
        //NSLog(@"Wheel by %g %d", evt.scrollingDeltaY, evt.hasPreciseScrollingDeltas);
    
}

- (void)mouseUp:(NSEvent *)evt
{
    NSLog(@"Stop panning");
}

@end