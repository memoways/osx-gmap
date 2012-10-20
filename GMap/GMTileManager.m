#import "GMTileManager.h"
#import "GMMapView.h"

@interface GMTileManager ()

@property (readonly) NSString *cacheDirectoryPath;
@property (readonly) NSString *defaultTileURLFormat;

@end

@implementation GMTileManager

- (id)init
{
    if (!(self = [super init]))
        return nil;

    self.tileURLFormat = self.defaultTileURLFormat;

    return self;
}

- (NSString *)defaultTileURLFormat
{
    NSString *s = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"GMTileURLFormat"];

    if (!s)
        s = [[NSBundle bundleForClass:[GMTileManager class]] objectForInfoDictionaryKey:@"GMTileURLFormat"];

    return s;
}

- (NSString *)cacheDirectoryPath
{
    NSString *path = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

    if ([paths count])
    {
        NSString *bundleName =
            [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
    }

    assert(path);
    path = [path stringByAppendingPathComponent:@"GMap-tiles/"];

    if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

    return path;
}


- (CGImageRef)tileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel
{
    NSString *filename = [NSString stringWithFormat:@"%ld-%ld-%ld.jpg", (long)zoomLevel, (long)x, (long)y];
    NSString *path = [self.cacheDirectoryPath stringByAppendingPathComponent:filename];

    CGImageRef image;

    @synchronized(self)
    {
        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:self.tileURLFormat, (long)zoomLevel, (long)x, (long)y]];
            NSData *data = [NSData dataWithContentsOfURL:url];
            [data writeToFile:path atomically:YES];
        }

        if (![[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            return NULL;
        }

        NSURL *fileURL = [NSURL fileURLWithPath:path];
        CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);
        image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
    }
    return image;
}

@end
