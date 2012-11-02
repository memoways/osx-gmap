#import "GMCoordinate.h"


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