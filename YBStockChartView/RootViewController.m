//
//  RootViewController.m
//  YBStockChartView
//
//  Created by YYB on 16/10/22.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import "RootViewController.h"
#import "ListTableViewHeaderView.h"
#import "StockChartViewController.h"
@interface RootViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <NSArray *>*dataArray;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    [self initAddTableView];
    [self loadData];
}

- (void)initAddTableView{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 20, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-20)];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"ListTableViewHeaderView" bundle:nil] forHeaderFooterViewReuseIdentifier:@"headerView"];
    [self.view addSubview:self.tableView];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.dataArray.count != 0) {
        return self.dataArray[section].count;
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = self.dataArray[indexPath.section][indexPath.row][@"name"];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StockChartViewController *stockVC = [[StockChartViewController alloc] init];
    // 股票代码
    stockVC.sharesCode = self.dataArray[indexPath.section][indexPath.row][@"symbol"];
    [self presentViewController:stockVC animated:YES completion:nil];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 30;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    ListTableViewHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"headerView"];
    if (section == 0) {
        headerView.stockNameLabel.text = @"涨幅";
        headerView.stockNameLabel.textColor = [UIColor redColor];
    }else{
        headerView.stockNameLabel.text = @"跌幅";
        headerView.stockNameLabel.textColor = [UIColor greenColor];
    }
    return headerView;
}

- (void)loadData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *riseTempArray = [self requestRiseData];
        NSArray *fallTempArray = [self requestFallData];
        [self.dataArray addObject:riseTempArray];
        [self.dataArray addObject:fallTempArray];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_tableView reloadData];
        });
    });
}

#pragma mark - 请求上涨数据
- (NSArray *)requestRiseData
{
    NSString *riseUrlStr = [NSString stringWithFormat:@"http://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeData?page=%d&num=20&sort=changepercent&asc=0&node=hs_a&symbol=&_s_r_a=init", 1];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:riseUrlStr]];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *str = [[NSString alloc] initWithData:data encoding:enc];
    str = [str stringByReplacingOccurrencesOfString:@"{" withString:@"{\""];
    str = [str stringByReplacingOccurrencesOfString:@"," withString:@",\""];
    str = [str stringByReplacingOccurrencesOfString:@"\"{" withString:@"{"];
    str = [str stringByReplacingOccurrencesOfString:@":\"" withString:@"\":\""];
    str = [str stringByReplacingOccurrencesOfString:@":([-\\d]\\d*),|:([-\\d]\\d*\\.\\d*)," withString:@"\":\"$1$2\"," options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)];
    str = [str stringByReplacingOccurrencesOfString:@":(\\d*\\.\\d*)" withString:@"\":\"$1\"" options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)];
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    return arr;
}

#pragma mark - 请求下跌数据
- (NSArray *)requestFallData
{
    NSString *riseUrlStr = [NSString stringWithFormat:@"http://vip.stock.finance.sina.com.cn/quotes_service/api/json_v2.php/Market_Center.getHQNodeData?page=%d&num=20&sort=changepercent&asc=1&node=hs_a&symbol=&_s_r_a=init", 1];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:riseUrlStr]];
    NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
    NSString *str = [[NSString alloc] initWithData:data encoding:enc];
    str = [str stringByReplacingOccurrencesOfString:@"{" withString:@"{\""];
    str = [str stringByReplacingOccurrencesOfString:@"," withString:@",\""];
    str = [str stringByReplacingOccurrencesOfString:@"\"{" withString:@"{"];
    str = [str stringByReplacingOccurrencesOfString:@":\"" withString:@"\":\""];
    str = [str stringByReplacingOccurrencesOfString:@":([-\\d]\\d*),|:([-\\d]\\d*\\.\\d*)," withString:@"\":\"$1$2\"," options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)];
    str = [str stringByReplacingOccurrencesOfString:@":(\\d*\\.\\d*)" withString:@"\":\"$1\"" options:NSRegularExpressionSearch range:NSMakeRange(0, str.length)];
    NSArray *arr = [NSJSONSerialization JSONObjectWithData:[str dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    return arr;
}

- (NSMutableArray *)dataArray
{
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
    }
    return _dataArray;
}

@end
