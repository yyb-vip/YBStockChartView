//
//  RootViewController.m
//  YBStockChartView
//
//  Created by YYB on 16/10/11.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import "StockChartViewController.h"
#import "YBStockChartView.h"
#import "YBStockTimeView.h"
#import "YBStockFiveDayView.h"
#import "YBStockChartModel.h"
#import "CustomView.h"
@interface StockChartViewController ()<YBStockChartViewDelegate, YBStockTimeViewDelegate, YBStockFiveDayModelDelegate>
@property (nonatomic, strong) YBStockChartView *stockChartView;
@property (nonatomic, strong) YBStockTimeView *stockChartTimeView;
@property (nonatomic, strong) YBStockFiveDayView *stockFiveDayView;
@end

@implementation StockChartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.frame = CGRectMake(20, [UIScreen mainScreen].bounds.size.height - 70, 50, 50);
    backBtn.backgroundColor = [UIColor cyanColor];
    [backBtn setTitle:@"Back" forState:UIControlStateNormal];
    backBtn.layer.cornerRadius = 25;
    [backBtn addTarget:self action:@selector(handleBackBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backBtn];
    
    UISegmentedControl *segmentControl = [[UISegmentedControl alloc] initWithItems:@[@"分时", @"五日", @"日K"]];
    segmentControl.frame = CGRectMake(20, 50, [UIScreen mainScreen].bounds.size.width-40, 40);
    segmentControl.selectedSegmentIndex = 0;
    [segmentControl addTarget:self action:@selector(handleSegmentControlAction:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:segmentControl];
    
    
    [self stockChartViewTest];
    [self stockChartTimeViewTest];
    [self stockFiveDayViewTest];
    
}

- (void)handleBackBtnAction:(UIButton *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)handleSegmentControlAction:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        _stockChartView.hidden = YES;
        _stockChartTimeView.hidden = NO;
        _stockFiveDayView.hidden = YES;
    }
    if (sender.selectedSegmentIndex == 1) {
        _stockChartTimeView.hidden = YES;
        _stockChartView.hidden = YES;
        _stockFiveDayView.hidden = NO;
    }
    if (sender.selectedSegmentIndex == 2) {
        _stockChartView.hidden = NO;
        _stockChartTimeView.hidden = YES;
        _stockFiveDayView.hidden = YES;
    }
}

#pragma mark - 股票视图
- (void)stockChartViewTest
{
    self.stockChartView = [[YBStockChartView alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 300)];
    self.stockChartView.prop = 0.7;
    self.stockChartView.delegate = self;
    self.stockChartView.padding = UIEdgeInsetsMake(10, 10, 0, 10);
    [self.view addSubview:self.stockChartView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // 初始化模型数组
        NSMutableArray *modelArray = [NSMutableArray array];
        // 获取日K数据
        NSArray *array = [self getOneDayStockData];
        // 添加模型到模型数组
        for (int i = 0; i < array.count; i ++) {
            NSArray *tempArr = array[i];
            YBStockChartModel *model = [[YBStockChartModel alloc] init];
            model.open = [tempArr[1] doubleValue]; // 开盘价
            model.close = [tempArr[2] doubleValue];// 收盘价
            model.high = [tempArr[3] doubleValue]; // 最高价
            model.low = [tempArr[4] doubleValue];  // 最低价
            model.volume = [tempArr[5] integerValue]; // 成交量
            model.date = tempArr[0]; // 日期
            if (i >= 4) {
                for (int j = 0; j < 5; j ++) {
                    model.ma5 = model.ma5 + [array[i - j][2] doubleValue];
                    model.ma5Volume = model.ma5Volume + [array[i - j][5] doubleValue];
                }
                model.ma5 = model.ma5 / 5.0;    // 五日均价
                model.ma5Volume = model.ma5Volume / 5.0;    // 五日成交量均价
            }
            if (i >= 9) {
                for (int j = 0; j < 10; j ++) {
                    model.ma10 = model.ma10 + [array[i - j][2] doubleValue];
                    model.ma10Volume = model.ma10Volume + [array[i - j][5] doubleValue];
                }
                model.ma10 = model.ma10 / 10.0; // 十日均价
                model.ma10Volume = model.ma10Volume / 10.0; // 十日成交量均价
            }
            if (i >= 19) {
                for (int j = 0; j < 20; j ++) {
                    model.ma20 = model.ma20 + [array[i - j][2] doubleValue];
                }
                model.ma20 = model.ma20 / 20.0; // 二十日均价
            }
            [modelArray addObject:model];   // 添加模型到数组
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stockChartView.dataArray = modelArray; // 赋值
            [self.stockChartView setNeedsDisplay];  //  刷新界面
        });
    });
}

- (NSArray *)getOneDayStockData
{
    NSString *requestStr = [NSString stringWithFormat:@"http://web.ifzq.gtimg.cn/appstock/app/fqkline/get?_var=kline_dayqfq&param=%@,day,,,320,qfq&r=0.14639775198884308", self.sharesCode];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:requestStr]];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *str = [[NSString alloc] initWithData:data encoding:enc];
    NSString *regularStr = @"^[^=]*=";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray <NSTextCheckingResult *>*resultArray = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSTextCheckingResult *result = [resultArray firstObject];
    str = [str stringByReplacingOccurrencesOfString:[str substringWithRange:result.range] withString:@""];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    NSArray *array = dict[@"data"][self.sharesCode][@"day"];
    if (array == nil || array.count == 0) {
        array = dict[@"data"][self.sharesCode][@"qfqday"];
    }
    return array;
}

#pragma mark - 分时
- (void)stockChartTimeViewTest
{
    self.stockChartTimeView = [[YBStockTimeView alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 300)];
    self.stockChartTimeView.delegate = self;
    self.stockChartTimeView.padding = UIEdgeInsetsMake(10, 10, 0, 10);
    [self.view addSubview:self.stockChartTimeView];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *dict = [self getTimeData];    // 获取数据
        NSMutableArray *modelArray = [NSMutableArray array];
        NSArray *listArray = dict[@"data"][self.sharesCode][@"data"][@"data"];
        NSString *closeYesterday = dict[@"data"][self.sharesCode][@"qt"][self.sharesCode][4];
        CGFloat total_a = 0;
        CGFloat total_b = 0;
        for (int i = 0; i < listArray.count; i ++) {
            NSString *tempStr = listArray[i];
            NSArray *tempArray = [tempStr componentsSeparatedByString:@" "];
            YBStockTimeModel *model = [[YBStockTimeModel alloc] init];
            model.price = [tempArray[1] doubleValue];   // 即时成交价
            model.yesterdayClose = [closeYesterday doubleValue];    // 昨日收盘价
            model.time = tempArray[0];  // 成交时间
            if (i == 0) {
                model.volume = [tempArray[2] doubleValue];
                model.avgPrice = model.price;
            }else{
                NSString *str = listArray[i - 1];
                NSArray *arr = [str componentsSeparatedByString:@" "];
                total_a = total_a + (model.price * ([tempArray[2] doubleValue] - [arr[2] doubleValue]));
                total_b = total_b + ([tempArray[2] doubleValue] - [arr[2] doubleValue]);
                model.avgPrice = total_a / total_b; // 均价(总成交额 / 总成交量)
                model.volume = [tempArray[2] doubleValue] - [arr[2] doubleValue]; // 成交量
            }
            [modelArray addObject:model];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.stockChartTimeView.dataArray = modelArray;
            [self.stockChartTimeView setNeedsDisplay];
        });
    });
}

- (NSDictionary *)getTimeData
{
    NSString *riseUrlStr = [NSString stringWithFormat:@"http://web.ifzq.gtimg.cn/appstock/app/minute/query?_var=min_data_%@&code=%@&r=0.25370021839626133", self.sharesCode, self.sharesCode];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:riseUrlStr]];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *str = [[NSString alloc] initWithData:data encoding:enc];
    NSString *regularStr = @"^[^=]*=";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray <NSTextCheckingResult *>*resultArray = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSTextCheckingResult *result = [resultArray firstObject];
    str = [str stringByReplacingOccurrencesOfString:[str substringWithRange:result.range] withString:@""];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    return dict;
}

#pragma mark - 五日
- (void)stockFiveDayViewTest
{
    self.stockFiveDayView = [[YBStockFiveDayView alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 300)];
    self.stockFiveDayView.delegate = self;
    self.stockFiveDayView.hidden = YES;
    self.stockFiveDayView.padding = UIEdgeInsetsMake(10, 10, 0, 10);
    [self.view addSubview:self.stockFiveDayView];
    [self getFiveDayData];
}


- (void)getFiveDayData
{
    NSString *riseUrlStr = [NSString stringWithFormat:@"http://web.ifzq.gtimg.cn/appstock/app/day/query?_var=fdays_data_%@&code=%@&r=0.6376702517736703", self.sharesCode, self.sharesCode];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:riseUrlStr]];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *str = [[NSString alloc] initWithData:data encoding:enc];
    NSString *regularStr = @"^[^=]*=";
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regularStr options:NSRegularExpressionCaseInsensitive error:&error];
    NSArray <NSTextCheckingResult *>*resultArray = [regex matchesInString:str options:0 range:NSMakeRange(0, str.length)];
    NSTextCheckingResult *result = [resultArray firstObject];
    str = [str stringByReplacingOccurrencesOfString:[str substringWithRange:result.range] withString:@""];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    
    CGFloat yesterday = [dict[@"data"][self.sharesCode][@"qt"][self.sharesCode][4] doubleValue];
    NSArray *arr =  dict[@"data"][self.sharesCode][@"data"];
    NSMutableArray *dataArray = [NSMutableArray array];
    for (NSInteger i = arr.count - 1; i >= 0; i --) {
        NSMutableArray *addArray = [NSMutableArray array];
        NSString *date = arr[i][@"date"];
        NSMutableArray *dayArr = arr[i][@"data"];
        [dayArr removeLastObject];
        CGFloat total_a = 0;
        CGFloat total_b = 0;
        for (int j = 0; j < dayArr.count; j ++) {
            NSString *str = dayArr[j];
            NSArray *tempArray = [str componentsSeparatedByString:@" "];
            YBStockFiveDayModel *model = [[YBStockFiveDayModel alloc] init];
            model.date = date;
            model.price = [tempArray[1] doubleValue];
            model.volume = [tempArray[2] integerValue];
            model.time = tempArray[0];
            model.yesterdayClose = yesterday;
            if (j == 0) {
                model.volume = [tempArray[2] doubleValue];
                model.avgPrice = model.price;
            }else{
                NSString *str = dayArr[j - 1];
                NSArray *arr = [str componentsSeparatedByString:@" "];
                total_a = total_a + (model.price * ([tempArray[2] doubleValue] - [arr[2] doubleValue]));
                total_b = total_b + ([tempArray[2] doubleValue] - [arr[2] doubleValue]);
                model.avgPrice = total_a / total_b; // 均价(总成交额 / 总成交量)
                model.volume = [tempArray[2] doubleValue] - [arr[2] doubleValue]; // 成交量
            }
            [addArray addObject:model];
        }
        [dataArray addObject:addArray];
    }
    _stockFiveDayView.dataArray = dataArray;
    [_stockFiveDayView setNeedsDisplay];
}

#pragma mark - delegate
- (void)longPressStockChartView:(YBStockChartView *)chartView currentEntityModel:(YBStockChartModel *)entityModel entityModelIndex:(NSInteger)entityModelIndex {
    NSLog(@"长按K线视图");
}

- (void)longPressStockTimeView:(YBStockTimeView *)chartView currentEntityModel:(YBStockTimeModel *)entityModel entityModelIndex:(NSInteger)entityModelIndex {
    NSLog(@"长按分时视图");
}

- (void)longPressStockFiveDayView:(YBStockFiveDayView *)chartView currentEntityModel:(YBStockFiveDayModel *)entityModel entityModelIndexPath:(NSIndexPath *)entityModelIndexPath {
    NSLog(@"长按五日视图");
}

@end
