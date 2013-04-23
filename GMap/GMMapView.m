#import <QuartzCore/QuartzCore.h>
#import "GMMapView.h"
#import "GMOverlay.h"
#import "GMConnection.h"
#import "GMTile.h"
#import <curl/curl.h>

void *kOverlayObserverContext = (__bridge void *)@"kOverlayObserverContext";

const NSUInteger kMaxDiskCacheFiles = 50000;

const NSString *kCacheArrayKey = @"kCacheArrayKey";
const NSInteger kMaxHTTPConnectionCount = 16;
const NSInteger kNumberOfCachedTilesPerZoomLevel = 200;


@interface GMMapView ()


// ################################################################################
// Drawing properties

@property (nonatomic) NSInteger renderedZoomLevel;
@property (nonatomic) CALayer *tileLayer;
@property (nonatomic) CALayer *overlayLayer;

- (void)updateLayerTransform;
- (void)updateLayerBounds;

- (void)drawTilesInContext:(CGContextRef)ctx;
- (void)drawOverlaysInContext:(CGContextRef)ctx;

// ################################################################################
// Tiles

@property NSMutableDictionary *tileCache;
@property NSOperationQueue *tileLoadQueue;
@property NSMutableArray *tileConnections;
@property NSInteger tileConnectionIndex;


- (NSString *)cachePathForTile:(GMTile *)tile;

- (void)flushDiskCache;

@property NSTimer *flushDiskCacheTimer;
@property NSOperationQueue *diskCacheQueue;

- (void)loadTileFromDiskCache:(GMTile *)tile;
- (void)queueTileDownload:(GMTile *)tile;
- (void)downloadTile:(GMTile *)tile;
- (const CFStringRef)fetchTileImageAtURL:(NSString *)urlString writeInData:(NSMutableData *)data;
- (CGImageRef)newTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completion;

// ################################################################################
// Overlays

@property (nonatomic) NSMutableArray *overlays;
@property (nonatomic) NSMutableArray *visibleOverlays;

- (void)redisplayOverlays;
- (void)updateVisibleOverlays;

@property (nonatomic) GMOverlay* hoveredOverlay;
@property (nonatomic) GMOverlay *clickedOverlay;
@property (nonatomic) BOOL draggingOccured;

@property (nonatomic) NSInteger lastSelectedOverlay;

// ################################################################################
// System

@property (nonatomic) NSInteger clickCount;

@end

@implementation GMMapView

- (id)initWithFrame:(NSRect)frame
{
    if (!(self = [super initWithFrame:frame]))
        return nil;

// ################################################################################
// Tile download

    self.tileLoadQueue = NSOperationQueue.new;
    self.tileLoadQueue.maxConcurrentOperationCount = 16;
    self.tileConnections = NSMutableArray.new;

    for (int i = 0; i < kMaxHTTPConnectionCount; i++)
    {
        GMConnection *con = GMConnection.new;

        if (!con)
        {
            self.tileConnections = nil;
            return nil;
        }

        [self.tileConnections addObject:con];
    }

    self.tileURLFormat = [NSBundle.mainBundle objectForInfoDictionaryKey:@"GMTileURLFormat"];

    if (!self.tileURLFormat)
        self.tileURLFormat = [[NSBundle bundleForClass:GMMapView.class] objectForInfoDictionaryKey:@"GMTileURLFormat"];

// ################################################################################
// Tile disk cache

    {
        NSString *path = nil;
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);

        if (paths.count)
        {
            NSString *bundleName = [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleIdentifier"];
            path = [[paths objectAtIndex:0] stringByAppendingPathComponent:bundleName];
        }

        assert(path);
        path = [path stringByAppendingPathComponent:@"GMapTiles/"];

        if (![NSFileManager.defaultManager fileExistsAtPath:path])
            [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

        self.tileCacheDirectoryPath = path;
    }

    self.tileCache = NSMutableDictionary.new;
    self.diskCacheQueue = NSOperationQueue.new;
    self.flushDiskCacheTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(scheduleDiskCacheFlush) userInfo:nil repeats:YES];

// ################################################################################
// Overlays

    self.overlays = NSMutableArray.new;
	self.lastSelectedOverlay = NSNotFound;

// ################################################################################
// General properties

    self.cacheTilesOnDisk = YES;
    self.panningEnabled = YES;
    self.scrollZoomEnabled = YES;
	self.overlaysClickable = YES;
	self.overlaysSelectable = NO;
	self.overlaysAllowMultipleSelection = YES;

// ################################################################################
// Drawing

    self.layer = CALayer.new;
    self.wantsLayer = YES;

    self.tileLayer = CALayer.new;
    self.tileLayer.delegate = self;
    self.tileLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self.tileLayer];

    self.overlayLayer = CALayer.new;
    self.overlayLayer.delegate = self;
    self.overlayLayer.needsDisplayOnBoundsChange = YES;
    [self.layer addSublayer:self.overlayLayer];

    [self updateLayerBounds];
    [self updateLayerTransform];

	self.clickCount = 0;

    return self;
}

- (void)dealloc
{
    self.layer.delegate = nil;
    self.tileLayer.delegate = nil;
    [self.tileLoadQueue cancelAllOperations];
    [self.diskCacheQueue cancelAllOperations];
    [self.flushDiskCacheTimer invalidate];
    [self flushDiskCache];
}

- (void)viewDidEndLiveResize
{
    [self updateLayerBounds];
    [self updateLayerTransform];
}

- (void)updateLayerBounds
{
    self.tileLayer.bounds = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.overlayLayer.bounds = self.tileLayer.bounds;
}

- (void)updateLayerTransform
{
    CGFloat f = fmod(self.zoomLevel, 1);
    CGFloat scale = pow(2, f);
    CGAffineTransform t = CGAffineTransformIdentity;

    t = CGAffineTransformTranslate(t, self.layer.bounds.size.width / 2.0, self.layer.bounds.size.height / 2.0);
    self.overlayLayer.affineTransform = t;

    t = CGAffineTransformScale(t, scale, scale);
    self.tileLayer.affineTransform = t;
}

// ################################################################################
// Properties

- (void)setFrame:(CGRect)frame
{
    super.frame = frame;

    if (![self inLiveResize])
        [self updateLayerBounds];

    [self updateLayerTransform];
}

- (void)setZoomLevel:(CGFloat)zoomLevel
{
    _zoomLevel = MAX(0, MIN(18, zoomLevel));

    if (self.roundZoomLevel)
        _zoomLevel = round(_zoomLevel);

    NSInteger renderZoomLevel = floor(_zoomLevel);

    if (renderZoomLevel != self.renderedZoomLevel)
    {
        self.renderedZoomLevel = renderZoomLevel;
        [self updateLayerTransform];
        [self.tileLayer setNeedsDisplay];
    }
    else
        [self updateLayerTransform];

    [self.overlayLayer setNeedsDisplay];
}

- (void)setCenterCoordinate:(GMCoordinate)coordinate
{
    [self willChangeValueForKey:@"centerLatitude"];
    [self willChangeValueForKey:@"centerLongitude"];
    _centerCoordinate = coordinate;
    [self didChangeValueForKey:@"centerLongitude"];
    [self didChangeValueForKey:@"centerLatitude"];

    [self willChangeValueForKey:@"centerPoint"];
    _centerPoint = GMCoordinateToMapPoint(self.centerCoordinate);
    [self didChangeValueForKey:@"centerPoint"];

    [self.tileLayer setNeedsDisplay];
    [self.overlayLayer setNeedsDisplay];
}

- (void)setCenterPoint:(GMMapPoint)point
{
    _centerPoint.x = MAX(0, MIN(1.0, point.x));
    _centerPoint.y = MAX(0, MIN(1.0, point.y));

    [self willChangeValueForKey:@"centerCoordinate"];
    [self willChangeValueForKey:@"centerLatitude"];
    [self willChangeValueForKey:@"centerLongitude"];
    _centerCoordinate = GMMapPointToCoordinate(_centerPoint);
    [self didChangeValueForKey:@"centerLongitude"];
    [self didChangeValueForKey:@"centerLatitude"];
    [self didChangeValueForKey:@"centerCoordinate"];

    [self.tileLayer setNeedsDisplay];
    [self.overlayLayer setNeedsDisplay];
}

- (void)setCenterLatitude:(GMFloat)latitude
{
    self.centerCoordinate = GMCoordinateMake(latitude, self.centerCoordinate.longitude);
}

- (void)setCenterLongitude:(GMFloat)longitude
{
    self.centerCoordinate = GMCoordinateMake(self.centerCoordinate.latitude, longitude);
}

- (GMFloat)centerLatitude
{
    return self.centerCoordinate.latitude;
}

- (GMFloat)centerLongitude
{
    return self.centerCoordinate.longitude;
}

- (void) setOverlaysSelectable:(BOOL)selectable
{
	if (_overlaysSelectable == selectable) return;

	_overlaysSelectable = selectable;

	if (!_overlaysSelectable) [self deselectAllOverlays];
}

- (void)zoomToFitMapBounds:(GMMapBounds)bounds
{
    GMMapPoint centerPoint = GMMapBoundsCenterPoint(bounds);

    CGFloat scale = fmin(self.frame.size.width / (bounds.bottomRight.x - bounds.topLeft.x),
                         self.frame.size.height / (bounds.bottomRight.y - bounds.topLeft.y));

    CGFloat zoomLevel = log2(scale / kTileSize);

    self.centerPoint = centerPoint;
    self.zoomLevel = zoomLevel;
}

// ################################################################################
// Drawing

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    if (layer == self.tileLayer)
        [self drawTilesInContext:ctx];
    else if (layer == self.overlayLayer)
    {
        [self updateVisibleOverlays];
        [self drawOverlaysInContext:ctx];
    }
}

- (void)drawTilesInContext:(CGContextRef)ctx
{
    CGRect rect = CGContextGetClipBoundingBox(ctx);

    GMMapPoint center = self.centerPoint;

    CGSize size = self.tileLayer.bounds.size;
    NSInteger level = floor(self.zoomLevel);
    NSInteger n = 1 << level;

    CGFloat worldSize = kTileSize * n;

    CGPoint centerPoint = CGPointMake(center.x * n, center.y * n);

    CGPoint worldOffset = CGPointMake(centerPoint.x * kTileSize,
                                      worldSize - centerPoint.y * kTileSize);

    NSInteger centralTileX = floor(center.x * n);
    NSInteger centralTileY = floor(center.y * n);

    CGPoint centralTilePoint = CGPointMake((CGFloat)centralTileX * kTileSize,
                                           worldSize - (CGFloat)centralTileY * kTileSize - kTileSize);

    CGPoint centralTileOrigin = CGPointMake(size.width / 2 + centralTilePoint.x - worldOffset.x,
                                            size.height / 2 + centralTilePoint.y - worldOffset.y);


    NSInteger offsetX = -ceil((size.width / 2.0) / kTileSize);
    NSInteger offsetY = -ceil((size.height / 2.0) / kTileSize);

    NSInteger maxOffsetX = -offsetX;
    NSInteger maxOffsetY = -offsetY;

	CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

    CGContextSetFillColorWithColor(ctx, NSColor.windowBackgroundColor.CGColor);

    CGContextFillRect(ctx, rect);

    void (^drawTile)(NSInteger offsetX, NSInteger offsetY) = ^(NSInteger offsetX, NSInteger offsetY) {

        NSInteger tileX = centralTileX + offsetX;
        NSInteger tileY = centralTileY + offsetY;

        if (tileX < 0 || tileY < 0 || tileX >= n || tileY >= n)
            return;

        CGRect tileRect;
        tileRect.size = CGSizeMake (kTileSize, kTileSize);
        tileRect.origin = CGPointMake (floor (centralTileOrigin.x + offsetX * kTileSize),
                                       floor (centralTileOrigin.y - offsetY * kTileSize));

        if (!CGRectIntersectsRect (rect, tileRect))
            return;

        CGImageRef image;

        void (^redraw)(void) = ^{
            [self.tileLayer setNeedsDisplayInRect:tileRect];
        };

        if ((image = [self newTileImageForX:tileX y:tileY zoomLevel:level completion:redraw]))
        {
            CGContextDrawImage (ctx, tileRect, image);
            CGImageRelease (image);
        }
    };

    for (; offsetY <= maxOffsetY; offsetY++)
    {
        offsetX = -maxOffsetX;

        for (; offsetX <= maxOffsetX; offsetX++)
        {
            drawTile (offsetX, offsetY);
        }
    }
}

- (void)drawOverlaysInContext:(CGContextRef)ctx
{
    if (!self.visibleOverlays.count)
        return;

    GMMapPoint center = self.centerPoint;
    CGFloat scale = pow(2, self.zoomLevel) * kTileSize;

    CGSize size = self.tileLayer.bounds.size;

    CGPoint worldOffset = CGPointMake(center.x * scale - size.width / 2.0,
                                      center.y * scale - size.height / 2.0);

    for (GMOverlay *overlay in self.visibleOverlays)
        [overlay drawInContext:ctx offset:worldOffset scale:scale];
}

// ################################################################################
// Events

- (void)mouseDown:(NSEvent *)evt
{
    CGPoint location = [self convertPoint:evt.locationInWindow fromView:nil];

    GMMapPoint clickedPoint = [self convertViewLocationToMapPoint:location];

    self.clickedOverlay = nil;
    self.draggingOccured = NO;

    if (self.overlaysClickable || self.overlaysDraggable)
    {
        for (GMOverlay *overlay in self.visibleOverlays.reverseObjectEnumerator)
        {
            if (GMMapBoundsContainsMapPoint(overlay.mapBounds, clickedPoint))
            {
                self.clickedOverlay = overlay;
                break;
            }
        }
	}

	if (self.overlaysSelectable && (self.clickedOverlay != nil) && (evt.clickCount == 1))
	{
		NSUInteger index = [self.overlays indexOfObject: self.clickedOverlay];
		BOOL selected = self.clickedOverlay.selected;
		BOOL extends = (NSEvent.modifierFlags & NSShiftKeyMask) || (NSEvent.modifierFlags & NSCommandKeyMask);
		if (!selected)
		{
			[self selectOverlayIndexes:[[NSIndexSet alloc] initWithIndex: index] byExtendingSelection:extends];
		}
		else
		{
			if (extends) [self deselectOverlayAtIndex:index];
		}
	}
}

- (void)mouseUp:(NSEvent *)evt
{
    CGPoint location = [self convertPoint:evt.locationInWindow fromView:nil];

    GMMapPoint clickedPoint = [self convertViewLocationToMapPoint:location];

    if (self.clickedOverlay && self.overlaysClickable && !self.draggingOccured
        && [self.delegate respondsToSelector:@selector(mapView:overlayClicked:locationInView:)]
        && GMMapBoundsContainsMapPoint(self.clickedOverlay.mapBounds, clickedPoint))
        [self.delegate mapView:self overlayClicked:self.clickedOverlay locationInView:location];

	if (self.draggingOccured && self.overlaysDraggable && (self.clickedOverlay != nil) && [self.delegate respondsToSelector:@selector(mapView:didDragOverlay:toMapPoint:)])
		[self.delegate mapView:self didDragOverlay:self.clickedOverlay toMapPoint:self.clickedOverlay.mapPoint];

    self.clickedOverlay = nil;

    if (!self.draggingOccured
        && [self.delegate respondsToSelector:@selector(mapView:clickedAtPoint:locationInView:)])
        [self.delegate mapView:self clickedAtPoint:clickedPoint locationInView:location];

	// simple / double / multi click detection

	self.clickCount = evt.clickCount;

	switch ( self.clickCount )
	{
		case 1:
		{
			[self simpleClickImmediate:evt];
			[self performSelector:@selector(handleSimpleClickDelayed:) withObject:evt afterDelay:NSEvent.doubleClickInterval];
			break;
		}
		case 2:
		{
			[self doubleClick:evt];
			break;
		}
	}
}

- (void)simpleClickImmediate:(NSEvent*)evt
{
}

-(void)handleSimpleClickDelayed:(NSEvent*)evt
{
	if ( self.clickCount == 1 ) [self simpleClickDelayed:evt];
	else self.clickCount = 0;
}

-(void)simpleClickDelayed:(NSEvent*)evt
{
    CGPoint location = [self convertPoint:evt.locationInWindow fromView:nil];

    GMMapPoint clickedPoint = [self convertViewLocationToMapPoint:location];

    if (!self.draggingOccured && [self.delegate respondsToSelector:@selector(mapView:simpleClickedAtPoint:locationInView:)])
		[self.delegate mapView:self simpleClickedAtPoint:clickedPoint locationInView:location];
}

-(void)doubleClick:(NSEvent*)evt
{
    CGPoint location = [self convertPoint:evt.locationInWindow fromView:nil];

    GMMapPoint clickedPoint = [self convertViewLocationToMapPoint:location];

    if (!self.draggingOccured && [self.delegate respondsToSelector:@selector(mapView:doubleClickedAtPoint:locationInView:)])
		[self.delegate mapView:self doubleClickedAtPoint:clickedPoint locationInView:location];
}

- (void)mouseMoved:(NSEvent *)evt
{
    CGPoint location = [self convertPoint:evt.locationInWindow fromView:nil];

    GMMapPoint hoveredPoint = [self convertViewLocationToMapPoint:location];

	GMOverlay* previouslyHoveredOverlay = self.hoveredOverlay;

	self.hoveredOverlay = nil;

	for (GMOverlay *overlay in self.visibleOverlays.reverseObjectEnumerator)
	{
		if (GMMapBoundsContainsMapPoint(overlay.mapBounds, hoveredPoint))
		{
			self.hoveredOverlay = overlay;
			break;
        }
	}

	if ( (previouslyHoveredOverlay != nil) && (self.hoveredOverlay != previouslyHoveredOverlay) &&
		[self.delegate respondsToSelector:@selector(mapView:overlayExited:locationInView:)])
	{
		[self.delegate mapView:self overlayExited:previouslyHoveredOverlay locationInView:location];
	}

	if ( (previouslyHoveredOverlay == nil) && (self.hoveredOverlay != nil) &&
		[self.delegate respondsToSelector:@selector(mapView:overlayEntered:locationInView:)])
	{
		[self.delegate mapView:self overlayEntered:self.hoveredOverlay locationInView:location];
	}

	if ((self.hoveredOverlay != nil) && !self.draggingOccured &&
		[self.delegate respondsToSelector:@selector(mapView:overlayHovered:locationInView:)] &&
		GMMapBoundsContainsMapPoint(self.hoveredOverlay.mapBounds, hoveredPoint))
	{
		[self.delegate mapView:self overlayHovered:self.hoveredOverlay locationInView:location];
	}
}

- (void)mouseDragged:(NSEvent *)evt
{
    self.draggingOccured = YES;

    if (!self.panningEnabled && !self.overlaysDraggable)
        return;

    CGFloat scale = pow(2, self.zoomLevel);
    CGPoint offset = CGPointMake(evt.deltaX / scale / kTileSize, evt.deltaY / scale / kTileSize);

    if (self.overlaysDraggable && self.clickedOverlay)
    {
        if ([self.delegate respondsToSelector:@selector(mapView:shouldDragOverlay:)]
            && ![self.delegate mapView:self shouldDragOverlay:self.clickedOverlay])
            return;

        GMMapPoint newPoint = GMMapPointMake(self.clickedOverlay.mapPoint.x + offset.x, self.clickedOverlay.mapPoint.y + offset.y);

        if ([self.delegate respondsToSelector:@selector(mapView:willDragOverlay:toMapPoint:)])
            newPoint = [self.delegate mapView:self willDragOverlay:self.clickedOverlay toMapPoint:newPoint];

        self.clickedOverlay.mapPoint = newPoint;
        [self.overlayLayer setNeedsDisplay];
    }
    else if (self.panningEnabled)
    {
        GMMapPoint newPoint = GMMapPointMake(self.centerPoint.x - offset.x, self.centerPoint.y - offset.y);

        if ([self.delegate respondsToSelector:@selector(mapView:willPanCenterToMapPoint:)])
            newPoint = [self.delegate mapView:self willPanCenterToMapPoint:newPoint];

        self.centerPoint = newPoint;
    }
}

- (void)scrollWheel:(NSEvent *)evt
{
    if (!self.scrollZoomEnabled)
        return;

    CGFloat zoomDelta = evt.scrollingDeltaY / 10.0;

    if (self.roundZoomLevel)
        zoomDelta = zoomDelta > 0 ? ceil(zoomDelta) : floor(zoomDelta);

    CGFloat scale = pow(2, zoomDelta);

    CGPoint relativeCenter = [self convertPoint:evt.locationInWindow fromView:nil];

    relativeCenter.x -= self.frame.size.width / 2.0;
    relativeCenter.y -= self.frame.size.height / 2.0;

    CGPoint offset = CGPointMake(relativeCenter.x * scale - relativeCenter.x,
                                 relativeCenter.y * scale - relativeCenter.y );

    CGFloat previousZoomLevel = self.zoomLevel;
    CGFloat newZoomLevel = self.zoomLevel + zoomDelta;

    if ([self.delegate respondsToSelector:@selector(mapView:willScrollZoomToLevel:)])
        newZoomLevel = [self.delegate mapView:self willScrollZoomToLevel:newZoomLevel];

    self.zoomLevel = newZoomLevel;

    if (previousZoomLevel == self.zoomLevel)
        return;

    scale = pow(2, self.zoomLevel);

    offset.x = offset.x / scale / kTileSize;
    offset.y = offset.y / scale / kTileSize;

    self.centerPoint = GMMapPointMake(self.centerPoint.x + offset.x, self.centerPoint.y - offset.y);
}

// ################################################################################
// Utilities

- (GMMapPoint)convertViewLocationToMapPoint:(CGPoint)locationInView;
{
    locationInView.x -= self.frame.size.width / 2.0;
    locationInView.y -= self.frame.size.height / 2.0;

    CGFloat scale = pow(2, self.zoomLevel);
    return GMMapPointMake(self.centerPoint.x + locationInView.x / scale / kTileSize,
                          self.centerPoint.y - locationInView.y / scale / kTileSize);
}

- (CGPoint)convertMapPointToViewLocation:(GMMapPoint)mapPoint
{
    CGPoint location;

    CGFloat scale = pow(2, self.zoomLevel);

    location.x = scale * kTileSize * (mapPoint.x - self.centerPoint.x);
    location.y = -scale * kTileSize * (mapPoint.y - self.centerPoint.y);

    location.x += self.frame.size.width / 2.0;
    location.y += self.frame.size.height / 2.0;

    return location;
}


// ################################################################################
// Tiles

- (CGImageRef)newTileImageForX:(NSInteger)x y:(NSInteger)y zoomLevel:(NSInteger)zoomLevel completion:(void (^)(void))completion
{
    NSString *tileKey = [GMTile tileKeyForX:x y:y zoomLevel:zoomLevel];

    NSMutableDictionary *cacheDictionary = [self.tileCache objectForKey:[NSNumber numberWithInteger:zoomLevel]];
    NSMutableArray *cacheArray;

    if (!cacheDictionary)
    {
        cacheDictionary = NSMutableDictionary.new;
        [self.tileCache setObject:cacheDictionary forKey:[NSNumber numberWithInteger:zoomLevel]];
        cacheArray = NSMutableArray.new;
        [cacheDictionary setObject:cacheArray forKey:kCacheArrayKey];
    }
    else
        cacheArray = [cacheDictionary objectForKey:kCacheArrayKey];

    GMTile *tile;

    tile = [cacheDictionary objectForKey:tileKey];

    if (!tile)
    {
        tile = [GMTile.alloc initWithX:x y:y zoomLevel:zoomLevel];
        [self loadTileFromDiskCache:tile];
        [cacheDictionary setObject:tile forKey:tileKey];
    }

    if (tile.zoomLevel > 4)
    {
        [cacheArray removeObject:tile];
        [cacheArray insertObject:tile atIndex:0];
    }

    if (cacheArray.count > kNumberOfCachedTilesPerZoomLevel)
    {
        GMTile *tileToFlush = cacheArray.lastObject;
        [cacheArray removeLastObject];
        [cacheDictionary removeObjectForKey:tileToFlush.key];
    }

    CGImageRef image;

    if (!tile.loaded)
    {
        tile.completion = completion;

        if (!tile.image)
        {
            CGFloat factor = 1;

            for (NSInteger parentZoomLevel = zoomLevel - 1; parentZoomLevel >= 0; parentZoomLevel--)
            {
                factor *= 2;

                NSInteger parentX = floor((CGFloat)x / factor);
                NSInteger parentY = floor((CGFloat)y / factor);
                NSString *parentTileKey = [GMTile tileKeyForX:parentX y:parentY zoomLevel:parentZoomLevel];

                GMTile *parentTile = [[self.tileCache objectForKey:[NSNumber numberWithInteger:parentZoomLevel]] objectForKey:parentTileKey];

                if (parentTile.loaded)
                {
                    CGRect rect;

                    rect.origin = CGPointMake(fmod((CGFloat)x / factor, 1.0) * kTileSize, fmod((CGFloat)y / factor, 1.0) * kTileSize);
                    rect.size = CGSizeMake(kTileSize / factor, kTileSize / factor);

                    CGImageRef parentImage = CGImageCreateWithImageInRect(parentTile.image, rect);
                    tile.image = parentImage;
                    CGImageRelease(parentImage);
                    break;
                }
            }
        }

        if (!tile.loading)
        {
            tile.loading = YES;

            [self.tileLoadQueue addOperationWithBlock:^{
                 [self queueTileDownload:tile];
             }];
        }
    }

    image = CGImageRetain(tile.image);

    return image;
}

- (NSString *)cachePathForTile:(GMTile *)tile
{
    return [self.tileCacheDirectoryPath stringByAppendingPathComponent:(NSString *)tile.key];
}

- (void)loadTileFromDiskCache:(GMTile *)tile
{
    NSString *path = [self cachePathForTile:tile];

    if (!self.cacheTilesOnDisk || ![NSFileManager.defaultManager fileExistsAtPath:path])
        return;

    NSURL *fileURL = [NSURL fileURLWithPath:path];

    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)fileURL, NULL);

	CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    tile.image = image;

	CGImageRelease(image);
    CFRelease(source);

    tile.loaded = YES;
}

- (void)queueTileDownload:(GMTile *)tile
{
    if (tile.zoomLevel != self.renderedZoomLevel)
    {
        tile.loading = NO;
        return;
    }

    [self.tileLoadQueue addOperationWithBlock:^{
         @autoreleasepool {
             [self downloadTile:tile];
         }
     }];
}


static size_t writeData(void *ptr, size_t size, size_t nmemb, void *userdata)
{
    size_t len = size * nmemb;
    NSMutableData *data = (__bridge NSMutableData *)userdata;

    [data appendBytes:ptr length:len];

    return len;
}

- (const CFStringRef)fetchTileImageAtURL:(NSString *)urlString writeInData:(NSMutableData *)data
{
    CFStringRef type = NULL;

    GMConnection *con;

    @synchronized(self.tileConnections)
    {
        self.tileConnectionIndex = (self.tileConnectionIndex + 1) % self.tileConnections.count;
        con = self.tileConnections[self.tileConnectionIndex];
    }

    @synchronized(con)
    {
        CURL *handle = con.CURLHandle;

        curl_easy_setopt(handle, CURLOPT_URL, [urlString cStringUsingEncoding:NSUTF8StringEncoding]);
        curl_easy_setopt(handle, CURLOPT_WRITEDATA, data);
        curl_easy_setopt(handle, CURLOPT_WRITEFUNCTION, writeData);
        curl_easy_setopt(handle, CURLOPT_TIMEOUT, 5);

        if (!curl_easy_perform(handle))
        {
            char *contentType;
            curl_easy_getinfo(handle, CURLINFO_CONTENT_TYPE, &contentType);

            if (contentType)
            {
                CFStringRef MIMEType = CFStringCreateWithCStringNoCopy(NULL, contentType, kCFStringEncodingUTF8, kCFAllocatorNull);
                CFStringRef UTType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, MIMEType, kUTTypeImage);

                if (UTType && UTTypeEqual(UTType, kUTTypeJPEG))
                    type = kUTTypeJPEG;
                else if (UTType && UTTypeEqual(UTType, kUTTypePNG))
                    type = kUTTypePNG;

                if (UTType != NULL) CFRelease(UTType);
                CFRelease(MIMEType);
            }
        }
    }

    return type;
}


- (void)downloadTile:(GMTile *)tile
{
    CGImageRef image = NULL;

    if (tile.zoomLevel != self.renderedZoomLevel)
    {
        tile.loading = NO;
        return;
    }

    NSString *path = [self cachePathForTile:tile];
    NSString *url = [NSString stringWithFormat:self.tileURLFormat, (long)tile.zoomLevel, (long)tile.x, (long)tile.y];

    NSMutableData *data = NSMutableData.new;
    const CFStringRef imageType = [self fetchTileImageAtURL:url writeInData:data];

    if (imageType && data.length)
    {
        CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);

        if (provider)
        {
            if (imageType == kUTTypePNG)
                image = CGImageCreateWithPNGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);
            else
                image = CGImageCreateWithJPEGDataProvider(provider, NULL, NO, kCGRenderingIntentDefault);

            CFRelease(provider);
        }

        if (image && self.cacheTilesOnDisk)
            [data writeToFile:path atomically:YES];
    }

    [NSOperationQueue.mainQueue addOperationWithBlock:^{
         tile.image = image;
         CGImageRelease (image);
         tile.loaded = image != NULL;
         tile.loading = NO;

         if (image)
             tile.completion ();
     }];
}

- (void)scheduleDiskCacheFlush
{
    if (!self.cacheTilesOnDisk)
        return;

    [self.diskCacheQueue addOperationWithBlock:^{
        [self flushDiskCache];
    }];
}

- (void)flushDiskCache
{
    NSString *dirPath = self.tileCacheDirectoryPath;
    NSArray *tilePaths = [NSFileManager.defaultManager contentsOfDirectoryAtPath:dirPath error:nil];

    if (tilePaths.count < kMaxDiskCacheFiles)
        return;

    NSMutableArray *files = NSMutableArray.new;

    for (NSString *tilePath in tilePaths)
    {
        NSString *absolutePath = [dirPath stringByAppendingPathComponent:tilePath];
        NSDictionary *attrs = [NSFileManager.defaultManager attributesOfItemAtPath:absolutePath error:nil];

        NSMutableDictionary *file = NSMutableDictionary.new;
        file[@"date"] = attrs[NSFileCreationDate];
        file[@"absolutePath"] = absolutePath;

        file[@"zoomLevel"] = [tilePath componentsSeparatedByString:@"-"][0];

        [files addObject:file];
    }

    [files sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]]];


    [files enumerateObjectsUsingBlock:^(NSMutableDictionary *file, NSUInteger idx, BOOL *stop) {
        NSUInteger zoomLevel = [file[@"zoomLevel"] integerValue];
        NSUInteger keepScore = idx;
        keepScore += (18 - zoomLevel) * 100;

        file[@"keepScore"] = [NSNumber numberWithUnsignedInteger:keepScore];
    }];

    [files sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"keepScore" ascending:YES]]];

    [files removeObjectsInRange:NSMakeRange(files.count - kMaxDiskCacheFiles - 1, kMaxDiskCacheFiles)];

    for (NSDictionary *file in files)
        [NSFileManager.defaultManager removeItemAtPath:file[@"absolutePath"] error:nil];

}

// ################################################################################
// Overlays

- (void)addedOverlay:(GMOverlay *)overlay
{
    [overlay addObserver:self forKeyPath:@"version" options:0 context:kOverlayObserverContext];
    [self redisplayOverlays];
}

- (void)removedOverlay:(GMOverlay *)overlay
{
    [overlay removeObserver:self forKeyPath:@"version" context:kOverlayObserverContext];
    [self redisplayOverlays];
}

- (void)addOverlay:(GMOverlay *)overlay
{
    [(NSMutableArray *) _overlays addObject:overlay];
    [self addedOverlay:overlay];
}

- (void)addOverlays:(NSArray *)overlays
{
    [(NSMutableArray *) _overlays addObjectsFromArray:overlays];

    for (GMOverlay *overlay in overlays)
        [self addedOverlay:overlay];
}

- (void)removeOverlay:(GMOverlay *)overlay
{
    [(NSMutableArray *) _overlays removeObject:overlay];
    [self removedOverlay:overlay];
}

- (void)removeOverlays:(NSArray *)overlays
{
    [(NSMutableArray *) _overlays removeObjectsInArray:overlays];

    for (GMOverlay *overlay in overlays)
        [self removedOverlay:overlay];
}

- (void)removeAllOverlays
{
	for (GMOverlay* overlay in [_overlays copy])
		[self removeOverlay:overlay];
}

- (void)exchangeOverlayAtIndex:(NSUInteger)index1 withOverlayAtIndex:(NSUInteger)index2
{
    [(NSMutableArray *) _overlays exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    [self redisplayOverlays];
}

- (void)insertOverlay:(GMOverlay *)overlay aboveOverlay:(GMOverlay *)sibling
{
    NSUInteger idx = [_overlays indexOfObject:sibling];

    [(NSMutableArray *) _overlays insertObject:overlay atIndex:idx];
    [self addedOverlay:overlay];
}

- (void)insertOverlay:(GMOverlay *)overlay belowOverlay:(GMOverlay *)sibling
{
    NSUInteger idx = [_overlays indexOfObject:sibling] + 1;

    [(NSMutableArray *) _overlays insertObject:overlay atIndex:idx];
    [self addedOverlay:overlay];
}

- (void)insertOverlay:(GMOverlay *)overlay atIndex:(NSUInteger)index
{
    index = MIN(index, _overlays.count);
    [(NSMutableArray *) _overlays insertObject:overlay atIndex:index];
    [self addedOverlay:overlay];
}

- (NSIndexSet*)selectedOverlayIndexes
{
	NSMutableIndexSet* indexes = [NSMutableIndexSet new];

	for (NSUInteger index = 0; index < self.overlays.count; index += 1)
	{
		GMOverlay* overlay = self.overlays[index];
		if ( overlay.selected ) [indexes addIndex: index];
	}

	return [indexes copy];
}

- (NSArray*)selectedOverlays
{
	return [self.overlays objectsAtIndexes: [self selectedOverlayIndexes]];
}

- (void)selectOverlayIndexes:(NSIndexSet*)indexes byExtendingSelection:(BOOL)extend
{
	if (!extend)
	{
		for (GMOverlay* overlay in self.overlays) overlay.selected = NO;

		self.lastSelectedOverlay = NSNotFound;
	}

	if (!self.overlaysSelectable) return;

	if ( self.overlaysAllowMultipleSelection )
	{
		[indexes enumerateIndexesUsingBlock: ^(NSUInteger index, BOOL* stop)
		{
			if ( index >= self.overlays.count ) return;

			GMOverlay* overlay = self.overlays[index];
			overlay.selected = YES;

			self.lastSelectedOverlay = index;
		}];
	}
	else
	{
		if (extend)
		{
			for (GMOverlay* overlay in self.overlays) overlay.selected = NO;
		}

		NSUInteger index = indexes.firstIndex;

		GMOverlay* overlay = self.overlays[index];
		overlay.selected = YES;

		self.lastSelectedOverlay = index;
	}

	[self redisplayOverlays];

	if ([self.delegate respondsToSelector:@selector(mapView:overlaySelectionDidChange:)])
	{
		[self.delegate mapView: self overlaySelectionDidChange: self.selectedOverlayIndexes];
	}
}

- (void)deselectOverlayAtIndex:(NSUInteger)index
{
	if ( index >= self.overlays.count ) return;

	GMOverlay* overlay = self.overlays[index];
	overlay.selected = NO;

	if ( self.lastSelectedOverlay == index ) self.lastSelectedOverlay = NSNotFound;

	[self redisplayOverlays];
}

- (void)deselectAllOverlays
{
	for (GMOverlay* overlay in self.overlays) overlay.selected = NO;

	self.lastSelectedOverlay = NSNotFound;

	[self redisplayOverlays];

	if ([self.delegate respondsToSelector:@selector(mapView:overlaySelectionDidChange:)])
	{
		[self.delegate mapView: self overlaySelectionDidChange: self.selectedOverlayIndexes];
	}
}

- (void)zoomToFitOverlays:(NSArray*)overlays round:(BOOL)round
{
	if (overlays.count == 0) return;
	if (![overlays[0] isKindOfClass: GMOverlay.class]) return;

	GMMapBounds bounds = ((GMOverlay*)overlays[0]).mapBounds;

	for ( GMOverlay* overlay in overlays )
	{
		bounds = GMMapBoundsAddMapBounds(bounds, overlay.mapBounds);
	}

	GMMapPoint desiredCenter = GMMapBoundsCenterPoint(bounds);

	if ([self.delegate respondsToSelector:@selector(mapView:willPanCenterToMapPoint:)])
	{
		desiredCenter = [self.delegate mapView:self willPanCenterToMapPoint:desiredCenter];
	}

	self.centerPoint = GMMapBoundsCenterPoint(bounds);
	
    //CGFloat scale = exp2(self.zoomLevel) * kTileSize;
	CGFloat desiredScale = self.frame.size.width / (bounds.bottomRight.x - bounds.topLeft.x);
	desiredScale = fmin( desiredScale, self.frame.size.height / (bounds.bottomRight.y - bounds.topLeft.y));

	CGFloat desiredZoom = log2(desiredScale / kTileSize);
	if ( round ) desiredZoom = floor( desiredZoom );

    if ([self.delegate respondsToSelector:@selector(mapView:willScrollZoomToLevel:)])
	{
		desiredZoom = [self.delegate mapView:self willScrollZoomToLevel:desiredZoom];
	}

	self.zoomLevel = desiredZoom;
}

- (void)zoomToFitOverlays:(NSArray*)overlays
{
    if (!overlays.count)
        return;

    GMMapBounds bounds;
    BOOL boundsSet = NO;

    for (GMOverlay *overlay in overlays)
    {
        if (GMMapBoundsArea(overlay.mapBounds) == 0)
            continue;

        if (!boundsSet)
        {
            bounds = overlay.mapBounds;
            boundsSet = YES;
        }
        else
            bounds = GMMapBoundsAddMapBounds(bounds, overlay.mapBounds);
    }

    if (boundsSet)
        [self zoomToFitMapBounds:bounds];
}

- (void)redisplayOverlays
{
    [self.overlayLayer setNeedsDisplay];
}

- (void)updateVisibleOverlays
{
    if (!self.overlays.count)
    {
        self.visibleOverlays = nil;
        return;
    }

    GMMapPoint topLeft = [self convertViewLocationToMapPoint:CGPointMake(0, self.overlayLayer.bounds.size.height)];
    GMMapPoint bottomRight = [self convertViewLocationToMapPoint:CGPointMake(self.overlayLayer.bounds.size.width, 0)];
    GMMapBounds bounds = GMMapBoundsMakeWithMapPoints(topLeft, bottomRight);


    CGFloat scale = pow(2, self.zoomLevel) * kTileSize;
    CGFloat minSize = 10.0 / scale;

    self.visibleOverlays = NSMutableArray.new;

    for (GMOverlay *overlay in self.overlays)
    {
        if (((overlay.visibility == GMOverlayAlwaysVisible) || ((overlay.visibility == GMOverlayVisible) && GMMapBoundsSemiPerimeter(overlay.mapBounds) > minSize)) &&
            GMMapBoundsInterectsMapBounds(overlay.mapBounds, bounds))
            [self.visibleOverlays addObject:overlay];
    }
}

// ################################################################################
// Key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == kOverlayObserverContext)
        [self redisplayOverlays];
}


@end
