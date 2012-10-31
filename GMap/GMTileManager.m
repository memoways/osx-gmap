#import "GMTileManager.h"
#import "GMMapView.h"
#import "GMTile.h"
#import <curl/curl.h>

const NSString *kCacheArrayKey = @"cacheArray";

@interface GMConnection : NSObject

@property CURL *CURLHandle;

@end

@implementation GMConnection

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.CURLHandle = curl_easy_init();

    if (!self.CURLHandle)
        return nil;

    return self;
}

- (void)dealloc
{
    curl_easy_cleanup(self.CURLHandle);
}

@end

@interface GMTileManager ()

@property (readonly) NSString *defaultCacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@property NSInteger currentZoomLevel;

@property NSMutableDictionary *tileCache;
@property NSOperationQueue *tileLoadQueue;
@property NSMutableArray *connections;
@property NSInteger connectionIndex;

- (void)loadTileFromDiskCache:(GMTile *)tile;
- (void)queueTileDownload:(GMTile *)tile;
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

    self.connections = NSMutableArray.new;

    for (int i = 0; i < 16; i++)
    {
        GMConnection *con = GMConnection.new;

        if (!con)
        {
            self.connections = nil;
            return nil;
        }

        [self.connections addObject:con];
    }

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
                 [self queueTileDownload:tile];
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

- (void)queueTileDownload:(GMTile *)tile
{
    if (tile.zoomLevel != self.currentZoomLevel)
    {
        tile.loading = NO;
        return;
    }

    [self.tileLoadQueue addOperationWithBlock:^{
         @autoreleasepool {
             [self downloadTile:tile];
         }
     }];
}


static size_t writeData(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    size_t len = size * nmemb;
    NSMutableData *data = (__bridge NSMutableData *)userdata;

    [data appendBytes:ptr length:len];

    return len;
}

- (const CFStringRef)fetchTileImageAtURL:(NSString *)urlString writeInData:(NSMutableData *)data
{
    CFStringRef type = NULL;

    GMConnection *con;

    @synchronized(self.connections)
    {
        self.connectionIndex = (self.connectionIndex + 1) % self.connections.count;
        con = self.connections[self.connectionIndex];
    }

    @synchronized(con)
    {
        CURL *handle = con.CURLHandle;

        curl_easy_setopt(handle, CURLOPT_URL, [urlString cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, data);
        curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, writeData);
        curl_easy_setopt(handle, CURLOPT_TIMEOUT, 5);

        if (!curl_easy_perform(handle))
        {
            char *contentType;
            curl_easy_getinfo(handle, CURLINFO_CONTENT_TYPE, &contentType);

            if (contentType)
            {
                CFStringRef MIMEType = CFStringCreateWithCStringNoCopy(NULL, contentType, kCFStringEncodingUTF8, kCFAllocatorNull);
                CFStringRef UTType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, kUTTypeImage);

                if (UTType && UTTypeEqual(UTType, kUTTypeJPEG))
                    type = kUTTypeJPEG;
                else if (UTType && UTTypeEqual(UTType, kUTTypePNG))
                    type = kUTTypePNG;

                CFRelease(UTType);
                CFRelease(MIMEType);
            }
        }
    }

    return type;
}


- (void)downloadTile:(GMTile *)tile
{
    CGImageRef image = NULL;

    if (tile.zoomLevel != self.currentZoomLevel)
    {
        tile.loading = NO;
        return;
    }

    NSString *path = [self cachePathForTile:tile];
    NSString *url = [NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y];

    NSMutableData *data = NSMutableData.new;
    const CFStringRef imageType = [self fetchTileImageAtURL:url writeInData:data];

    if (imageType && data.length)
    {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

        if (provider)
        {
            if (imageType == kUTTypePNG)
                image = CGImageCreateWithPNGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
            else
                image = CGImageCreateWithJPEGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);

            CFRelease(provider);
        }

        if (image && self.diskCacheEnabled)
            [data writeToFile:path atomically:YES];
    }

    [NSOperationQueue.mainQueue addOperationWithBlock:^{
         CGImageRelease (tile.image);
         tile.image = image;
         tile.loaded = image != NULL;
         tile.loading = NO;

         if (image)
             tile.completion ();
     }];

}

@end
