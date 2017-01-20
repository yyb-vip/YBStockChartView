//
//  YBStockFiveDayView.h
//  YBStockChartView
//
//  Created by YYB on 16/10/23.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YBStockChartModel.h"
@class YBStockFiveDayView;
@protocol YBStockFiveDayModelDelegate <NSObject>

@optional
/**
 *  长按触发
 *
 *  @param chartView            当前视图
 *  @param entityModel          长按选中的实体模型
 *  @param entityModelIndexPath 长按选中的实体模型在数组中的下标
 */
- (void)longPressStockFiveDayView:(YBStockFiveDayView *)chartView currentEntityModel:(YBStockFiveDayModel *)entityModel entityModelIndexPath:(NSIndexPath *)entityModelIndexPath;

@end

@interface YBStockFiveDayView : UIView

@property (nonatomic, assign) id<YBStockFiveDayModelDelegate> delegate;

/** 数据源 **/
@property (nonatomic, strong) NSArray<NSMutableArray<YBStockFiveDayModel *> *> *dataArray;

/** 内边距(默认:1,1,1,1) **/
@property (nonatomic, assign) UIEdgeInsets padding;
/** K线成交量的比例,范围(0,1)(默认:0.7) **/
@property (nonatomic, assign) CGFloat prop;
/** K线成交量之间距离(默认:0.0) **/
@property (nonatomic, assign) CGFloat upDownModeMargen;
/** 价格label字体大小,日期,移动时候显示的大小(默认:10.0) **/
@property (nonatomic, assign) CGFloat defaultTextSize;


/** 背景线颜色(默认:White:0.4) **/
@property (nonatomic, strong) UIColor *lineColor;
/** 背景颜色(默认:黑色) **/
@property (nonatomic, strong) UIColor *bgColor;
/** 成交量涨幅颜色(默认:红色) **/
@property (nonatomic, strong) UIColor *riseVolumnColor;
/** 成交量跌幅颜色(默认:绿色) **/
@property (nonatomic, strong) UIColor *fallVolumnColor;
/** 长按显示的价格以及日期颜色(默认:黑色)**/
@property (nonatomic, strong) UIColor *longPressTextColor;
/** 长按显示label背景颜色(默认:White:0.5)**/
@property (nonatomic, strong) UIColor *longPressLabelBgColor;
/** 实时价格线颜色(默认:白色) **/
@property (nonatomic, strong) UIColor *priceLineColor;
/** 均线颜色(默认:黄色) **/
@property (nonatomic, strong) UIColor *avgLineColor;
/** 十字线颜色(默认:白色) **/
@property (nonatomic, strong) UIColor *crossLineColor;

/** 是否支持长按手势(默认:支持) **/
@property (nonatomic, assign) BOOL longPressEnabled;

@end



