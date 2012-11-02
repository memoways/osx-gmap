#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMTileManager.h"
#import "GMOverlayManager.h"


@interface GMMapView ()

@property (nonatomic) NSInteger renderedZoomLevel;
@property (nonatomic) CALayer *tileLayer;
@property (nonatomic) CALayer *overlayLayer;
@property (nonatomic) CGPoint centerPoint;


- (void)updateLayerTransform;
- (void)updateLayerBounds;

- (void)drawTilesInContext:(CGContextRef)ctx;
- (void)drawOverlaysInContext:(CGContextRef)ctx;

@end

@implementation GMMapView


- (id)initWithFrame:(NSRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

    self.panningEnabled = YES;
    self.scrollZoomEnabled = YES;

    self.tileManager = GMTileManager.new;
    self.overlayManager = GMOverlayManager.new;

    self.layer = CALayer.new;
    self.wantsLayer = YES;

    self.tileLayer = CALayer.new;
    self.tileLayer.delegate = self;
    self.tileLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self.tileLayer];

    self.overlayLayer = CALayer.new;
    self.overlayLayer.delegate = self;
    self.overlayLayer.needsDisplayOnBoundsChange = YES;
        //self.overlayLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    [self.layer addSublayer:self.overlayLayer];

    [self updateLayerBounds];
    [self updateLayerTransform];


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
}

- (void)updateLayerBounds
{
    self.tileLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.overlayLayer.bounds = self.tileLayer.bounds;
}

- (void)updateLayerTransform
{
    CGFloat f = fmod(self.zoomLevel, 1);
    CGFloat scale = pow(2, f);
    CGAffineTransform t = CGAffineTransformIdentity;

    t = CGAffineTransformTranslate(t, self.layer.bounds.size.width / 2.0, self.layer.bounds.size.height / 2.0);
    self.overlayLayer.affineTransform = t;
    
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

    [self.overlayLayer setNeedsDisplay];
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
    [self.overlayLayer setNeedsDisplay];
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
    [self.overlayLayer setNeedsDisplay];
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

// ################################################################################
// Drawing

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (layer == self.tileLayer)
        [self drawTilesInContext:ctx];
    else if (layer == self.overlayLayer)
        [self drawOverlaysInContext:ctx];
}

- (void)drawTilesInContext:(CGContextRef)ctx
{
    CGRect rect = CGContextGetClipBoundingBox(ctx);

    CGPoint center = self.centerPoint;

    CGSize size = self.tileLayer.bounds.size;
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

- (void)drawOverlaysInContext:(CGContextRef)ctx
{
    CGPoint topLeft = [self convertViewLocationToPoint:CGPointMake(0, self.frame.size.height)];
    CGPoint bottomRight = [self convertViewLocationToPoint:CGPointMake(self.frame.size.width, 0)];
    CGRect bounds = CGRectMake(topLeft.x, topLeft.y, bottomRight.x - topLeft.x, bottomRight.y - topLeft.y);

    NSArray *overlays = [self.overlayManager overlaysWithinBounds:bounds];
    
    CGPoint center = self.centerPoint;
    CGFloat scale = pow(2, self.zoomLevel);

    CGSize size = self.tileLayer.bounds.size;
    NSInteger level = floor(self.zoomLevel);
    NSInteger n = 1 << level;

    CGFloat worldSize = kTileSize * n;

    CGPoint centerPoint = CGPointMake(center.x * scale, center.y * scale);

    CGPoint worldOffset = CGPointMake(centerPoint.x * kTileSize - size.width / 2.0,
                                      centerPoint.y * kTileSize - size.height / 2.0);


    for (GMOverlay *overlay in overlays)
    {
        [overlay drawInContext:ctx offset:worldOffset scale:scale * kTileSize];
    }

}

// ################################################################################
// Events
/*
#import <Foundation/NSJSONSerialization.h>
static NSMutableArray *currentPath;

- (void)rightMouseDown:(NSEvent *)evt
{
    if (currentPath)
    {
        NSData *data = [NSJSONSerialization dataWithJSONObject:currentPath options:NSJSONWritingPrettyPrinted error:nil];
    [data writeToFile:[NSString stringWithFormat:@"/Users/kuon/Projects/GMap/DemoApp/DemoApp/Tracks/%ld.json", time(NULL)] atomically:NO];
    }


    currentPath = NSMutableArray.new;
}

- (void)mouseDown:(NSEvent *)evt
{
    CGPoint relativeCenter = [self convertPoint:evt.locationInWindow fromView:nil];

    GMCoordinate coord = GMPointToCoordinate([self convertViewLocationToPoint:relativeCenter]);

    [currentPath addObject:@{@"latitude":[NSNumber numberWithDouble:coord.latitude], @"longitude":[NSNumber numberWithDouble:coord.longitude]}];

}
*/
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

    CGPoint offset = CGPointMake(relativeCenter.x * scale - relativeCenter.x,
                                 relativeCenter.y * scale - relativeCenter.y );

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

// ################################################################################
// Utilities

- (CGPoint)convertViewLocationToPoint:(CGPoint)locationInView
{
    locationInView.x -= self.frame.size.width / 2.0;
    locationInView.y -= self.frame.size.height / 2.0;

    CGFloat scale = pow(2, self.zoomLevel);
    return CGPointMake(self.centerPoint.x + locationInView.x / scale / kTileSize,
                       self.centerPoint.y - locationInView.y / scale / kTileSize);
}

@end
