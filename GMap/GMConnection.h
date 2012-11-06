#import <Foundation/Foundation.h>
#import <curl/curl.h>

@interface GMConnection : NSObject

@property (nonatomic) CURL *CURLHandle;

@end
