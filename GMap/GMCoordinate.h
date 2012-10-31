#import <Foundation/Foundation.h>


static const CGFloat kTileSize = 256.0;


typedef struct
{
    CGFloat latitude;
    CGFloat longitude;
} GMCoordinate;


static inline GMCoordinate GMCoordinateMake(CGFloat latitude, CGFloat longitude)
{
    GMCoordinate result;

    result.latitude = latitude;
    result.longitude = longitude;

    return result;
}

static inline CGFloat GMLongitudeToX(CGFloat longitude)
{
    return (longitude + 180.0) / 360.0;
}

static inline CGFloat GMLatitudeToY(CGFloat latitude)
{
    CGFloat lat = latitude * M_PI / 180.0;

    return (1.0 - log(tan(lat) + 1.0 / cos(lat)) / M_PI) / 2.0;
}

static inline CGFloat GMXToLongitude(CGFloat x)
{
    return x * 360.0 - 180.0;
}

static inline CGFloat GMYToLatitude(CGFloat y)
{
    CGFloat n = M_PI - 2.0 * M_PI * y;

    return (180.0 / M_PI) * atan(0.5 * (exp(n) - exp(-n)));
}

static inline CGPoint GMCoordinateToPoint(GMCoordinate coordinates)
{
    return CGPointMake(GMLongitudeToX(coordinates.longitude), GMLatitudeToY(coordinates.latitude));
}

static inline GMCoordinate GMPointToCoordinate(CGPoint point)
{
    return GMCoordinateMake(GMYToLatitude(point.y), GMXToLongitude(point.x));
}
