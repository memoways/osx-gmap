#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMPolygon : GMOverlay

- (void)addPoint:(GMCoordinate)coordinate;

@property (nonatomic) NSMutableArray *points;

@property (nonatomic) BOOL shouldClose;
@property (nonatomic) NSColor *fillColor;

@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) NSColor *strokeColor;

@end
