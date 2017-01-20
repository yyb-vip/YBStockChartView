//
//  YBStockChartView.h
//  YBStockChartView
//
//  Created by YYB on 16/10/11.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBStockChartModel.h"
@class YBStockChartView;
@protocol YBStockChartViewDelegate <NSObject>

@optional
/**
 *  长按触发
 *
 *  @param chartView        当前视图
 *  @param entityModel      长按选中的实体模型
 *  @param entityModelIndex 长按选中的实体模型在数组中的下标
 */
- (void)longPressStockChartView:(YBStockChartView *)chartView currentEntityModel:(YBStockChartModel *)entityModel entityModelIndex:(NSInteger)entityModelIndex;
@end

@interface YBStockChartView : UIView
/** 代理 **/
@property (nonatomic, assign) id<YBStockChartViewDelegate> delegate;
/** 股票数据源数组 **/
@property (nonatomic, strong) NSMutableArray <YBStockChartModel *> *dataArray;

/** 内边距(默认:1,1,1,1) **/
@property (nonatomic, assign) UIEdgeInsets padding;
/** K线成交量的比例,范围(0,1)(默认:0.6) **/
@property (nonatomic, assign) CGFloat prop;
/** K线成交量之间距离,默认是20 **/
@property (nonatomic, assign) CGFloat upDownModeMargen;
/** 价格label字体大小,日期,移动时候显示的大小(默认:10.0) **/
@property (nonatomic, assign) CGFloat defaultTextSize;

/** 均线宽度(默认:1.0) **/
@property (nonatomic, assign) CGFloat avgLineWidth;
/** K线宽度(蜡烛实体宽度)(默认:8.0) **/
@property (nonatomic, assign) CGFloat candleWidth;
/** 最大宽度(默认:20.0) **/
@property (nonatomic, assign) CGFloat maxCandleWidth;
/** 最小K线宽度(默认:1.0) **/
@property (nonatomic, assign) CGFloat minCandleWidth;

/** 背景线线颜色(默认:White:0.4) **/
@property (nonatomic, strong) UIColor *lineColor;
/** 背景颜色(默认是黑色) **/
@property (nonatomic, strong) UIColor *bgColor;
/** 价格以及日期label字体颜色(默认:White:0.4) **/
@property (nonatomic, strong) UIColor *priceTextColor;
/** 长按显示的价格以及日期颜色(默认:黑色)**/
@property (nonatomic, strong) UIColor *longPressTextColor;
/** 长按显示label背景颜色(默认:White:0.5)**/
@property (nonatomic, strong) UIColor *longPressLabelBgColor;
/** 十字线颜色(默认是白色) **/
@property (nonatomic, strong) UIColor *crossLineColor;
/** 涨幅颜色(默认:红色) **/
@property (nonatomic, strong) UIColor *candleRiseColor;
/** 跌幅颜色(默认:浅蓝色) **/
@property (nonatomic, strong) UIColor *candleFallColor;
/** 5日均线颜色(默认:白色) **/
@property (nonatomic, strong) UIColor *ma5AvgLineColor;
/** 10日均线颜色(默认:黄色) **/
@property (nonatomic, strong) UIColor *ma10AvgLineColor;
/** 20日均线颜色(默认:紫色) **/
@property (nonatomic, strong) UIColor *ma20AvgLineColor;

/** 是否支持长按手势(默认:支持) **/
@property (nonatomic, assign) BOOL longPressEnabled;
/** 是否支持滑动手势(默认:支持) **/
@property (nonatomic, assign) BOOL panEnabled;
/** 是否支持啮合放大缩小手势(默认:支持) **/
@property (nonatomic, assign) BOOL pinEnabled;
/** 是否支持轻拍切换类型手势(默认:支持) **/
@property (nonatomic, assign) BOOL tapEnabled;
@end
