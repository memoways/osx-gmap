#import <Foundation/Foundation.h>

@class GMMapView;

@interface GMOverlay : NSObject < NSCopying >

@property (nonatomic) NSUInteger version;

@property (nonatomic) GMCoordinate coordinate;

@property (nonatomic) GMMapPoint mapPoint;
@property (nonatomic) GMMapBounds mapBounds;

/**
 Overlay visibility.

 GMOverlayVisible: the map view decides when the overlay is visible (default value)
 */
typedef NS_ENUM(NSInteger, GMOverlayVisibility) { GMOverlayHidden = -1, GMOverlayVisible = 0, GMOverlayAlwaysVisible = +1 };

@property (nonatomic) GMOverlayVisibility visibility;

@property (nonatomic) BOOL selected;

@property (nonatomic) id representedObject;


- (void)drawInContext:(CGContextRef)ctx offset:(CGPoint)offset scale:(CGFloat)scale;
- (void)updateBounds;

@end
