#import "GMTile.h"


@interface GMTile ()

@property NSInteger x;
@property NSInteger y;
@property NSInteger zoomLevel;

@end

@implementation GMTile

+ (NSString *)tileKeyForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel
{
    return [NSString stringWithFormat:@"%ld-%ld-%ld", (long)zoomLevel, (long)x, (long)y];
}

- (id)initWithX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel
{
    if (!(self = super.init))
        return nil;

    self.x = x;
    self.y = y;
    self.zoomLevel = zoomLevel;

    return self;
}

- (NSString *)key
{
    return [GMTile tileKeyForX:self.x y:self.y zoomLevel:self.zoomLevel];
}

- (void)dealloc
{
    NSLog(@"Cleaning tile %@", self.key);
    CGImageRelease(self.image);
}

@end
