#import <Cocoa/Cocoa.h>

@protocol GMMapViewDelegate;
@class GMOverlay;

/**
 `GMMapView` is the base of GMap. It renders the map and manage it's overlays.
 */

@interface GMMapView : NSView

///---------------
/// @name Delegate
///---------------

@property (nonatomic, assign) id<GMMapViewDelegate> delegate;

///--------------------------
/// @name Tiles configuration
///--------------------------

/**
 The tile URL format.

 You may set it globally in your application Info.plist with the key `GMTileURLFormat`.

 The default uses Mapnik CDN.

 It must contain 3 long integer substitutions, in this order: zoomLevel, x and y.

 Only PNG and JPEG are supported. The server must return image/png or image/jpeg
 as Content-Type header.

 You may reorder the substitutions with NSString reorderable arguments (second example).

 Examples:

 - http://otile1.mqcdn.com/tiles/1.0.0/osm/%ld/%ld/%ld.jpg
 - http://mydomain.com/tiles/%2$ld/%3$ld/%1$ld.png
 */
@property (nonatomic) NSString *tileURLFormat;

/**
 The absolute path of the directory where tiles will be cached on disk.

 If the directory doesn't exist, it will be created.

 The default is ~/Library/Caches/<yourapp bundle identifier>/GMapTiles.
 */
@property (nonatomic) NSString *tileCacheDirectoryPath;

/**
 If YES, all downloaded tiles will be cached on disk.

 FIXME: AT PRESENT THERE IS NO CACHE CLEANING MECHANISM
 */
@property (nonatomic) BOOL cacheTilesOnDisk;

///------------
/// @name State
///------------

/**
 The coordinate of the center point of the map view.
 */
@property (nonatomic) GMCoordinate centerCoordinate;

/**
 Convenience property to manage latitude.
 */
@property (nonatomic) GMFloat centerLatitude;

/**
 Convenience property to manage longitude.
 */
@property (nonatomic) GMFloat centerLongitude;

/**
 The zoom level between 0 and 18, inclusive.
 If you set a value outside those bounds it will be clamped.
 */
@property (nonatomic) GMFloat zoomLevel;

///----------------
/// @name Behaviour
///----------------

/**
 If set to `YES`, zoomLevel will be rounded to the nearest integer.
 This is usefull if you want to provide a map that is never interpolated.

 `NO` by default.
 */
@property (nonatomic) BOOL roundZoomLevel;

/**
 If set to `YES`, panning will be enabled by dragging the map.

 `YES` by default.
 */
@property (nonatomic) BOOL panningEnabled;

/**
 If set to `YES`, zooming with the mouse scroll will be enabled.

 `YES` by default.
 */
@property (nonatomic) BOOL scrollZoomEnabled;

@property (nonatomic) BOOL overlaysDraggable;
@property (nonatomic) BOOL overlaysClickable;

///---------------
/// @name Overlays
///---------------

@property (nonatomic, readonly) NSArray *overlays;

- (void)addOverlay:(GMOverlay *)overlay;
- (void)addOverlays:(NSArray *)overlays;

- (void)removeOverlay:(GMOverlay *)overlay;
- (void)removeOverlays:(NSArray *)overlays;

- (void)exchangeOverlayAtIndex:(NSUInteger)index1 withOverlayAtIndex:(NSUInteger)index2;

- (void)insertOverlay:(GMOverlay *)overlay aboveOverlay:(GMOverlay *)sibling;
- (void)insertOverlay:(GMOverlay *)overlay belowOverlay:(GMOverlay *)sibling;
- (void)insertOverlay:(GMOverlay *)overlay atIndex:(NSUInteger)index;

///---------------
/// @name Utilities
///---------------

- (GMMapPoint)convertViewLocationToMapPoint:(CGPoint)locationInView;

@end

@protocol GMMapViewDelegate <NSObject>
@optional

- (GMMapPoint)mapView:(GMMapView *)mapView willPanCenterToMapPoint:(GMMapPoint)proposedCenter;
- (GMFloat)mapView:(GMMapView *)mapView willScrollZoomToLevel:(GMFloat)proposedZoomLevel;

- (void)mapView:(GMMapView *)mapView overlayClicked:(GMOverlay *)overlay;
- (BOOL)mapView:(GMMapView *)mapView shouldDragOverlay:(GMOverlay *)overlay;
- (GMMapPoint)mapView:(GMMapView *)mapView willDragOverlay:(GMOverlay *)overlay toMapPoint:(GMMapPoint)proposedPoint;

@end
