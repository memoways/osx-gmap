#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GMTile : NSObject

@property (readonly) volatile NSInteger x;
@property (readonly) volatile NSInteger y;
@property (readonly) volatile NSInteger zoomLevel;
@property (readonly) volatile NSString *key;


@property volatile BOOL loaded;
@property volatile BOOL loading;
@property volatile CGImageRef image;

@property (copy) volatile void (^completion)(void);


- (id)initWithX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

+ (NSString *)tileKeyForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

@end
