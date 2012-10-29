#import "GMTileManager.h"
#import "GMMapView.h"
#import "GMTile.h"
#import <objc/runtime.h>
#import <curl/curl.h>

const NSString *kCacheArrayKey = @"cacheArray";

const char *TILE_KEY = "tile";

@interface GMTileManager ()

@property (readonly) NSString *defaultCacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@property CGImageRef errorTileImage;

@property NSMutableDictionary *tileCacheDictionary;
@property NSMutableDictionary *loadingTiles;
@property NSMutableArray *tileCacheArray;

@property NSOperationQueue *tileLoadQueue;

- (void)loadTileFromDiskCache:(GMTile *)tile;
- (void)loadTile:(GMTile *)tile;
- (void)tileDidLoad:(GMTile *)tile withImage:(CGImageRef)image;
- (NSString *)cachePathForTile:(GMTile *)tile;

@end

@implementation GMTileManager

+ (id)sharedTileManager
{
    static GMTileManager *sharedTileManager;
    
    if (!sharedTileManager)
        sharedTileManager = GMTileManager.new;

    return sharedTileManager;
}

- (id)init
{
    if (!(self = super.init))
        return nil;

    if (curl_global_init(CURL_GLOBAL_ALL))
        return nil;

    self.tileURLFormat = self.defaultTileURLFormat;
    self.cacheDirectoryPath = self.defaultCacheDirectoryPath;

    self.loadingTiles = NSMutableDictionary.new;
    self.tileCacheDictionary = NSMutableDictionary.new;
    self.tileCacheArray = NSMutableArray.new;

    self.tileLoadQueue = NSOperationQueue.new;
    self.tileLoadQueue.maxConcurrentOperationCount = 10;

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
        [self loadTileFromDiskCache:tile];
        [self.tileCacheDictionary setObject:tile forKey:tileKey];
    }

    if (tile.zoomLevel > 4)
    {
        [self.tileCacheArray removeObject:tile];
        [self.tileCacheArray insertObject:tile atIndex:0];
    }

    if (self.tileCacheArray.count > 1000)
    {
        GMTile *tileToFlush = self.tileCacheArray.lastObject;
        [self.tileCacheArray removeLastObject];
        [self.tileCacheDictionary removeObjectForKey:tileToFlush.key];
    }

    CGImageRef image;

    if (!tile.loaded)
    {
        tile.completion = completion;

        if (!tile.image)
        {
            CGFloat factor = 1;

            for (NSInteger parentZoomLevel = zoomLevel - 1; parentZoomLevel >= 0; parentZoomLevel--)
            {
                factor *= 2;

                NSInteger parentX = floor((CGFloat)x / factor);
                NSInteger parentY = floor((CGFloat)y / factor);
                NSString *parentTileKey = [GMTile tileKeyForX:parentX y:parentY zoomLevel:parentZoomLevel];

                GMTile *parentTile = [self.tileCacheDictionary objectForKey:parentTileKey];

                if (parentTile.loaded)
                {

                    CGRect rect;

                    rect.origin = CGPointMake(fmod((CGFloat)x / factor, 1.0) * kTileSize, fmod((CGFloat)y / factor, 1.0) * kTileSize);
                    rect.size = CGSizeMake(kTileSize / factor, kTileSize / factor);

                    tile.image = CGImageCreateWithImageInRect(parentTile.image, rect);
                    break;
                }
            }
        }

        if (!tile.loading)
        {
            tile.loading = YES;

            [self loadTile:tile];
        }
    }

    image = CGImageRetain(tile.image);

    return image;
}

- (NSString *)cachePathForTile:(GMTile *)tile
{
    return [self.cacheDirectoryPath stringByAppendingPathComponent:(NSString *)tile.key];
}

- (void)loadTileFromDiskCache:(GMTile *)tile
{
    NSString *path = [self cachePathForTile:tile];

    if (!self.diskCacheEnabled || ![NSFileManager.defaultManager fileExistsAtPath:path])
        return;

    NSURL *fileURL = [NSURL fileURLWithPath:path];

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);

    tile.image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    tile.loaded = YES;
}

- (void)loadTile:(GMTile *)tile
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y]];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    
    [req setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/536.26.14 (KHTML, like Gecko) Version/6.0.1 Safari/536.26.14" forHTTPHeaderField:@"User-Agent"];
    [req setValue:@"gzip, deflate" forHTTPHeaderField:@"Accept-Encoding"];
    
    [NSURLConnection sendAsynchronousRequest:req queue:self.tileLoadQueue completionHandler:^(NSURLResponse * response, NSData * data, NSError * error) {

         NSString *path = [self cachePathForTile:tile];

         CGImageRef image = NULL;
         CFStringRef MIMEType = (__bridge CFStringRef)response.MIMEType;
         CFStringRef type = UTTypeCreatePreferredIdentifierForTag (kUTTagClassMIMEType, MIMEType, kUTTypeImage);

         if (type && data)
         {
             if (UTTypeEqual (type, kUTTypeJPEG) || UTTypeEqual (type, kUTTypePNG))
             {
                 CGDataProviderRef provider = CGDataProviderCreateWithCFData ((__bridge CFDataRef)data);

                 if (provider)
                 {
                     if (UTTypeEqual (type, kUTTypePNG))
                         image = CGImageCreateWithPNGDataProvider (provider, NULL, NO, kCGRenderingIntentDefault);
                     else
                         image = CGImageCreateWithJPEGDataProvider (provider, NULL, NO, kCGRenderingIntentDefault);

                     CFRelease (provider);
                 }

                 if (image && self.diskCacheEnabled)
                     [data writeToFile:path atomically:YES];
             }

             CFRelease (type);
         }

         if (!image)
         {
             image = CGImageRetain (self.errorTileImage);
             NSLog (@"Unable to load tile %@", tile.key);
         }

         [NSOperationQueue.mainQueue addOperationWithBlock:^{
              [self tileDidLoad:tile withImage:image];
          }];
     }];

}

- (void)tileDidLoad:(GMTile *)tile withImage:(CGImageRef)image
{
    CGImageRelease (tile.image);
    tile.image = image;
    tile.loaded = YES;
    tile.loading = NO;
    tile.completion();
}

@end
