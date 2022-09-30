#import "CloudproofPlugin.h"
#if __has_include(<cloudproof/cloudproof-Swift.h>)
#import <cloudproof/cloudproof-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "cloudproof-Swift.h"
#endif

@implementation CloudproofPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftCloudproofPlugin registerWithRegistrar:registrar];
}
@end
