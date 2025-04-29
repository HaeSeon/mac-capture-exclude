#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <ImageIO/ImageIO.h>
#include <node.h>
#include <node_buffer.h>
#include <iostream>
#include <vector>

namespace screenshot {

using v8::FunctionCallbackInfo;
using v8::Isolate;
using v8::Local;
using v8::Object;
using v8::Value;
using v8::ArrayBuffer;
using v8::String;

// 이미지 데이터를 메모리에 저장하는 함수
CFDataRef createImageData(CGImageRef image) {
    if (!image) return nullptr;
    
    // PNG 포맷으로 이미지 데이터 생성
    CFMutableDataRef data = CFDataCreateMutable(nullptr, 0);
    CGImageDestinationRef destination = CGImageDestinationCreateWithData(data, kUTTypePNG, 1, nullptr);
    
    if (!destination) {
        CFRelease(data);
        return nullptr;
    }
    
    CGImageDestinationAddImage(destination, image, nullptr);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    return data;
}

// Node.js에서 호출할 함수
void CaptureScreen(const FunctionCallbackInfo<Value>& args) {
    Isolate* isolate = args.GetIsolate();

    // 1. 현재 열린 창 목록에서 StepHow 창 찾기
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

        // StepHow 앱의 창 ID 저장 - Electron 또는 StepHow 소유이면서 제목이 StepHow인 창만 제외
        if ([windowTitle isEqualToString:@"StepHow"] && 
            ([ownerName isEqualToString:@"Electron"] || [ownerName isEqualToString:@"StepHow"])) {
            stepHowWindowID = windowID.intValue;
        }
    }

    CFRelease(windowList);

    // 2. StepHow 앱의 창을 제외하고 전체 화면 캡처
    CGImageRef image = CGWindowListCreateImage(
        CGRectInfinite,
        kCGWindowListOptionOnScreenBelowWindow,
        stepHowWindowID,
        kCGWindowImageDefault
    );

    if (!image) {
        args.GetReturnValue().Set(String::NewFromUtf8(isolate, "Failed to capture screen").ToLocalChecked());
        return;
    }

    // 3. 이미지를 PNG 데이터로 변환
    CFDataRef imageData = createImageData(image);
    CFRelease(image);

    if (!imageData) {
        args.GetReturnValue().Set(String::NewFromUtf8(isolate, "Failed to convert image").ToLocalChecked());
        return;
    }

    // 4. PNG 데이터를 Node.js Buffer로 변환
    const void* rawData = CFDataGetBytePtr(imageData);
    size_t dataLength = CFDataGetLength(imageData);
    
    Local<Object> buffer = node::Buffer::Copy(
        isolate,
        static_cast<const char*>(rawData),
        dataLength
    ).ToLocalChecked();

    CFRelease(imageData);
    
    // 5. Buffer를 반환
    args.GetReturnValue().Set(buffer);
}

void Initialize(Local<Object> exports) {
    NODE_SET_METHOD(exports, "captureScreen", CaptureScreen);
}

NODE_MODULE(NODE_GYP_MODULE_NAME, Initialize)

}  // namespace screenshot