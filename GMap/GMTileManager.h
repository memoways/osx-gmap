#import <Foundation/Foundation.h>

@interface GMTileManager : NSObject

@property (nonatomic) NSString *tileURLFormat;
@property (nonatomic) NSString *cacheDirectoryPath;

- (CGImageRef)createTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completion;

@end
