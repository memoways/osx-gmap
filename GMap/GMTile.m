#import "GMTile.h"


@interface GMTile ()

@property (nonatomic) NSInteger x;
@property (nonatomic) NSInteger y;
@property (nonatomic) NSInteger zoomLevel;
@property (nonatomic) NSString *key;

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
    self.key = [GMTile tileKeyForX:self.x y:self.y zoomLevel:self.zoomLevel];

    return self;
}

- (void)dealloc
{
    CGImageRelease(self.image);
}

- (void)setImage:(CGImageRef)newImage
{
    if (_image == newImage)
        return;

    CGImageRelease(_image);
    _image = CGImageRetain(newImage);
}

@end
