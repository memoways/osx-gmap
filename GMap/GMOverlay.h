#import <Foundation/Foundation.h>

@class GMMapView;

@interface GMOverlay : NSObject

- (void)drawOnMapView:(GMMapView *)mapView inContext:(CGContextRef)ctx;

@end
