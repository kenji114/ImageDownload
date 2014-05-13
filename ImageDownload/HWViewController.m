//
//  HWViewController.m
//  ImageDownload
//
//  Created by Kenji SHIMIZU on 2014/02/04.
//  Copyright (c) 2014年 Kenji SHIMIZU. All rights reserved.
//

#import "HWViewController.h"
#import "HWimageUpload.h"

@interface HWViewController () <NSURLSessionDownloadDelegate>

@property (weak, nonatomic) IBOutlet UITextField *URLname;
@property (weak, nonatomic) IBOutlet UITextField *tryNum;
@property (weak, nonatomic) IBOutlet UITextField *Interval;
@property (weak, nonatomic) IBOutlet UITextField *calcRes;

@property (weak, nonatomic) IBOutlet UILabel *downOrUp;

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *percentView;
@property (weak, nonatomic) IBOutlet UILabel *instantRateView;
@property (weak, nonatomic) IBOutlet UILabel *aveRate2View;
@property (weak, nonatomic) IBOutlet UILabel *generalStatusView;
@property (weak, nonatomic) IBOutlet UISwitch *logSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *dlSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *upSwitch;

- (IBAction)bkgTapped:(id)sender;
- (IBAction)startSession:(id)sender;


@end

NSDate *startTime, *lastTime, *currTime;
NSDate *dispStartTime, *dispLastTime, *dispCurrTime;
int64_t lastBytesWritten = 0;
int64_t dispLastBytesWritten = 0;
unsigned int ntryMax = 1;
unsigned int ntry = 0;
unsigned int tryCount = 0;
float resolution = 1.0;
NSFileHandle *fileHandle = nil;
NSTimer *timer = nil;
NSURLSessionDownloadTask* task = nil;
bool sessionFinish = false;
NSURLSession* session = nil;
float aveRate2 = 0.0;

@implementation HWViewController

- (void)viewDidLoad
{
    _URLname.text = @"http://www.kiriko-sandblast.com/10MB.bin";
    _tryNum.text = @"1";
    _Interval.text = @"1";
    _calcRes.text = @"1.0";
    
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self.scrollView setContentSize:CGSizeMake(320, 750)];
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

- (void)updateRate:(NSTimer *)timer
{
    
    currTime = [NSDate date];
    int64_t totalCount = [task countOfBytesExpectedToReceive];
    int64_t recvCount = [task countOfBytesReceived];
    float intervalSinceLast = [currTime timeIntervalSinceDate:lastTime];
    float percent = 0.0;
    float insRate = 0.0;
    
    if (totalCount > 0) {
        percent = (float)recvCount*100/(float)totalCount;
    }

    insRate = (float)(recvCount - lastBytesWritten)*8.0/intervalSinceLast;
    
    NSString *writeLine1 = [NSString stringWithFormat:@"DL: %@, %lld, %lld, %2.3f %%, %3.1f kbps, %lld, %1.3f\n",
                            [self getCurrentDataString],
                            recvCount,
                            totalCount,
                            percent,
                            insRate/1000,
                            recvCount - lastBytesWritten,
                            intervalSinceLast
                            ];
    NSData *data1 = [NSData dataWithBytes:writeLine1.UTF8String length:writeLine1.length];
    
//    NSLog(@"%@", writeLine1);
    
    if (_logSwitch.on) {
        [fileHandle writeData:data1];
        [fileHandle synchronizeFile];
    }
    
    lastTime = currTime;
    lastBytesWritten = recvCount;
    
    if(sessionFinish == true){
        float intervalFromStart = [currTime timeIntervalSinceDate:startTime];
        float aveRate = (float)totalCount*8/intervalFromStart;
        
        writeLine1 = [NSString stringWithFormat:@"DL: %@, Ave. Rate: %3.1f kbps, Ave. Rate2: %3.1f kbps\n",
                      [self getCurrentDataString],
                      aveRate/1000,
                      aveRate2/1000];
        
        data1 = [NSData dataWithBytes:writeLine1.UTF8String length:writeLine1.length];
        NSLog(@"%@", writeLine1);
        
        if (_logSwitch.on) {
            [fileHandle writeData:data1];
            [fileHandle synchronizeFile];
        }

        [session invalidateAndCancel];
    }
}


- (void)downloadTaskWithDelegate
{
    aveRate2 = 0.0;
    lastBytesWritten = 0;
    dispLastBytesWritten = 0;
    
    startTime = [NSDate date];
    lastTime = [NSDate date];
    dispStartTime = [NSDate date];
    dispLastTime = [NSDate date];
    sessionFinish = false;

    
    NSURL* url = [NSURL URLWithString:_URLname.text];
    // NSURLSessionConfiguration* config = [NSURLSessionConfiguration defaultSessionConfiguration];
    // バックグラウンドタスクとしてダウンロードを実行
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"backgroundTask"];
    session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
        // データをファイルとしてダウンロード
    task = [session downloadTaskWithURL:url];
    
    _progressView.progress = 0;
    _percentView.text = [NSString stringWithFormat:@"%2.1f  %%", 0.0];
    _instantRateView.text = [NSString stringWithFormat:@"%2.1f  kbps", 0.0];
    _aveRate2View.text = [NSString stringWithFormat:@"%2.1f  kbps", 0.0];
    _downOrUp.text = [NSString stringWithFormat:@"Download %d 回目", ++ntry];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:[_calcRes.text floatValue] target:self                                                                 selector:@selector(updateRate:) userInfo:nil repeats:YES];
    
    [task resume];
    
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{

    dispCurrTime = [NSDate date];
    float thisInterval = [dispCurrTime timeIntervalSinceDate:dispLastTime];
    float thisPercent = (float)totalBytesWritten / (float)totalBytesExpectedToWrite;
    float thisInsRate = (float)(totalBytesWritten - dispLastBytesWritten)*8.0 / thisInterval;
    
    _progressView.progress = thisPercent;
    
    if(thisInterval > 0.2){
        _instantRateView.text = [NSString stringWithFormat:@"%3.1f kbps",thisInsRate/1000];
        _percentView.text = [NSString stringWithFormat:@"%2.3f  %%",thisPercent*100];
        
        dispLastBytesWritten = totalBytesWritten;
        dispLastTime = dispCurrTime;
    }
    
}

// Delegateタスク
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{

    currTime = [NSDate date];
    float intervalFromStart = [currTime timeIntervalSinceDate:startTime];
    float intervalFromLast = [currTime timeIntervalSinceDate:dispLastTime];
    float thisInsRate = 0.0;
    
    if ((intervalFromLast > 0.0) && ([task countOfBytesReceived] - dispLastBytesWritten) > 0){
        thisInsRate = (float)([task countOfBytesReceived] - dispLastBytesWritten)*8.0 / intervalFromLast;
        
        _instantRateView.text = [NSString stringWithFormat:@"%3.1f kbps",thisInsRate/1000];
        _percentView.text = [NSString stringWithFormat:@"%2.3f  %%",
                             (float)[task countOfBytesReceived]*100.0/(float)([task countOfBytesExpectedToReceive])];
    }
    
    if (intervalFromStart > 0.0) {
        aveRate2 = (float)[task countOfBytesReceived]*8/intervalFromStart;
        _aveRate2View.text = [NSString stringWithFormat:@"%3.1f kbps",aveRate2/1000];
    }
    
    sessionFinish = true;
    
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error
{
    
    if ([timer isValid]) {
        [timer invalidate];
    }
    
    tryCount--;
    
    if(tryCount > 0){
        sleep([_Interval.text intValue]);
        [self downloadTaskWithDelegate];
    }
    
    
    if (tryCount == 0) {
        NSLog(@"close file ファイルをクローズします。tryCount = %d",tryCount);
        task = nil;
        session = nil;
        _generalStatusView.text = @"セッションは停止しています。";

        [fileHandle closeFile];
    }
    
}

- (IBAction)bkgTapped:(id)sender {
    [self.view endEditing:YES];
}

- (IBAction)startSession:(id)sender {
    
    if(task != nil && session != nil){
        _generalStatusView.text = @"セッションが残っています。";
        return;
    }else{
        _generalStatusView.text = @"セッションを開始します。";
    }
    
    // [HWimageUpload uploadTest];
    
    
    ntryMax = [_tryNum.text intValue];
    ntry = 0;
    tryCount = ntryMax;
    
    NSString *currDate = [self getCurrentDataString];
    NSString *filename = [NSString stringWithFormat:@"/Documents/%@.txt",currDate];
    //NSLog(@"ファイル名 %@", filename);
    
    if (_logSwitch.on) {
    
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
        }
        
    }
    
    if (_dlSwitch.on) {
        [self downloadTaskWithDelegate];
    }

    
}
@end
