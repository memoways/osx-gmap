#import <QuartzCore/QuartzCore.h>
#import "GMDrawDelegate.h"
#import "GMMapView.h"
#import "GMTileManager.h"

@interface GMDrawDelegate ()

@property (assign) GMMapView *mapView;
@property (readonly) NSInteger tileZoomLevel;
@property GMTileManager* tileManager;


@end


@implementation GMDrawDelegate

- (id)initWithMapView:(GMMapView *)mapView
{
    self = [super init];

    if (!self)
        return nil;

    self.mapView = mapView;
    self.tileManager = [GMTileManager new];
    return self;
}

- (void)drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)context
{
    if (self.mapView.inLiveResize)
        return;

    CGPoint center = GMCoordinateToPoint(self.mapView.centerCoordinate);

    NSInteger zoomLevel = self.tileZoomLevel;
    NSInteger n = 1 << zoomLevel;
    NSInteger tileX = floor(center.x * n);
    NSInteger tileY = floor(center.y * n);

    NSLog(@"%f", layer.contentsScale);
    CGRect tileBounds = CGContextGetClipBoundingBox(context);
    NSLog(@"%@", NSStringFromRect(tileBounds));
    NSInteger x = tileBounds.origin.x / layer.tileSize.width;
    NSInteger y = tileBounds.origin.y / layer.tileSize.height;

    tileX += x;
    tileY -= y;
    
    tileX %= n;
    tileY %= n;
    
    CGImageRef image;
    
    if ((image = [self.tileManager tileImageForX:tileX y:tileY zoomLevel:zoomLevel]))
    {
        //tileBounds.size = layer.tileSize;
        CGContextDrawImage(context, tileBounds, image);
        CFRelease(image);
    }
    
    /*
    NSURL *url = [self tileURLForX:tileX y:tileY];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    tileBounds.size = layer.tileSize;
    CGContextDrawImage(context, tileBounds, image);
    CGImageRelease(image);
    */
}

- (NSInteger)tileZoomLevel
{
    return round(self.mapView.zoomLevel);
}

@end
