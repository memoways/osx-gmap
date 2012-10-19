#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMDrawDelegate.h"

@interface FastCATiledLayer : CATiledLayer
@end

@implementation FastCATiledLayer
+(CFTimeInterval)fadeDuration {
    return 0.0;
}
@end

@interface GMMapView ()

@property GMDrawDelegate *drawDelegate;
@property CATiledLayer *tiledLayer;

@property CGFloat previousZoomLevel;

@end

@implementation GMMapView

+ (NSString *)tileURLFormat
{
    static void *volatile tileURLFormat;

    if (!tileURLFormat)
    {
        NSString *s = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GMTileURLFormat"];

        if (!s)
            s = [[NSBundle bundleForClass:[GMMapView class]]
                 objectForInfoDictionaryKey:@"GMTileURLFormat"];

        if (OSAtomicCompareAndSwapPtrBarrier(NULL, (__bridge void *)(s), &tileURLFormat))
            return s;
    }

    return (__bridge NSString *)tileURLFormat;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];

    if (!self)
        return nil;

    self.wantsLayer = YES;

    CALayer *baseLayer = [CALayer layer];
    self.layer = baseLayer;

    self.drawDelegate = [[GMDrawDelegate alloc] initWithMapView:self];

    self.tiledLayer = [FastCATiledLayer layer];
    [baseLayer addSublayer:self.tiledLayer];
    self.tiledLayer.delegate = self.drawDelegate;
    self.tiledLayer.tileSize = CGSizeMake(256, 256);
    self.tiledLayer.masksToBounds = YES;
    self.tiledLayer.levelsOfDetail = 1;
    self.tiledLayer.levelsOfDetailBias = 100;
    self.tiledLayer.frame = CGRectMake(0, 0, 256, 256);
        //self.tiledLayer.autoresizingMask = kCALayerWidthSizable; // | kCALayerHeightSizable;
    self.tiledLayer.needsDisplayOnBoundsChange = YES;
    [self.tiledLayer setNeedsDisplay];

    [self addObserver:self forKeyPath:@"zoomLevel" options:0 context:nil];
    [self addObserver:self forKeyPath:@"centerCoordinate" options:0 context:nil];

    [self updateLayerTransform];
    
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self updateLayerTransform];

    //[self.tiledLayer setNeedsDisplay];
}

- (void)viewDidEndLiveResize
{
    [self.tiledLayer setNeedsDisplay];
}

- (void)updateLayerTransform
{
    CGPoint center = GMCoordinateToPoint(self.centerCoordinate);

    CGAffineTransform t = CGAffineTransformIdentity;

    
    CGFloat scale = pow(2, fmod(self.zoomLevel, 4)) * 4;
    t = CGAffineTransformScale(t, scale, scale);
        //    t = CGAffineTransformTranslate(t, 0.5 * 256, -0.5 * 256);
        //t = CGAffineTransformTranslate(t, -center.x * 256, center.y * 256);

    [CATransaction begin];
    [CATransaction setAnimationDuration:0];
    self.layer.affineTransform = t;
    [CATransaction commit];
    
    if (floor(self.previousZoomLevel / 4.0) != floor(self.zoomLevel / 4.0))
        [self.tiledLayer setNeedsDisplay];
    
    self.previousZoomLevel = self.zoomLevel;
}

@end
