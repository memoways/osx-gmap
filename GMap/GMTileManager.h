#import <Foundation/Foundation.h>

/**
 This class manages the tiles downloads and caching for a `GMMapView`.
 */
@interface GMTileManager : NSObject

/**
 The tile URL format.

 You may set it globally in your application Info.plist with the key `GMTileURLFormat`.

 The default uses Mapnik CDN.

 It must contain 3 long integer substitutions, in this order: zoomLevel, x and y.

 Only PNG and JPEG are supported. The server must return image/png or image/jpeg
 as Content-Type header.

 You may reorder the substitutions with NSString reorderable arguments (second example).

 Examples:

 - http://otile1.mqcdn.com/tiles/1.0.0/osm/%ld/%ld/%ld.jpg
 - http://mydomain.com/tiles/%2$ld/%3$ld/%1$ld.png
 */
@property NSString *tileURLFormat;

/**
 The absolute path of the directory where tiles will be cached on disk.

 If the directory doesn't exist, it will be created.

 The default is ~/Library/Caches/<yourapp bundle identifier>/GMapTiles.
 */
@property NSString *cacheDirectoryPath;

/**
 If YES, all downloaded tiles will be cached on disk.

 FIXME: AT PRESENT THERE IS NO CACHE CLEANING MECHANISM
 */
@property BOOL diskCacheEnabled;

/**
 Returns a tile image.

 If the tile is not available in the cache, it will be downloaded,
 this function does not block, it will return an image of a tile at a lower
 zoom level matching the requested tile.

 When a download occurs, `completionBlock` will be called when the download
 succeed. If the download fails, the block will not be called.

 @return A newly created image that you must release when done, or NULL if no acceptable tile was found.

 @param x X coordinate of the tile
 @param y Y coordinate of the tile
 @param zoomLevel Zoom level of the tile
 @param completionBlock A block to call if the tile is not available and a download is triggered
 */
- (CGImageRef)createTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completionBlock;

@end
