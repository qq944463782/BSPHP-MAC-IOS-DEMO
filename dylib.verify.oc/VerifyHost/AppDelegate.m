#import "AppDelegate.h"
#import <dlfcn.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    (void)application;
    (void)launchOptions;

    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    UIViewController *root = [[UIViewController alloc] init];
    root.view.backgroundColor = [UIColor systemBackgroundColor];
    self.window.rootViewController = root;
    [self.window makeKeyAndVisible];

    NSString *exeDir = [[[NSBundle mainBundle] executablePath] stringByDeletingLastPathComponent];
    NSString *dylibPath = [exeDir stringByAppendingPathComponent:@"verify.dylib"];

    void *handle = dlopen(dylibPath.fileSystemRepresentation, RTLD_NOW);
    if (!handle) {
        const char *err = dlerror();
        NSString *detail = err ? [NSString stringWithUTF8String:err] : @"(无 dlerror)";
        NSLog(@"[VerifyHost] dlopen 失败: %@ — %@", dylibPath, detail);

        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VerifyHost：未加载 verify.dylib"
                                                                         message:[NSString stringWithFormat:@"路径：%@\n\n%@\n\n请先编译 verify 目标，并确认 Copy Files 已将 dylib 拷入 App 包内（与可执行文件同目录）。", dylibPath, detail]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:nil]];
        [root presentViewController:alert animated:YES completion:nil];
        return YES;
    }

    NSLog(@"[VerifyHost] 已 dlopen %@（constructor 将拉起验证流程）", dylibPath);
    return YES;
}

@end
