#import "GMOverlayManager.h"
#import <sqlite3.h>

@interface GMOverlayManager ()

@property (nonatomic) NSMutableArray *overlays;
@property (nonatomic) sqlite3 *db;

@end

@implementation GMOverlayManager

- (id)init
{
    if (!(self = super.init))
        return nil;

    if (sqlite3_open(":memory:", &_db))
        return nil;

    self.overlays = NSMutableArray.new;

    return self;
}

- (void)dealloc
{
    sqlite3_close(_db);
}

- (void)addOverlay:(GMOverlay *)anOverlay
{
    [self.overlays addObject:anOverlay];
}

- (void)removeOverlay:(GMOverlay *)anOverlay
{
    [self.overlays removeObject:anOverlay];    
}

- (NSArray *)overlaysWithinBounds:(CGRect)bounds
{
    return self.overlays;
}

@end
