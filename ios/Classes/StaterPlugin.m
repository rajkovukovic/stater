#import "StaterPlugin.h"
#if __has_include(<stater/stater-Swift.h>)
#import <stater/stater-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "stater-Swift.h"
#endif

@implementation StaterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftStaterPlugin registerWithRegistrar:registrar];
}
@end
