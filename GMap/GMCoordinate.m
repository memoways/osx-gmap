#import "GMCoordinate.h"

GMMapPoint GMMapPointZero = (GMMapPoint){0, 0};
GMMapBounds GMMapBoundsZero = (GMMapBounds){{0, 0}, {0, 0}};

@implementation NSValue (GMMapPoint)

+ (NSValue *)valueWithMapPoint:(GMMapPoint)mapPoint
{
    return [NSValue valueWithBytes:&mapPoint objCType:@encode(GMMapPoint)];
}

- (id)initWithMapPoint:(GMMapPoint)mapPoint
{
    return [self initWithBytes:&mapPoint objCType:@encode(GMMapPoint)];
}

- (GMMapPoint)mapPointValue
{
    GMMapPoint res;

    [self getValue:&res];
    return res;
}

@end

@implementation NSValue (GMMapBounds)

+ (NSValue *)valueWithMapBounds:(GMMapBounds)mapBounds
{
    return [NSValue valueWithBytes:&mapBounds objCType:@encode(GMMapBounds)];
}

- (id)initWithMapBounds:(GMMapBounds)mapBounds
{
    return [self initWithBytes:&mapBounds objCType:@encode(GMMapBounds)];
}

- (GMMapBounds)mapBoundsValue
{
    GMMapBounds res;

    [self getValue:&res];
    return res;
}

@end

@implementation NSValue (GMCoordinate)

+ (NSValue *)valueWithCoordinate:(GMCoordinate)coordinate
{
    return [NSValue valueWithBytes:&coordinate objCType:@encode(GMCoordinate)];
}

- (id)initWithCoordinate:(GMCoordinate)coordinate
{
    return [self initWithBytes:&coordinate objCType:@encode(GMCoordinate)];
}

- (GMCoordinate)coordinateValue
{
    GMCoordinate res;

    [self getValue:&res];
    return res;
}

@end

@implementation NSValue (GMCoordinateBounds)

+ (NSValue *)valueWithCoordinateBounds:(GMCoordinateBounds)bounds
{
    return [NSValue valueWithBytes:&bounds objCType:@encode(GMCoordinateBounds)];
}

- (id)initWithCoordinateBounds:(GMCoordinateBounds)bounds
{
    return [self initWithBytes:&bounds objCType:@encode(GMCoordinateBounds)];
}

- (GMCoordinateBounds)coordinateBoundsValue
{
    GMCoordinateBounds res;

    [self getValue:&res];
    return res;
}

@end
