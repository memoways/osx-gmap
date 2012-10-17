
#import <Cocoa/Cocoa.h>

@interface GMMapView : NSView


+ (NSString *)tileURLFormat;

@property GMCoordinate centerCoordinate;
@property CGFloat zoomLevel;


@end
