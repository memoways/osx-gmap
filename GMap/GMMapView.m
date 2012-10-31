#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMTileManager.h"



@interface GMMapView ()

@property (nonatomic) NSInteger renderedZoomLevel;
@property (nonatomic) CALayer *tileLayer;
@property (nonatomic) CGPoint centerPoint;


- (void)updateLayerTransform;
- (void)updateLayerBounds;


@end

@implementation GMMapView


- (id)initWithFrame:(NSRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.panningEnabled = YES;
    self.scrollZoomEnabled = YES;

    self.tileManager = GMTileManager.new;

    self.layer = CALayer.new;
    self.wantsLayer = YES;

    self.layer.delegate = self;

    self.tileLayer = CALayer.new;
    self.tileLayer.delegate = self;
    [self.layer addSublayer:self.tileLayer];

    [self updateLayerBounds];
    [self updateLayerTransform];
    [self.tileLayer setNeedsDisplay];

    return self;
}

- (void)dealloc
{
    self.layer.delegate = nil;
    self.tileLayer.delegate = nil;
}

- (void)viewDidEndLiveResize
{
    [self updateLayerBounds];
    [self updateLayerTransform];
    [self.tileLayer setNeedsDisplay];
}

- (void)updateLayerBounds
{
    self.tileLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
}

- (void)updateLayerTransform
{
    CGFloat f = fmod(self.zoomLevel, 1);
    CGFloat scale = pow(2, f);
    CGAffineTransform t = CGAffineTransformIdentity;

    t = CGAffineTransformTranslate(t, self.layer.bounds.size.width / 2.0, self.layer.bounds.size.height / 2.0);
    t = CGAffineTransformScale(t, scale, scale);

    self.tileLayer.affineTransform = t;
}


// ################################################################################
// Properties

- (void)setFrame:(CGRect)frame
{
    super.frame = frame;

    if (![self inLiveResize])
        [self updateLayerBounds];

    [self updateLayerTransform];
}

- (void)setZoomLevel:(CGFloat)zoomLevel
{
    _zoomLevel = MAX(0, MIN(18, zoomLevel));

    if (self.shouldRoundZoomLevel)
        _zoomLevel = round(_zoomLevel);

    NSInteger renderZoomLevel = floor(_zoomLevel);

    if (renderZoomLevel != self.renderedZoomLevel)
    {
        self.renderedZoomLevel = renderZoomLevel;
        [self updateLayerTransform];
        [self.tileLayer setNeedsDisplay];
    }
    else
        [self updateLayerTransform];
}

- (void)setCenterLatitude:(CGFloat)latitude
{
    self.centerCoordinate = GMCoordinateMake(latitude, self.centerCoordinate.longitude);
}

- (void)setCenterLongitude:(CGFloat)longitude
{
    self.centerCoordinate = GMCoordinateMake(self.centerCoordinate.latitude, longitude);
}

- (CGFloat)centerLatitude
{
    return self.centerCoordinate.latitude;
}

- (CGFloat)centerLongitude
{
    return self.centerCoordinate.longitude;
}

- (void)setCenterCoordinate:(GMCoordinate)coordinate
{
    [self willChangeValueForKey:@"centerLatitude"];
    [self willChangeValueForKey:@"centerLongitude"];
    _centerCoordinate = coordinate;
    [self didChangeValueForKey:@"centerLongitude"];
    [self didChangeValueForKey:@"centerLatitude"];

    [self willChangeValueForKey:@"centerPoint"];
    _centerPoint = GMCoordinateToPoint(self.centerCoordinate);
    [self didChangeValueForKey:@"centerPoint"];

    [self.tileLayer setNeedsDisplay];
}

- (void)setCenterPoint:(CGPoint)point
{
    _centerPoint.x = MAX(0, MIN(1.0, point.x));
    _centerPoint.y = MAX(0, MIN(1.0, point.y));

    [self willChangeValueForKey:@"centerCoordinate"];
    [self willChangeValueForKey:@"centerLatitude"];
    [self willChangeValueForKey:@"centerLongitude"];
    _centerCoordinate = GMPointToCoordinate(_centerPoint);
    [self didChangeValueForKey:@"centerLongitude"];
    [self didChangeValueForKey:@"centerLatitude"];
    [self didChangeValueForKey:@"centerCoordinate"];

    [self.tileLayer setNeedsDisplay];
}



// ################################################################################
// Drawing

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    CGRect rect = CGContextGetClipBoundingBox(ctx);

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

    void (^drawTile)(NSInteger offsetX, NSInteger offsetY) = ^(NSInteger offsetX, NSInteger offsetY) {

        NSInteger tileX = centralTileX + offsetX;
        NSInteger tileY = centralTileY + offsetY;

        if (tileX < 0 || tileY < 0 || tileX >= n || tileY >= n)
            return;

        CGRect tileRect;
        tileRect.size = CGSizeMake (kTileSize, kTileSize);
        tileRect.origin = CGPointMake (floor (centralTileOrigin.x + offsetX * kTileSize),
                                       floor (centralTileOrigin.y - offsetY * kTileSize));

        if (!CGRectIntersectsRect (rect, tileRect))
            return;

        CGImageRef image;

        void (^redraw)(void) = ^{
            [self.tileLayer setNeedsDisplayInRect:tileRect];
        };

        if ((image = [self.tileManager createTileImageForX:tileX y:tileY zoomLevel:level completion:redraw]))
        {
            CGContextDrawImage (ctx, tileRect, image);
            CGImageRelease (image);
        }
    };

    for (; offsetY <= maxOffsetY; offsetY++)
    {
        offsetX = -maxOffsetX;

        for (; offsetX <= maxOffsetX; offsetX++)
        {
            drawTile (offsetX, offsetY);
        }
    }
}

// ################################################################################
// Events

- (void)mouseDown:(NSEvent *)evt
{

}

- (void)mouseDragged:(NSEvent *)evt
{
    if (!self.panningEnabled)
        return;

    CGFloat scale = pow(2, self.zoomLevel);
    CGPoint point = CGPointMake(evt.deltaX / scale / kTileSize, evt.deltaY / scale / kTileSize);

    self.centerPoint = CGPointMake(self.centerPoint.x - point.x, self.centerPoint.y - point.y);
}

- (void)scrollWheel:(NSEvent *)evt
{
    if (!self.scrollZoomEnabled)
        return;

    CGFloat zoomDelta = evt.scrollingDeltaY / 10.0;

    if (self.shouldRoundZoomLevel)
        zoomDelta = zoomDelta > 0 ? ceil(zoomDelta) : floor(zoomDelta);

    CGFloat scale = pow(2, zoomDelta);

    CGPoint relativeCenter = [self convertPoint:evt.locationInWindow fromView:nil];

    relativeCenter.x -= self.frame.size.width / 2.0;
    relativeCenter.y -= self.frame.size.height / 2.0;

    CGPoint offset = CGPointMake(relativeCenter.x * scale - relativeCenter.x, relativeCenter.y * scale - relativeCenter.y );

    CGFloat previousZoomLevel = self.zoomLevel;
    self.zoomLevel += zoomDelta;

    if (previousZoomLevel == self.zoomLevel)
        return;

    scale = pow(2, self.zoomLevel);

    offset.x = offset.x / scale / kTileSize;
    offset.y = offset.y / scale / kTileSize;

    self.centerPoint = CGPointMake(self.centerPoint.x + offset.x, self.centerPoint.y - offset.y);
}

- (void)mouseUp:(NSEvent *)evt
{

}

@end
