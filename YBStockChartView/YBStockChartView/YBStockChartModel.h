//
//  YBStockChartModel.h
//  YBStockChartView
//
//  Created by YYB on 16/10/12.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface YBStockChartModel : NSObject
// 成交量
@property (nonatomic, assign) NSInteger volume;
// 开盘价
@property (nonatomic, assign) CGFloat open;
// 收盘价
@property (nonatomic, assign) CGFloat close;
// 最高价
@property (nonatomic, assign) CGFloat high;
// 最低价
@property (nonatomic, assign) CGFloat low;
// 日期时间
@property (nonatomic, copy) NSString *date;
// 5日均线
@property (nonatomic, assign) CGFloat ma5;
// 10日均线
@property (nonatomic, assign) CGFloat ma10;
// 20日均线
@property (nonatomic, assign) CGFloat ma20;

// 5日成交量均线
@property (nonatomic, assign) CGFloat ma5Volume;
// 10日成交量均线
@property (nonatomic, assign) CGFloat ma10Volume;
@end


@interface YBStockTimeModel : NSObject

/** 即时成交时间 **/
@property (nonatomic, copy) NSString *time;
/** 即时成交价 **/
@property (nonatomic, assign) CGFloat price;
/** 每分钟成交量(注意:有的后台返回的是总的成交量) **/
@property (nonatomic, assign) NSInteger volume;
/** 昨日收盘价 **/
@property (nonatomic, assign) CGFloat yesterdayClose;
/** 均价 **/
@property (nonatomic, assign) CGFloat avgPrice;
@end

@interface YBStockFiveDayModel : YBStockTimeModel

/** 日期 **/
@property (nonatomic, copy) NSString *date;

@end
