#import <Cocoa/Cocoa.h>

@class GMTileManager;

/**
 `GMMapView` is the base of GMap. It renders the map and manage it's overlays.

 ## Tile Manager

 Each instance of `GMMapView` uses it's own tile manager by default.
 You should not share a single `tileManager` instance between multiple `GMMapView` instances except if
 the map instances are displaying the same map point
 (same `zoomLevel` and `centerCoordinate`, overlays doesn't need to be in sync).
 */

@interface GMMapView : NSView

///-------------------------
/// @name Base configuration
///-------------------------

/**
 The tile manager instance providing tile to this map view.

 You usually do not need to override this.
 */
@property (nonatomic) GMTileManager *tileManager;

///----------------
/// @name Behaviour
///----------------

/**
 If set to `YES`, zoomLevel will be rounded to the nearest integer.
 This is usefull if you want to provide a map that is never interpolated.

 `NO` by default.
 */
@property (nonatomic) BOOL shouldRoundZoomLevel;

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
@property (nonatomic) CGFloat centerLatitude;

/**
 Convenience property to manage longitude.
 */
@property (nonatomic) CGFloat centerLongitude;

/**
 The zoom level between 0 and 18, inclusive.
 If you set a value outside those bounds it will be clamped.
 */
@property (nonatomic) CGFloat zoomLevel;


@end
