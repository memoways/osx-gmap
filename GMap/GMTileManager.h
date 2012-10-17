
#import <Foundation/Foundation.h>

@interface GMTileManager : NSObject

- (CGImageRef)tileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

@end
