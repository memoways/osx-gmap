#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMCircle : GMOverlay

@property (nonatomic) GMCoordinate centerCoordinate;
@property (nonatomic) CGFloat radius;

@property (nonatomic) NSColor *fillColor;

@property (nonatomic) CGFloat strokeWidth;
@property (nonatomic) NSColor *strokeColor;

@property (nonatomic) CGFloat centerPointWidth;
@property (nonatomic) NSColor *centerPointColor;


@end
