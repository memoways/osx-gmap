#import <Foundation/Foundation.h>

@interface GMTileManager : NSObject


@property NSString *tileURLFormat;
@property NSString *cacheDirectoryPath;
@property BOOL diskCacheEnabled;


- (CGImageRef)createTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completionBlock;

@end
