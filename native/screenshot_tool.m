#import <Foundation/Foundation.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if (argc < 2) {
            NSLog(@"Usage: %s <output_path.png>", argv[0]);
            return 1;
        }

        NSString *outputPath = [NSString stringWithUTF8String:argv[1]];

        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:@"/usr/sbin/screencapture"];
        [task setArguments:@[@"-x", outputPath]];

        [task launch];
        [task waitUntilExit];

        int status = [task terminationStatus];
        if (status == 0) {
            NSLog(@"Screenshot saved to %@", outputPath);
        } else {
            NSLog(@"Failed to capture screenshot, exit code %d", status);
        }

        return status;
    }
}
