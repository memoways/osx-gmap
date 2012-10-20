#import <QuartzCore/QuartzCore.h>
#import "GMDrawDelegate.h"
#import "GMMapView.h"
#import "GMTileManager.h"

@interface GMDrawDelegate ()

@property (assign) GMMapView *mapView;
@property (readonly) NSInteger tileZoomLevel;
@property GMTileManager *tileManager;


@end


@implementation GMDrawDelegate

- (id)initWithMapView:(GMMapView *)mapView
{
    self = [super init];

    if (!self)
        return nil;

    self.tileManager = [GMTileManager new];
    return self;
}

- (void)drawLayer:(CATiledLayer *)layer inContext:(CGContextRef)context
{
    if (self.mapView.inLiveResize)
        return;

    // CGPoint center = GMCoordinateToPoint(self.mapView.centerCoordinate);



    CGAffineTransform t = CGContextGetCTM(context);
    CGFloat scale = t.a;

    int level = log(scale) / log(2);

    level = (int)ceil(self.mapView.zoomLevel);
    NSInteger n = 1 << level;
    /*
       NSInteger tileX = floor(center.x * n);
       NSInteger tileY = floor(center.y * n);
     */
    CGSize tileSize = layer.tileSize;

    CGRect rect = CGContextGetClipBoundingBox(context);
    //NSLog(@"%f %f", t.tx, t.ty);
    //    NSLog(@"%@", NSStringFromRect(rect));
    NSInteger x = t.tx / tileSize.width;
    NSInteger y = t.ty / tileSize.height;

    //NSLog(@"n: %ld", n);
    //NSLog(@"x: %ld", x);
    //NSLog(@"y: %ld", y);

    NSInteger tileX = -x;
    NSInteger tileY = n + y - 1;

    //tileX %= n;

    // NSLog(@"X:%d, Y:%d, N:%d", tileX, tileY, n);
/*
    CGContextSetFillColorWithColor(context, [NSColor colorWithCalibratedRed:((CGFloat)rand() / (CGFloat)RAND_MAX) green:((CGFloat)rand() / (CGFloat)RAND_MAX) blue:0 alpha:1].CGColor);
    CGContextFillRect(context, rect);
    return;
 */
    if (tileY >= n || tileY < 0 || tileX >= n || tileX < 0)
        return;

    CGImageRef image;

    if ((image = [self.tileManager tileImageForX:tileX y:tileY zoomLevel:level]))
    {
        tileSize.width /= scale;
        tileSize.height /= scale;
        rect.size = tileSize;
        CGContextDrawImage(context, rect, image);
        CFRelease(image);
    }
    else
    {
        CGContextFillRect(context, rect);
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
