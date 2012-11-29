#import "GMMarker.h"

@implementation GMMarker

- (instancetype) copyWithZone: (NSZone*) zone
{
	GMMarker* another = [super copyWithZone: zone];

	another.centerCoordinate = self.centerCoordinate;
	another.image = self.image;

	return another;
}

@end
