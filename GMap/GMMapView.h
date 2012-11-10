#import <Cocoa/Cocoa.h>

@protocol GMMapViewDelegate;
@class GMOverlay;

/**
 GMMapView is the base of GMap. It renders the map and manage it's overlays.
 */
@interface GMMapView : NSView

///---------------
/// @name Delegate
///---------------

/**
 The receiver’s delegate.

 A map view sends messages to its delegate regarding user events and overlays.
 */
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

 @warning FIXME: AT PRESENT THERE IS NO CACHE CLEANING MECHANISM
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

/**
 If set to `YES`, overlays will be draggable.

 `YES` by default.
 */
@property (nonatomic) BOOL overlaysDraggable;

/**
 If set to `YES`, overlays will be clickable.

 Clickable overlays does nothing except calling [GMMapViewDelegate mapView:overlayClicked:] on the delegate when
 an overlay is clicked.

 A click is defined by a `mouseDown` followed by a `mouseUp` with no movement between the two.

 `YES` by default.
 */
@property (nonatomic) BOOL overlaysClickable;

///---------------
/// @name Overlays
///---------------


/**
 The overlay objects currently associated with the map view. (read-only)

 All objects in this array must be subclasses of GMOverlay.

 The z-ordering of the overlays is determined by the order in this array. Thus, the overlay at index 1 is
 drawn above the overlay at index 0.
 */
@property (nonatomic, readonly) NSArray *overlays;

/**
 Add an overlay.

 The overlay is added at the end of the overlays array.

 @see overlays
 */
- (void)addOverlay:(GMOverlay *)overlay;

/**
 Add an array of overlays.

 All objects in the array must be subclass of GMOverlay.

 @see overlays
 */
- (void)addOverlays:(NSArray *)overlays;

/**
 Remove an overlay.

 @see overlays
 */
- (void)removeOverlay:(GMOverlay *)overlay;

/**
 Remove overlays.

 @see overlays
 */
- (void)removeOverlays:(NSArray *)overlays;

/**
 Change the ordering of two overlays.

 @see overlays
 */
- (void)exchangeOverlayAtIndex:(NSUInteger)index1 withOverlayAtIndex:(NSUInteger)index2;

/**
 Insert an overlay above another one.

 @see overlays
 */
- (void)insertOverlay:(GMOverlay *)overlay aboveOverlay:(GMOverlay *)sibling;

/**
 Insert an overlay below another one.

 @see overlays
 */
- (void)insertOverlay:(GMOverlay *)overlay belowOverlay:(GMOverlay *)sibling;

/**
 Insert an overlay at a specific index.

 @see overlays
 */
- (void)insertOverlay:(GMOverlay *)overlay atIndex:(NSUInteger)index;

///---------------
/// @name Utilities
///---------------

/**
 Convert a point from the receiver to the map coordinate system.
 */
- (GMMapPoint)convertViewLocationToMapPoint:(CGPoint)locationInView;

/**
 Convert a point from the map coordinate system to the receiver.
 */
- (CGPoint)convertMapPointToViewLocation:(GMMapPoint)mapPoint;

@end

/**
 The `GMMapViewDelegate` protocol defines a set of optional methods that you can use to receive map-related messages.

 Before releasing a GMMapView object for which you have a set a delegate, set that object's `delegate` property to `nil`.
 */
@protocol GMMapViewDelegate <NSObject>
@optional

/**
 Called when the map is clicked.

 @param mapView The mapView containing the overlay.
 @param mapPoint The mapPoint where the mapView was clicked.
 @param location The location in view of the click event.

 */
- (void)mapView:(GMMapView *)mapView clickedAtPoint:(GMMapPoint)mapPoint locationInView:(CGPoint)location;

/**
 Called when the view is panned with the mouse.

 This is not called when the centerCoordinate is set programatically.

 You may override the `proposedCenter` by returning another value.

 @param mapView The mapView for which the centerPoint is about to change.
 @param proposedCenter The new centerPoint.

 @return The centerPoint that will be set on the mapView.
 */
- (GMMapPoint)mapView:(GMMapView *)mapView willPanCenterToMapPoint:(GMMapPoint)proposedCenter;

/**
 Called when the view zoomed with the scrollwheel.

 This is not called when the zoomLevel is set programatically.

 You may override the `proposedZoomLevel` by returning another value.

 @param mapView The mapView for which the zoom level is about to change.
 @param proposedZoomLevel The new zoomLevel.

 @return The zoomLevel that will be set on the mapView.
 */
- (GMFloat)mapView:(GMMapView *)mapView willScrollZoomToLevel:(GMFloat)proposedZoomLevel;

/**
 Called when a click occurs within an overlay bounds.

 @param mapView The mapView containing the overlay.
 @param overlay The overlay that was clicked.
 @param location The location in view of the click event.
 
 */
- (void)mapView:(GMMapView *)mapView overlayClicked:(GMOverlay *)overlay locationInView:(CGPoint)location;

/**
 Called when an overlay is about to be dragged.

 @param mapView The mapView containing the overlay.
 @param overlay The overlay for which dragging is about to start.

 @return `YES` to allow the drag, `NO` to cancel it.
 */
- (BOOL)mapView:(GMMapView *)mapView shouldDragOverlay:(GMOverlay *)overlay;

/**
 Called when an overlay is dragged.

 @param mapView The mapView containing the overlay.
 @param overlay The overlay being dragged.
 @param proposedPoint The mapPoint to where this overlay will be dragged.

 @return The new mapPoint of the overlay.
 */
- (GMMapPoint)mapView:(GMMapView *)mapView willDragOverlay:(GMOverlay *)overlay toMapPoint:(GMMapPoint)proposedPoint;

@end
