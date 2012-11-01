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

    return self;
}

- (void)dealloc
{
    sqlite3_close(_db);
}

- (void)addOverlay:(GMOverlay *)anOverlay
{
    
}

- (void)removeOverlay:(GMOverlay *)anOverlay
{
    
}

@end
