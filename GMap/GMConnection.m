#import "GMConnection.h"

@implementation GMConnection

- (id)init
{
    if (!(self = super.init))
        return nil;

    self.CURLHandle = curl_easy_init();

    if (!self.CURLHandle)
        return nil;

    return self;
}

- (void)dealloc
{
    curl_easy_cleanup(self.CURLHandle);
}

@end
