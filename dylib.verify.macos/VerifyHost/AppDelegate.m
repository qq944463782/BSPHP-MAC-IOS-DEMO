#import "AppDelegate.h"
#import <dlfcn.h>

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    (void)notification;
    NSString *exeDir = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    NSString *dylibPath = [exeDir stringByAppendingPathComponent:@"verify.macos.dylib"];

    void *handle = dlopen(dylibPath.fileSystemRepresentation, RTLD_NOW);
    if (!handle) {
        const char *err = dlerror();
        NSString *detail = err ? [NSString stringWithUTF8String:err] : @"(无 dlerror)";
        NSLog(@"[VerifyHost] dlopen 失败: %@ — %@", dylibPath, detail);
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"VerifyHost：未加载 verify.macos.dylib";
        alert.informativeText = [NSString stringWithFormat:@"路径：%@\n\n%@\n\n请先编译 verify.macos 目标，并确认 Copy Files 已把 dylib 放进本 App 的 MacOS 目录。", dylibPath, detail];
        [alert addButtonWithTitle:@"好"];
        [alert runModal];
        return;
    }

    NSLog(@"[VerifyHost] 已 dlopen %@（constructor 将拉起验证弹窗）", dylibPath);
}

@end
