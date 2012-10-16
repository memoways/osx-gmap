
#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMDrawDelegate.h"

@interface GMMapView ()

@property GMDrawDelegate *drawDelegate;
@property CATiledLayer *tiledLayer;

@end

@implementation GMMapView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
    
    
    self.tileURLFormat = [[NSBundle bundleForClass:[GMMapView class]]
                        objectForInfoDictionaryKey:@"GMDefaultTileURLFormat"];
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
    
	[self.tiledLayer setNeedsDisplay];
    
    
    return self;
}



@end
