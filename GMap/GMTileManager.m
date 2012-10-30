#import "GMTileManager.h"
#import "GMMapView.h"
#import "GMTile.h"

const NSString *kCacheArrayKey = @"cacheArray";


@interface GMTileManager ()

@property (readonly) NSString *defaultCacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@property CGImageRef errorTileImage;
@property NSMutableDictionary *tileCache;
@property NSOperationQueue *tileLoadQueue;
@property NSInteger currentZoomLevel;

- (void)loadTileFromDiskCache:(GMTile *)tile;
- (void)downloadTile:(GMTile *)tile;
- (NSString *)cachePathForTile:(GMTile *)tile;

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
    self.tileLoadQueue.maxConcurrentOperationCount = 16;


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

    self.currentZoomLevel = zoomLevel;

    NSMutableDictionary *cacheDictionary = [self.tileCache objectForKey:[NSNumber numberWithInteger:zoomLevel]];
    NSMutableArray *cacheArray;

    if (!cacheDictionary)
    {
        cacheDictionary = NSMutableDictionary.new;
        [self.tileCache setObject:cacheDictionary forKey:[NSNumber numberWithInteger:zoomLevel]];
        cacheArray = NSMutableArray.new;
        [cacheDictionary setObject:cacheArray forKey:kCacheArrayKey];
    }
    else
        cacheArray = [cacheDictionary objectForKey:kCacheArrayKey];

    GMTile *tile;

    tile = [cacheDictionary objectForKey:tileKey];

    if (!tile)
    {
        tile = [GMTile.alloc initWithX:x y:y zoomLevel:zoomLevel];
        [self loadTileFromDiskCache:tile];
        [cacheDictionary setObject:tile forKey:tileKey];
    }

    if (tile.zoomLevel > 4)
    {
        [cacheArray removeObject:tile];
        [cacheArray insertObject:tile atIndex:0];
    }

    if (cacheArray.count > 200)
    {
        GMTile *tileToFlush = cacheArray.lastObject;
        [cacheArray removeLastObject];
        [cacheDictionary removeObjectForKey:tileToFlush.key];
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

                GMTile *parentTile = [[self.tileCache objectForKey:[NSNumber numberWithInteger:parentZoomLevel]] objectForKey:parentTileKey];

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

            [self.tileLoadQueue addOperationWithBlock:^{
                 [self downloadTile:tile];
             }];
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

- (void)downloadTile:(GMTile *)tile
{
    if (tile.zoomLevel != self.currentZoomLevel)
    {
        tile.loading = NO;
        return;
    }

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y]];

    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:120.0];

    req.HTTPShouldUsePipelining = YES;

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
             image = CGImageRetain (self.errorTileImage);

         [NSOperationQueue.mainQueue addOperationWithBlock:^{
              CGImageRelease (tile.image);
              tile.image = image;
              tile.loaded = YES;
              tile.loading = NO;
              tile.completion ();
          }];
     }];

}

@end
