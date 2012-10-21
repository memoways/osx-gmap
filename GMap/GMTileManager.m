#import "GMTileManager.h"
#import "GMMapView.h"
#import "GMTile.h"

const NSString *kCacheArrayKey = @"cacheArray";


@interface GMTileManager ()

@property (readonly) NSString *defaultCacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@property CGImageRef invalidSpriteImage;

@property NSMutableDictionary *tileCache;

@property NSOperationQueue *tileLoadQueue;

- (void)loadTile:(GMTile *)tile;

@end

@implementation GMTileManager

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.tileURLFormat = self.defaultTileURLFormat;
    self.cacheDirectoryPath = self.defaultCacheDirectoryPath;

    self.tileCache = NSMutableDictionary.new;

    self.tileLoadQueue = NSOperationQueue.new;


    NSURL *url = [[NSBundle bundleForClass:GMTileManager.class] URLForImageResource:@"InvalidSprite.jpg"];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    self.invalidSpriteImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);

    return self;
}

- (NSString *)defaultTileURLFormat
{
    NSString *s = [NSBundle.mainBundle objectForInfoDictionaryKey:@"GMTileURLFormat"];

    if (!s)
        s = [[NSBundle bundleForClass:GMTileManager.class] objectForInfoDictionaryKey:@"GMTileURLFormat"];

    return s;
}

- (NSString *)defaultCacheDirectoryPath
{
    NSString *path = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

    if (paths.count)
    {
        NSString *bundleName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
        path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
    }

    assert(path);
    path = [path stringByAppendingPathComponent:@"GMap-tiles/"];

    if (![NSFileManager.defaultManager fileExistsAtPath:path])
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

    return path;
}

- (CGImageRef)createTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completion
{
    NSString *tileKey = [GMTile tileKeyForX:x y:y zoomLevel:zoomLevel];
    NSNumber *key = [NSNumber numberWithInteger:zoomLevel];

    NSMutableDictionary *cacheDictionary;
    NSMutableArray *cacheArray;

    cacheDictionary = [self.tileCache objectForKey:key];

    if (!cacheDictionary)
    {
        cacheDictionary = NSMutableDictionary.new;
        [self.tileCache setObject:cacheDictionary forKey:key];

        cacheArray = NSMutableArray.new;
        [cacheDictionary setObject:cacheArray forKey:kCacheArrayKey];
    }
    else
    {
        cacheArray = [cacheDictionary objectForKey:kCacheArrayKey];
    }

    GMTile *tile;

    tile = [cacheDictionary objectForKey:tileKey];

    if (!tile)
    {
        tile = [GMTile.alloc initWithX:x y:y zoomLevel:zoomLevel];
        [cacheDictionary setObject:tile forKey:tileKey];
    }

    [cacheArray removeObject:tile];
    [cacheArray insertObject:tile atIndex:0];

    if (cacheArray.count > 1000)
    {
        GMTile *tileToFlush = cacheArray.lastObject;
        [cacheArray removeLastObject];
        [cacheDictionary removeObjectForKey:tileToFlush.key];
    }

    if (tile.loaded)
    {
        CGImageRef image = tile.image;
        return CGImageRetain(image);
    }
    else
    {
        tile.completion = completion;

        if (!tile.loading)
        {
            tile.loading = YES;
            [self.tileLoadQueue addOperationWithBlock:^{
                 [self loadTile:tile];
             }];
        }
    }

    return NULL;
}


- (void)loadTile:(GMTile *)tile
{
    NSLog(@"Loading tile %@", tile.key);
    NSString *filename = [NSString stringWithFormat:@"%@.jpg", tile.key];
    NSString *path = [self.cacheDirectoryPath stringByAppendingPathComponent:filename];
    NSURL *fileURL = [NSURL fileURLWithPath:path];

    CGImageRef image = NULL;

    if (![NSFileManager.defaultManager fileExistsAtPath:path])
    {
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y]];

        for (int i = 0; i < 5; i++)
        {
            NSData *data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:path atomically:YES];

            CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
            image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
            CFRelease(source);

            if (image)
                break;
        }

    }
    else
    {
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
        image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
    }
    if (!image)
        image = self.invalidSpriteImage;

    tile.image = image;
    tile.loaded = YES;
    tile.loading = NO;
    [NSOperationQueue.mainQueue addOperationWithBlock:tile.completion];

}


@end
