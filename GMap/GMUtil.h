
#import <Cocoa/Cocoa.h>

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

static inline CGPoint GMCoordinateToPoint(GMCoordinate coordinates)
{
    return CGPointMake(GMLongitudeToX(coordinates.longitude), GMLatitudeToY(coordinates.latitude));
}