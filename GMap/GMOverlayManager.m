#import "GMOverlayManager.h"
#import <sqlite3.h>

@interface GMOverlayManager ()

@property (nonatomic) NSMutableArray *overlays;

@end

@implementation GMOverlayManager

- (id)init
{
    if (!(self = super.init))
        return nil;


    self.overlays = NSMutableArray.new;

    return self;
}

- (void)addOverlay:(GMOverlay *)anOverlay
{
    [self.overlays addObject:anOverlay];
}

- (void)removeOverlay:(GMOverlay *)anOverlay
{
    [self.overlays removeObject:anOverlay];
}


- (NSArray *)overlaysWithinBounds:(CGRect)bounds minSize:(CGFloat)minSize
{
    NSMutableArray *overlays = NSMutableArray.new;

    for (GMOverlay *overlay in self.overlays)
    {
        if (overlay.bounds.size.width + overlay.bounds.size.height > minSize &&
            ! (overlay.bounds.origin.x + overlay.bounds.size.width < bounds.origin.x
               || overlay.bounds.origin.y + overlay.bounds.size.height < bounds.origin.y
               || overlay.bounds.origin.x > bounds.origin.x + bounds.size.width
               || overlay.bounds.origin.y > bounds.origin.y + bounds.size.height))
            [overlays addObject:overlay];
    }

    return overlays;
}



@end
