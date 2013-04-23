#import <Foundation/Foundation.h>

#ifndef GM_INLINE
#define GM_INLINE NS_INLINE
#endif

#ifndef GM_EXTERN
#define GM_EXTERN extern
#endif

static const double kTileSize = 256.0; // in pixel
static const double kEquatorLength = 40075016.686; // in meters

typedef double GMFloat;

typedef struct
{
    GMFloat x;
    GMFloat y;
} GMMapPoint;

GM_EXTERN GMMapPoint GMMapPointZero;

GM_INLINE GMMapPoint GMMapPointMake(GMFloat x, GMFloat y)
{
    GMMapPoint pt;

    pt.x = x;
    pt.y = y;
    return pt;
}

GM_INLINE NSString *NSStringFromMapPoint(GMMapPoint point)
{
    return [NSString stringWithFormat:@"{%.10f, %.10f}", point.x, point.y];
}

@interface NSValue (GMMapPoint)

- (GMMapPoint)mapPointValue;

+ (NSValue *)valueWithMapPoint:(GMMapPoint)mapPoint;
- (id)initWithMapPoint:(GMMapPoint)mapPoint;

@end

typedef struct
{
    GMMapPoint topLeft;
    GMMapPoint bottomRight;
} GMMapBounds;

GM_EXTERN GMMapBounds GMMapBoundsZero;

GM_INLINE GMMapBounds GMMapBoundsMake(GMFloat topLeftX, GMFloat topLeftY, GMFloat bottomRightX, GMFloat bottomRightY)
{
    GMMapBounds bounds;

    bounds.topLeft.x = topLeftX;
    bounds.topLeft.y = topLeftY;
    bounds.bottomRight.x = bottomRightX;
    bounds.bottomRight.y = bottomRightY;
    return bounds;
}

GM_INLINE GMMapBounds GMMapBoundsMakeWithMapPoints(GMMapPoint topLeft, GMMapPoint bottomRight)
{
    GMMapBounds bounds;

    bounds.topLeft = topLeft;
    bounds.bottomRight = bottomRight;
    return bounds;
}

GM_INLINE NSRect NSRectFromMapBounds(GMMapBounds bounds)
{
	return NSMakeRect(bounds.topLeft.x, bounds.topLeft.y, bounds.bottomRight.x - bounds.topLeft.x, bounds.bottomRight.y - bounds.topLeft.y);
}

GM_INLINE GMMapBounds GMMapBoundsFromNSRect(NSRect rect)
{
	return GMMapBoundsMake(NSMinX(rect), NSMinY(rect), NSMaxX(rect), NSMaxY(rect));
}

GM_INLINE NSString *NSStringFromMapBounds(GMMapBounds bounds)
{
    return [NSString stringWithFormat:@"{{%.10f, %.10f}, {%.10f, %.10f}}", bounds.topLeft.x, bounds.topLeft.x,
            bounds.bottomRight.x, bounds.bottomRight.y];
}

GM_INLINE GMMapBounds GMMapBoundsAddMapPoint(GMMapBounds bounds, GMMapPoint pt)
{
    if (bounds.topLeft.x > pt.x)
        bounds.topLeft.x = pt.x;
    else if (bounds.bottomRight.x < pt.x)
        bounds.bottomRight.x = pt.x;

    if (bounds.topLeft.y > pt.y)
        bounds.topLeft.y = pt.y;
    else if (bounds.bottomRight.y < pt.y)
        bounds.bottomRight.y = pt.y;

    return bounds;
}

GM_INLINE GMMapBounds GMMapBoundsAddMapBounds(GMMapBounds bounds, GMMapBounds boundsToAdd)
{
    bounds.topLeft.x = MIN(bounds.topLeft.x, boundsToAdd.topLeft.x);
    bounds.topLeft.y = MIN(bounds.topLeft.y, boundsToAdd.topLeft.y);

    bounds.bottomRight.x = MAX(bounds.bottomRight.x, boundsToAdd.bottomRight.x);
    bounds.bottomRight.y = MAX(bounds.bottomRight.y, boundsToAdd.bottomRight.y);

    return bounds;
}

GM_INLINE BOOL GMMapBoundsContainsMapPoint(GMMapBounds bounds, GMMapPoint pt)
{
    return (bounds.topLeft.x <= pt.x && bounds.bottomRight.x >= pt.x
            && bounds.topLeft.y <= pt.y && bounds.bottomRight.y >= pt.y);
}

GM_INLINE BOOL GMMapBoundsInterectsMapBounds(GMMapBounds a, GMMapBounds b)
{
    return !(b.bottomRight.x < a.topLeft.x
             || b.topLeft.x > a.bottomRight.x
             || b.bottomRight.y < a.topLeft.y
             || b.topLeft.y > a.bottomRight.y);
}

GM_INLINE GMMapPoint GMMapBoundsCenterPoint(GMMapBounds bounds)
{
	return GMMapPointMake((bounds.topLeft.x + bounds.bottomRight.x) / 2, (bounds.topLeft.y + bounds.bottomRight.y) / 2);
}

GM_INLINE GMFloat GMMapBoundsSemiPerimeter(GMMapBounds bounds)
{
    return bounds.bottomRight.x - bounds.topLeft.x + bounds.bottomRight.y - bounds.topLeft.y;
}

GM_INLINE GMMapPoint GMMapBoundsCenterPoint(GMMapBounds bounds)
{
    return GMMapPointMake(bounds.topLeft.x + (bounds.bottomRight.x - bounds.topLeft.x) / 2.0, bounds.topLeft.y + (bounds.bottomRight.y - bounds.topLeft.y) / 2.0);
}

GM_INLINE GMFloat GMMapBoundsArea(GMMapBounds bounds)
{
    return (bounds.bottomRight.x - bounds.topLeft.x) * (bounds.bottomRight.y - bounds.topLeft.y);
}

@interface NSValue (GMMapBounds)

- (GMMapBounds)mapBoundsValue;

+ (NSValue *)valueWithMapBounds:(GMMapBounds)mapBounds;
- (id)initWithMapBounds:(GMMapBounds)mapBounds;

@end

typedef struct
{
    GMFloat latitude;
    GMFloat longitude;
} GMCoordinate;

GM_INLINE GMCoordinate GMCoordinateMake(GMFloat latitude, GMFloat longitude)
{
    GMCoordinate result;

    result.latitude = latitude;
    result.longitude = longitude;

    return result;
}

GM_INLINE GMFloat GMLongitudeToX(GMFloat longitude)
{
    return (longitude + 180.0) / 360.0;
}

GM_INLINE GMFloat GMLatitudeToY(GMFloat latitude)
{
    GMFloat lat = latitude * M_PI / 180.0;

    return (1.0 - log(tan(lat) + 1.0 / cos(lat)) / M_PI) / 2.0;
}

GM_INLINE GMFloat GMXToLongitude(GMFloat x)
{
    return x * 360.0 - 180.0;
}

GM_INLINE GMFloat GMYToLatitude(GMFloat y)
{
    GMFloat n = M_PI - 2.0 * M_PI * y;

    return (180.0 / M_PI) * atan(0.5 * (exp(n) - exp(-n)));
}

GM_INLINE GMMapPoint GMCoordinateToMapPoint(GMCoordinate coordinates)
{
    return GMMapPointMake(GMLongitudeToX(coordinates.longitude), GMLatitudeToY(coordinates.latitude));
}

GM_INLINE GMCoordinate GMMapPointToCoordinate(GMMapPoint point)
{
    return GMCoordinateMake(GMYToLatitude(point.y), GMXToLongitude(point.x));
}

GM_INLINE NSString *NSStringFromCoordinate(GMCoordinate coordinate)
{
    return [NSString stringWithFormat:@"{%.10f, %.10f}", coordinate.latitude, coordinate.longitude];
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


GM_INLINE GMCoordinateBounds GMCoordinateBoundsMake(GMFloat southWestLatitude, GMFloat southWestLongitude, GMFloat northEastLatitude, GMFloat northEastLongitude)
{
    GMCoordinateBounds result;

    result.southWest.latitude = southWestLatitude;
    result.southWest.longitude = southWestLongitude;
    result.northEast.latitude = northEastLatitude;
    result.northEast.longitude = northEastLongitude;

    return result;
}

GM_INLINE GMMapBounds GMCoordinateBoundsToMapBounds(GMCoordinateBounds bounds)
{
    GMMapPoint southWest = GMCoordinateToMapPoint(bounds.southWest);
    GMMapPoint northEast = GMCoordinateToMapPoint(bounds.northEast);

    return GMMapBoundsMake(southWest.x, northEast.y, northEast.x - southWest.x, southWest.y - northEast.y);
}

@interface NSValue (GMCoordinateBounds)

- (GMCoordinateBounds)coordinateBoundsValue;

+ (NSValue *)valueWithCoordinateBounds:(GMCoordinateBounds)bounds;
- (id)initWithCoordinateBounds:(GMCoordinateBounds)bounds;

@end
