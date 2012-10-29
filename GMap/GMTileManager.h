#import <Foundation/Foundation.h>

@interface GMTileManager : NSObject

+ (id)sharedTileManager;

@property NSString *tileURLFormat;
@property NSString *cacheDirectoryPath;
@property BOOL diskCacheEnabled;


- (CGImageRef)createTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completion;

@end
