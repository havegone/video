//
//  FileCamera.m
//  video
//
//  Created by Tommy on 14-1-17.
//  Copyright (c) 2014年 com.taobao. All rights reserved.
//

#import "FileCamera.h"

@implementation FileCamera

- (AVCaptureOutput*) createOutput{
    self.fileOutput = [[AVCaptureMovieFileOutput alloc] init];
    return self.fileOutput;
}
- (AVCaptureDeviceInput*)createAudioInput{

    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:nil];
    
    return audioInput;
    
}
- (NSArray*) createInputs{
    self.audioInput = [self createAudioInput];

    return @[self.audioInput];
}

- (NSString*)generatePath{
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectoryPath = [paths objectAtIndex:0];
    NSString *archives = documentsDirectoryPath;
    NSDate* currentTime = [NSDate date];
    
    NSString *outputpathofmovie = [[archives stringByAppendingPathComponent:[currentTime description]] stringByAppendingString:@".mp4"];
    
    self.filePath = outputpathofmovie;
    return outputpathofmovie;
}

- (void)start{
    [super start];
    
    if(!self.filePath){
        [self generatePath];
    }
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:self.filePath];
    
    DefineWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself.fileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
    });
    

}

- (void)stop{
    [super stop];
    DefineWeakSelf();
    dispatch_async(dispatch_get_main_queue(), ^{
        [wself.fileOutput stopRecording];
    });
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didPauseRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections NS_AVAILABLE(10_7, NA){
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didResumeRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections NS_AVAILABLE(10_7, NA){
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput willFinishRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections error:(NSError *)error NS_AVAILABLE(10_7, NA){
    
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    

}

@end
