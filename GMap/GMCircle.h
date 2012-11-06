#import <Foundation/Foundation.h>
#import "GMOverlay.h"

@interface GMCircle : GMOverlay

@property (nonatomic) GMFloat radius;

@property (nonatomic) NSColor *fillColor;

@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) NSColor *strokeColor;

@property (nonatomic) CGFloat centerPointSize;
@property (nonatomic) NSColor *centerPointColor;


@end
