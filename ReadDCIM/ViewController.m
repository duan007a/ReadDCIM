//
//  ViewController.m
//  ReadDCIM
//
//  Created by 段洪春 on 2018/2/20.
//  Copyright © 2018年 RS. All rights reserved.
//

#import "ViewController.h"
#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/UTCoreTypes.h>

static const NSUInteger BufferSize = 1024*1024;

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status == PHAuthorizationStatusAuthorized) {
            [self selectVideoFromDCIM];
        }
    }];
    
    [self readDCIMImmediately];
}

- (void)readDCIM {
    PHFetchResult<PHAsset *> *videos = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeVideo options:nil];//这样获取
    for (PHAsset *asset in videos) {
        if (asset.mediaType == PHAssetMediaTypeVideo) {
            PHImageRequestOptions *option = [PHImageRequestOptions new];
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                NSLog(@"你好%zd,%@,%@",imageData.length,dataUTI,info);
            }];
        }
    }
}

- (void)selectVideoFromDCIM
{
    UIImagePickerController *ctrl = [[UIImagePickerController alloc] init];
    ctrl.delegate = self;
    ctrl.mediaTypes = @[(NSString *)kUTTypeMovie];
    [self presentViewController:ctrl animated:NO completion:nil];
}

- (void)readDCIMImmediately {
    NSError *readError;
    
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:[NSURL URLWithString:@"file:///var/mobile/Media/DCIM/100APPLE/IMG_0991.MOV"] error:&readError];
    NSData *data = [handle readDataToEndOfFile];
    NSLog(@"data.length = %ld", data.length);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    [picker dismissViewControllerAnimated:YES completion:^{
        NSURL *assetURL = info[UIImagePickerControllerReferenceURL];
        [self readDataFromAL:assetURL];
    }];
}

- (void)readDataFromAL:(NSURL *)assetURL {
    __block NSError *readError;
    ALAssetsLibrary *al = [[ALAssetsLibrary alloc] init];
    [al assetForURL:assetURL resultBlock:^(ALAsset *asset) {
        ALAssetRepresentation *rep = asset.defaultRepresentation;
        uint8_t *buffer = calloc(BufferSize, sizeof(*buffer));
        NSUInteger offset = 0, bytesRead = 0;
        
        do {
            @try {
                bytesRead = [rep getBytes:buffer fromOffset:offset length:BufferSize error:&readError];
                NSData *tmpData = [[NSData alloc] initWithBytes:buffer length:bytesRead];
                NSLog(@"tmpData.length = %zd", tmpData.length);
                
                offset += bytesRead;
            } @catch (NSException *exception) {
                free(buffer);
            }
        } while (bytesRead > 0);
        
        free(buffer);
    } failureBlock:^(NSError *error) {
        NSLog(@"error: %@",error);
    }];
    
    if (readError) {
        NSLog(@"error: %@",readError);
    }
}


@end
