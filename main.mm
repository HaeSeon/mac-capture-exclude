#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ImageIO/ImageIO.h>
#include <iostream>
#include <vector>

void listWindowsAndCapture() {
    // 1. 현재 열린 창 목록 출력
    std::cout << "Listing all open windows..." << std::endl;

    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);
    CGWindowID stepHowWindowID = 0;

    for (NSDictionary* window in (__bridge NSArray*)windowList) {
        NSNumber* windowID = window[(__bridge id)kCGWindowNumber];
        NSString* ownerName = window[(__bridge id)kCGWindowOwnerName];
        NSString* windowTitle = window[(__bridge id)kCGWindowName];
        
        std::cout << "Window ID: " << windowID.intValue
                  << ", Owner: " << ownerName.UTF8String
                  << ", Title: " << (windowTitle ? windowTitle.UTF8String : "No Title")
                  << std::endl;

        // StepHow 앱의 창 ID 저장
        if ([ownerName isEqualToString:@"StepHow"]) {
            stepHowWindowID = windowID.intValue;
        }
    }

    CFRelease(windowList);

    // 2. StepHow 앱의 창을 제외하고 전체 화면 캡처
    std::cout << "\nCapturing the screen excluding StepHow window (ID: " << stepHowWindowID << ")..." << std::endl;

    // 전체 화면 캡처에서 StepHow 창 제외
    CGImageRef image = CGWindowListCreateImage(
        CGRectInfinite,                    // 전체 화면 영역
        kCGWindowListOptionOnScreenBelowWindow,  // 특정 창 아래의 모든 창 캡처
        stepHowWindowID,                   // 제외할 StepHow 창 ID
        kCGWindowImageDefault              // 기본 이미지 옵션
    );

    if (image) {
        // 이미지 저장 경로 설정
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"Desktop/screenshot.png"];
        CFURLRef url = (__bridge CFURLRef)[NSURL fileURLWithPath:path];

        // ImageIO를 사용해 이미지 저장
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
        CGImageDestinationAddImage(destination, image, NULL);
        CGImageDestinationFinalize(destination);

        CFRelease(destination);
        CFRelease(image);

        std::cout << "Screenshot saved to ~/Desktop/screenshot.png" << std::endl;
    } else {
        std::cout << "Failed to capture the screen." << std::endl;
    }
}

int main() {
    @autoreleasepool {
        listWindowsAndCapture();
    }
    return 0;
}