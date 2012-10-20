#import <Foundation/Foundation.h>

@interface GMTileManager : NSObject

@property NSString *tileURLFormat;

- (CGImageRef)tileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

@end
