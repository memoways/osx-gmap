#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface GMTile : NSObject

@property (nonatomic, readonly) NSInteger x;
@property (nonatomic, readonly) NSInteger y;
@property (nonatomic, readonly) NSInteger zoomLevel;
@property (nonatomic, readonly) NSString *key;


@property (nonatomic) BOOL loaded;
@property (nonatomic) BOOL loading;
@property (nonatomic) CGImageRef image;


@property (nonatomic) NSURLResponse *loadResponse;
@property (nonatomic) NSMutableData *loadData;
@property (nonatomic) CFStringRef UTType;

@property (nonatomic, copy) void (^completion)(void);


- (id)initWithX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

+ (NSString *)tileKeyForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel;

@end
