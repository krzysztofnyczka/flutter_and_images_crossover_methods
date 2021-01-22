#import "OpencvBindingPlugin.h"
#if __has_include(<opencv_binding/opencv_binding-Swift.h>)
#import <opencv_binding/opencv_binding-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "opencv_binding-Swift.h"
#endif

@implementation OpencvBindingPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOpencvBindingPlugin registerWithRegistrar:registrar];
}
@end
