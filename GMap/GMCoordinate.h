#import <Foundation/Foundation.h>


static const double kTileSize = 256.0; // in pixel
static const double kEquatorLength = 40075016.686; // in meters

typedef double GMFloat;

typedef struct
{
    GMFloat x;
    GMFloat y;
} GMMapPoint;

static inline GMMapPoint GMMapPointMake(GMFloat x, GMFloat y)
{
}

typedef struct
{
    GMFloat latitude;
    GMFloat longitude;
} GMCoordinate;

static inline GMCoordinate GMCoordinateMake(GMFloat latitude, GMFloat longitude)
{
    GMCoordinate result;

    result.latitude = latitude;
    result.longitude = longitude;

    return result;
}

static inline GMFloat GMLongitudeToX(GMFloat longitude)
{
    return (longitude + 180.0) / 360.0;
}

static inline GMFloat GMLatitudeToY(GMFloat latitude)
{
    GMFloat lat = latitude * M_PI / 180.0;

    return (1.0 - log(tan(lat) + 1.0 / cos(lat)) / M_PI) / 2.0;
}

static inline GMFloat GMXToLongitude(GMFloat x)
{
    return x * 360.0 - 180.0;
}

static inline GMFloat GMYToLatitude(GMFloat y)
{
    GMFloat n = M_PI - 2.0 * M_PI * y;

    return (180.0 / M_PI) * atan(0.5 * (exp(n) - exp(-n)));
}

static inline GMMapPoint GMCoordinateToPoint(GMCoordinate coordinates)
{
    return GMMapPointMake(GMLongitudeToX(coordinates.longitude), GMLatitudeToY(coordinates.latitude));
}

static inline GMCoordinate GMMapPointToCoordinate(GMMapPoint point)
{
    return GMCoordinateMake(GMYToLatitude(point.y), GMXToLongitude(point.x));
}

static inline NSString *NSStringFromGMCoordinate(GMCoordinate coordinate)
{
    return [NSString stringWithFormat:@"%.10f - %.10f", coordinate.latitude, coordinate.longitude];
}

@interface NSValue (GMCoordinate)

- (GMCoordinate)coordinateValue;

+ (NSValue *)valueWithCoordinate:(GMCoordinate)coordinate;
- (id)initWithCoordinate:(GMCoordinate)coordinate;

@end


typedef struct
{
    GMCoordinate southWest;
    GMCoordinate northEast;
} GMCoordinateBounds;


static inline GMCoordinateBounds GMCoordinateBoundsMake(GMFloat southWestLatitude, GMFloat southWestLongitude, GMFloat northEastLatitude, GMFloat northEastLongitude)
{
    GMCoordinateBounds result;

    result.southWest.latitude = southWestLatitude;
    result.southWest.longitude = southWestLongitude;
    result.northEast.latitude = northEastLatitude;
    result.northEast.longitude = northEastLongitude;

    return result;
}

static inline GMMapRect GMCoordinateBoundsToRect(GMCoordinateBounds bounds)
{
    GMMapPoint southWest = GMCoordinateToPoint(bounds.southWest);
    GMMapPoint northEast = GMCoordinateToPoint(bounds.northEast);

    return GMMapRectMake(southWest.x, northEast.y, northEast.x - southWest.x, southWest.y - northEast.y);
}

@interface NSValue (GMCoordinateBounds)

- (GMCoordinateBounds)coordinateBoundsValue;

+ (NSValue *)valueWithCoordinateBounds:(GMCoordinateBounds)bounds;
- (id)initWithCoordinateBounds:(GMCoordinateBounds)bounds;

@end
