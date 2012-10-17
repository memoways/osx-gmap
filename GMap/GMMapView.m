#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMDrawDelegate.h"

@interface GMMapView ()

@property GMDrawDelegate *drawDelegate;
@property CATiledLayer *tiledLayer;

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

    self.zoomLevel = 5;

    self.wantsLayer = YES;
    CALayer *baseLayer = [CALayer layer];
    self.layer = baseLayer;

    self.drawDelegate = [[GMDrawDelegate alloc] initWithMapView:self];

    self.tiledLayer = [CATiledLayer layer];
    [baseLayer addSublayer:self.tiledLayer];
    self.tiledLayer.delegate = self.drawDelegate;
    self.tiledLayer.tileSize = CGSizeMake(256, 256);
    self.tiledLayer.levelsOfDetail = 1;
    self.tiledLayer.levelsOfDetailBias = 18;
    self.tiledLayer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    self.tiledLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    self.tiledLayer.needsDisplayOnBoundsChange = YES;
    self.tiledLayer.contentsScale = 2;
    [self.tiledLayer setNeedsDisplay];

    [self addObserver:self forKeyPath:@"zoomLevel" options:0 context:nil];

    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.tiledLayer setNeedsDisplay];
}

- (void)viewDidEndLiveResize
{
    [self.tiledLayer setNeedsDisplay];
}

@end
