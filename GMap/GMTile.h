#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GMTile : NSObject

@property (readonly) NSInteger x;
@property (readonly) NSInteger y;
@property (readonly) NSInteger zoomLevel;
@property (readonly) NSString *key;


@property BOOL loaded;
@property BOOL loading;
@property CGImageRef image;

@property (copy) void(^completion)(void);


- (id)initWithX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

+ (NSString *)tileKeyForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

@end

