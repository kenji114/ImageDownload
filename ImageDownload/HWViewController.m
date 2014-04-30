//
//  HWViewController.m
//  ImageDownload
//
//  Created by Kenji SHIMIZU on 2014/02/04.
//  Copyright (c) 2014年 Kenji SHIMIZU. All rights reserved.
//

#import "HWViewController.h"

@interface HWViewController () <NSURLSessionDownloadDelegate>

@property (weak, nonatomic) IBOutlet UITextField *URLname;
@property (weak, nonatomic) IBOutlet UITextField *tryNum;
@property (weak, nonatomic) IBOutlet UITextField *Interval;
@property (weak, nonatomic) IBOutlet UITextField *calcRes;

@property (weak, nonatomic) IBOutlet UILabel *downOrUp;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *percentView;
@property (weak, nonatomic) IBOutlet UILabel *instantRateView;
@property (weak, nonatomic) IBOutlet UILabel *aveRateView;

- (IBAction)startSession:(id)sender;

@end

NSDate *startTime, *lastTime, *currTime;
int64_t lastBytesWritten = 0;
int64_t fileSize = 0;
unsigned int ntryMax = 1;
unsigned int ntry = 0;
unsigned int tryCount = 0;
float resolution = 1.0;
NSFileHandle *fileHandle = nil;

@implementation HWViewController

- (void)viewDidLoad
{
    _URLname.text = @"http://www.kiriko-sandblast.com/10MB.bin";
    _tryNum.text = @"1";
    _Interval.text = @"1";
    _calcRes.text = @"1.0";
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)getCurrentDataString
{
    // NsDate => NSString変換用のフォーマッタを作成
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"]]; // Localeの指定
    [df setDateFormat:@"yyyyMMdd-HHmmss-SSS"];
    
    // 日付(NSDate) => 文字列(NSString)に変換
    NSDate *now = [NSDate date];
    NSString *strNow = [df stringFromDate:now];
    
    return strNow;
}

- (IBAction)startSession:(id)sender {
    
    NSLog(@"URLは、%@", _URLname.text);
    NSLog(@"繰り返し回数は、%@", _tryNum.text);
    NSLog(@"繰り返し間隔は、%@", _Interval.text);
    NSLog(@"解像度は、%@", _calcRes.text);
    
    ntryMax = [_tryNum.text intValue];
    ntry = 0;
    tryCount = ntryMax;
    lastBytesWritten = 0;
    fileSize = 0;
    resolution = [_calcRes.text floatValue];
    
    NSString *currData = [self getCurrentDataString];
    NSString *filename = [NSString stringWithFormat:@"/Documents/%@.txt",currData];
    NSLog(@"ファイル名 %@", filename);
    
    // ホームディレクトリを取得
    NSString *homeDir = NSHomeDirectory();
    // 書き込みたいファイルのパスを作成
    NSString *filePath = [homeDir stringByAppendingPathComponent:filename];
    // ファイルマネージャを作成
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // ファイルが存在しないか?
    if (![fileManager fileExistsAtPath:filePath]) { // yes
        // 空のファイルを作成する
        BOOL result = [fileManager createFileAtPath:filePath
                                           contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"ファイルの作成に失敗");
            return;
        }
    }
    
    // ファイルハンドルを作成する
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
    if (!fileHandle) {
        NSLog(@"ファイルハンドルの作成に失敗");
        return;
    }else{
        NSLog(@"ファイルハンドルの作成成功");
    }
    
    [self downloadTaskWithDelegate];
}

- (void)downloadTaskWithDelegate
{
    //NSLog(@"1");
    
    // NSURL* url = [NSURL URLWithString:@"http://www.kiriko-sandblast.com/10MB.bin"];
    NSURL* url = [NSURL URLWithString:_URLname.text];
    // NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // バックグラウンドタスクとしてダウンロードを実行
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"backgroundTask"];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    // データをファイルとしてダウンロード
    NSURLSessionDownloadTask* task = [session downloadTaskWithURL:url];
    

    lastBytesWritten = 0;
    fileSize = 0;
    
    _progressView.progress = 0;
    _percentView.text = [NSString stringWithFormat:@"%2.1f  %%", 0.0];
    _instantRateView.text = [NSString stringWithFormat:@"%2.1f  kbps", 0.0];
    _aveRateView.text = [NSString stringWithFormat:@"%2.1f  kbps", 0.0];

    
    // NSLog(@"startTime: %@", startTime);
    // NSLog(@"lastTime: %@", startTime);

    startTime = [NSDate date];
    lastTime = [NSDate date];
    
    _downOrUp.text = [NSString stringWithFormat:@"Download %d 回目", ++ntry];
    [task resume];

    
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    NSLog(@"2");
    
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    //NSLog(@"3");
    
    currTime = [NSDate date];
    
//    float interval = [currTime timeIntervalSinceDate:lastTime];
    
    float percent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
//    float insRate = (float)(totalBytesWritten - lastBytesWritten)/(float)interval;

/** debug start **/
//    int64_t receivedSize = totalBytesWritten - lastBytesWritten;
//    NSLog(@"--%@-- --%lld--", [self getCurrentDataString], receivedSize);
/** debug end **/
    
    fileSize = totalBytesExpectedToWrite;
    _progressView.progress = percent;
    
//    if (interval > resolution) {

//        _percentView.text = [NSString stringWithFormat:@"%2.1f  %%",percent*100];
//        _instantRateView.text = [NSString stringWithFormat:@"%3.1f kbps",insRate/1000];
        
//        NSString *writeLine1 = [NSString stringWithFormat:@"%@, %@, %@\n", [self getCurrentDataString], _percentView.text, _instantRateView.text];
//        NSData *data1 = [NSData dataWithBytes:writeLine1.UTF8String length:writeLine1.length];
        
//        NSLog(@"%@", writeLine1);
        
//        [fileHandle writeData:data1];
//        [fileHandle synchronizeFile];
        
//        lastTime = currTime;
//        lastBytesWritten = totalBytesWritten;
//    }
   
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    //NSLog(@"4");
    
    //NSLog(@"filesize %lld ", fileSize);
    //NSLog(@"lastbyteswritten %lld ", lastBytesWritten);
    
    //if(fileSize == 0) return;

    currTime = [NSDate date];
    float intervalFromStart = [currTime timeIntervalSinceDate:startTime];
    float intervalFromLast = [currTime timeIntervalSinceDate:lastTime];
    
    float aveRate = (float)fileSize/intervalFromStart;
    _aveRateView.text = [NSString stringWithFormat:@"%3.1f kbps",aveRate/1000];
    
    if (fileSize > lastBytesWritten){
        float insRate = (float)(fileSize - lastBytesWritten)/intervalFromLast;
        _instantRateView.text = [NSString stringWithFormat:@"%3.1f kbps",insRate/1000];
    }

    _progressView.progress = 1.0;
    _percentView.text = [NSString stringWithFormat:@"%2.1f  %%", 100.0];
    
    NSString *writeLine1 = [NSString stringWithFormat:@"%@, %@, %@ %@\n", [self getCurrentDataString], _percentView.text, _instantRateView.text, _aveRateView.text];
    NSData *data1 = [NSData dataWithBytes:writeLine1.UTF8String length:writeLine1.length];
    
    NSLog(@"%@",writeLine1);

    [fileHandle writeData:data1];
    [fileHandle synchronizeFile];

    
    // ファイルを移動
    /**
     NSFileManager* manager = [NSFileManager defaultManager];
     NSString* documentPath =
     [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
     NSURL* dstURL = [NSURL fileURLWithPath:[documentPath stringByAppendingPathComponent:@"test.zip"]];
     NSError* err = nil;
     [manager moveItemAtURL:location toURL:dstURL error:&err];
     **/

    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{

    //[session finishTasksAndInvalidate];
    [session invalidateAndCancel];

    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
    tryCount--;
    
    if(tryCount > 0){
        sleep([_Interval.text intValue]);
        [self downloadTaskWithDelegate];
    }
    
    if (tryCount == 0) {
        NSLog(@"close file ファイルをクローズします。tryCount = %d",tryCount);
        [fileHandle closeFile];
    }
    
}

@end
