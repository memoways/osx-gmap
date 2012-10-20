#import <Cocoa/Cocoa.h>

@class GMTileManager;

@interface GMMapView : NSView

@property GMTileManager *tileManager;

@property GMCoordinate centerCoordinate;
@property CGFloat zoomLevel;


@end
