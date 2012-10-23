#import "GMTileManager.h"
#import "GMMapView.h"
#import "GMTile.h"

const NSString *kCacheArrayKey = @"cacheArray";


@interface GMTileManager ()

@property (readonly) NSString *defaultCacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@property CGImageRef errorTileImage;

@property NSMutableDictionary *tileCacheDictionary;
@property NSMutableArray *tileCacheArray;

@property NSOperationQueue *tileLoadQueue;

- (void)cacheTile:(GMTile *)tile;
- (void)loadTileFromCache:(GMTile *)tile;
- (NSString *)cachePathForTile:(GMTile *)tile;

@end

@implementation GMTileManager

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.tileURLFormat = self.defaultTileURLFormat;
    self.cacheDirectoryPath = self.defaultCacheDirectoryPath;

    self.tileCacheDictionary = NSMutableDictionary.new;
    self.tileCacheArray = NSMutableArray.new;

    self.tileLoadQueue = NSOperationQueue.new;
    self.tileLoadQueue.maxConcurrentOperationCount = 50;

    NSURL *url = [[NSBundle bundleForClass:GMTileManager.class] URLForImageResource:@"ErrorTileImage.png"];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);
    self.errorTileImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);

    return self;
}

- (void)dealloc
{
    CGImageRelease(self.errorTileImage);
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

    GMTile *tile;

    tile = [self.tileCacheDictionary objectForKey:tileKey];

    if (!tile)
    {
        tile = [GMTile.alloc initWithX:x y:y zoomLevel:zoomLevel];
        [self loadTileFromCache:tile];
        [self.tileCacheDictionary setObject:tile forKey:tileKey];
    }

    [self.tileCacheArray removeObject:tile];
    [self.tileCacheArray insertObject:tile atIndex:0];

    if (self.tileCacheArray.count > 1000)
    {
        GMTile *tileToFlush = self.tileCacheArray.lastObject;
        [self.tileCacheArray removeLastObject];
        [self.tileCacheDictionary removeObjectForKey:tileToFlush.key];
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
                 [self cacheTile:tile];
             }];
        }
    }

    return NULL;
}

- (NSString *)cachePathForTile:(GMTile *)tile
{
    return [self.cacheDirectoryPath stringByAppendingPathComponent:(NSString *)tile.key];
}

- (void)loadTileFromCache:(GMTile *)tile
{
    NSString *path = [self cachePathForTile:tile];

    if (![NSFileManager.defaultManager fileExistsAtPath:path])
        return;

    NSURL *fileURL = [NSURL fileURLWithPath:path];

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
    tile.image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    tile.loaded = YES;
}

- (void)cacheTile:(GMTile *)tile
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y]];

    NSURLRequest *req = [NSURLRequest requestWithURL:url];


    [NSURLConnection sendAsynchronousRequest:req queue:self.tileLoadQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {

         NSString *path = [self cachePathForTile:tile];

         CGImageRef image = NULL;
         CFStringRef MIMEType = (__bridge CFStringRef)response.MIMEType;
         CFStringRef type = UTTypeCreatePreferredIdentifierForTag (kUTTagClassMIMEType, MIMEType, kUTTypeImage);

         if (UTTypeEqual (type, kUTTypeJPEG) || UTTypeEqual (type, kUTTypePNG))
         {
             CGDataProviderRef provider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)data);

             if (UTTypeEqual (type, kUTTypePNG))
                 image = CGImageCreateWithPNGDataProvider (provider, NULL, NO, kCGRenderingIntentDefault);
             else
                 image = CGImageCreateWithJPEGDataProvider (provider, NULL, NO, kCGRenderingIntentDefault);

             CFRelease (provider);

             if (image)
                 [data writeToFile:path atomically:YES];
         }

         CFRelease (type);

         if (!image)
         {
             image = self.errorTileImage;
             NSLog (@"Unable to load tile %@", tile.key);
         }

         tile.image = image;
         tile.loaded = YES;
         tile.loading = NO;
         [NSOperationQueue.mainQueue addOperationWithBlock:(void (^)(void))tile.completion];
     }];

}


@end
