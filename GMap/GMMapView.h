#import <Cocoa/Cocoa.h>

@class GMTileManager;

@interface GMMapView : NSView

@property (nonatomic) GMTileManager *tileManager;

@property (nonatomic) GMCoordinate centerCoordinate;
@property (nonatomic) CGFloat zoomLevel;


@end
