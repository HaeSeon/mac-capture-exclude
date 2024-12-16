#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ImageIO/ImageIO.h>
#include <iostream>

void listWindowsAndCapture(CGWindowID excludedWindowID) {
    // 1. 현재 열린 창 목록 출력
    std::cout << "Listing all open windows..." << std::endl;

    CFArrayRef windowList = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly, kCGNullWindowID);

    for (NSDictionary* window in (__bridge NSArray*)windowList) {
        NSNumber* windowID = window[(__bridge id)kCGWindowNumber];
        NSString* ownerName = window[(__bridge id)kCGWindowOwnerName];
        NSString* windowTitle = window[(__bridge id)kCGWindowName];
        
        std::cout << "Window ID: " << windowID.intValue
                  << ", Owner: " << ownerName.UTF8String
                  << ", Title: " << (windowTitle ? windowTitle.UTF8String : "No Title")
                  << std::endl;
    }

    CFRelease(windowList);

    // 2. 특정 창을 제외하고 전체 화면 캡처
    std::cout << "\nCapturing the screen excluding window ID: " << excludedWindowID << std::endl;

    CGRect screenBounds = CGRectInfinite; // 전체 화면 영역
    CGWindowListOption options = kCGWindowListOptionOnScreenOnly; // 화면에 표시된 창만 캡처

    // CGWindowListCreateImage 호출: 특정 창 제외
    CGImageRef image = CGWindowListCreateImage(
        screenBounds,                // 캡처할 전체 화면 영역
        options,                     // 화면에 표시된 창만 포함
        excludedWindowID,            // 제외할 창의 ID
        kCGWindowImageDefault        // 기본 이미지 옵션
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
        // 현재 열린 창 목록과 캡처 테스트
        // 창 ID 입력 (테스트용, 실제 창 ID로 변경 필요)
        CGWindowID excludedWindowID = 92261; // 제외할 창의 ID (0은 제외 없음)
        listWindowsAndCapture(excludedWindowID);
    }
    return 0;
}