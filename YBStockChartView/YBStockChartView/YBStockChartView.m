//
//  YBStockChartView.m
//  YBStockChartView
//
//  Created by YYB on 16/10/11.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import "YBStockChartView.h"
// 转换上半部分纵坐标
#define kCalcCandlePoint_y(parameter) ((self.maxPrice - parameter) / (self.maxPrice - self.minPrice)) * (self.bounds.size.height * self.prop - self.padding.top) + self.padding.top
// 转换下半部分纵坐标
#define kCalcVolumePoint_y(parameter) (1 - parameter / (CGFloat)self.maxvolume) * (self.bounds.size.height * (1 - self.prop) - self.padding.bottom - self.defaultTextSize - self.upDownModeMargen - 4) + self.bounds.size.height * self.prop + self.upDownModeMargen

typedef NS_ENUM(NSInteger, YBStockState){
    YBStockStateRise = 1,
    YBStockStateFall
};

//typedef NS_ENUM(NSInteger, YBStockChartType){
//    YBStockChartTypeVolume = 1,
//    YBStockChartTypeMACD,
//    YBStockChartTypeKDJ,
//    YBStockChartTypeRSI,
//    YBStockChartTypeBIAS,
//    YBStockChartTypeCCI,
//    YBStockChartTypeWR,
//    YBStockChartTypeBOLL,
//    YBStockChartTypeEXPMA,
//    YBStockChartTypeTRIX,
//    YBStockChartTypeVR,
//    YBStockChartTypeDMI,
//    YBStockChartTypeDPO,
//    YBStockChartTypeDMA
//};
@interface YBStockChartView ()

// 当前显示的最大价格和最小价格
@property (nonatomic, assign) CGFloat maxPrice;
@property (nonatomic, assign) CGFloat minPrice;
// 当前显示的成交量的最大值
@property (nonatomic, assign) NSInteger maxvolume;
// 开始绘制的K线的下标
@property (nonatomic, assign) NSInteger startDrawIndex;
// 当前显示的K线点数量
@property (nonatomic, assign) NSInteger countOfShowCandle;
// 所要绘制的区域的宽度
@property (nonatomic, assign) CGFloat contentWidth;
// 手指长按触摸点
@property (nonatomic, assign) CGPoint touchPoint;
// 手指是否长按移动
@property (nonatomic, assign) BOOL isLongPressMoveing;
// 触摸点在数组中的位置
@property (nonatomic, assign) NSInteger touchIndexOfDataArray;
// 蜡烛实体之间距离
@property (nonatomic, assign) CGFloat candleMargen;
//// 成交量图标类型
//@property (nonatomic, assign) YBStockChartType volumeChartType;
// 轻拍
@property (nonatomic, strong) UITapGestureRecognizer *tap;
// 长按
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
// 啮合
@property (nonatomic, strong) UIPinchGestureRecognizer *pin;
// 滑动
@property (nonatomic, strong) UIPanGestureRecognizer *pan;
// 啮合手势相关
@property (nonatomic, assign) CGFloat lastPinScale;
@property (nonatomic, assign) CGFloat lastPinCount;

@end

@implementation YBStockChartView

@synthesize dataArray = _dataArray;

#pragma mark - 初始化view方法
- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    // 添加轻拍手势
    [self addGestureRecognizer:self.tap];
    // 添加长按手势
    [self addGestureRecognizer:self.longPress];
    // 添加啮合手势
    [self addGestureRecognizer:self.pin];
    // 添加滑动手势
    [self addGestureRecognizer:self.pan];
}

#pragma mark - 绘制
- (void)drawRect:(CGRect)rect
{
    [self initLineView];                // 画背景
    [self getCurrenShowDataMaxAndMin];  // 获取当前显示的最大价格和最小价格
    [self drawPiceLabel];               // 左侧价格
    [self drawDateLabel];               // 下方日期
    [self drawCandleAndAvgLine];        // K线图(蜡烛图)
    
    [self drawDifferentTypeLabel];  // 成交量 MA5等label(上下两部分之间的文字)
    [self drawDifferentTypeChart];  // 成交量等不同类型的图表
    
    [self drawCrossLine];           // 十字线(长按的时候才绘制)
    [self drawMovingPriceLabel];    // 价格(长按的时候才绘制)
    [self drawMovingDateLabel];     // 日期(长按的时候才绘制)
}

#pragma mark - 画背景
- (void)initLineView
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, self.bgColor.CGColor);
    CGContextFillRect (context, self.bounds);
    [self drawLineForTopAsixX]; // K线背景横线
    [self drawLineForTopAsixY]; // K线背景竖线
    [self drawLineForBottomAsixX];  // 成交量背景横线
    [self drawLineForBottomAsixY];  // 成交量背景竖线
}

/**
 *  上半部分横线
 */
- (void)drawLineForTopAsixX
{
    CGFloat lineMargen_x = (self.bounds.size.height * self.prop - self.padding.top);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    for (int i = 0; i < 2; i ++) {
        CGContextMoveToPoint(context, self.padding.left, self.padding.top + i * lineMargen_x);
        CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.padding.top + i * lineMargen_x);
    }
    CGContextStrokePath(context);
    for (int i = 0; i < 3; i ++) {
        CGContextMoveToPoint(context, self.padding.left, self.padding.top + i * (lineMargen_x / 4) + lineMargen_x / 4);
        CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.padding.top + i * (lineMargen_x / 4) + lineMargen_x / 4);
    }
    CGContextStrokePath(context);
}

/**
 *  上半部分竖线
 */
- (void)drawLineForTopAsixY
{
    CGFloat lineMargen = (self.bounds.size.width - self.padding.left - self.padding.right) / 4;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    for (int i = 0 ; i < 2; i ++) {
        CGContextMoveToPoint(context, self.padding.left + i * lineMargen * 4, self.padding.top);
        CGContextAddLineToPoint(context, self.padding.left + i * lineMargen * 4, self.bounds.size.height * self.prop);
    }
    CGContextStrokePath(context);
}

/**
 *  下半部分横线
 */
- (void)drawLineForBottomAsixX
{
    CGFloat lineMargen = (self.bounds.size.height * (1 - self.prop) - self.upDownModeMargen - self.padding.bottom - 4 - self.defaultTextSize) / 2;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    
    CGContextMoveToPoint(context, self.padding.left, self.bounds.size.height * self.prop + self.upDownModeMargen + lineMargen);
    CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.bounds.size.height * self.prop + self.upDownModeMargen +lineMargen);
    CGContextStrokePath(context);
    for (int i = 0; i < 2; i ++) {
        CGContextMoveToPoint(context, self.padding.left, self.bounds.size.height * self.prop + self.upDownModeMargen + i * lineMargen * 2);
        CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.bounds.size.height * self.prop + self.upDownModeMargen + i * lineMargen * 2);
    }
    CGContextStrokePath(context);
}

/**
 *  下半部分竖线
 */
- (void)drawLineForBottomAsixY
{
    CGFloat lineMargen = (self.bounds.size.width - self.padding.left - self.padding.right) / 4;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    for (int i = 0 ; i < 2; i ++) {
        CGContextMoveToPoint(context, self.padding.left + i * lineMargen * 4, self.bounds.size.height * self.prop + self.upDownModeMargen);
        CGContextAddLineToPoint(context, self.padding.left + i * lineMargen * 4, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
    }
    CGContextStrokePath(context);
}

#pragma mark 画label
/**
 *  价格
 */
- (void)drawPiceLabel
{
    CGFloat margenPrice = (self.maxPrice - self.minPrice) / 4.0;
    CGFloat margen = (self.bounds.size.height * self.prop - self.padding.top) / 4.0;
    for (int i = 4; i >= 0; i --) {
        NSString *str = [NSString stringWithFormat:@"%.2f", self.minPrice + i * margenPrice];
        NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:str];
        [attributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.priceTextColor} range:NSMakeRange(0, str.length)];
        CGFloat priceLabel_y = i == 4 ? self.padding.top + ((4 - i) * margen) + 1 : self.padding.top + ((4 - i) * margen) - attributedStr.size.height - 2;
        [attributedStr drawInRect:CGRectMake(self.padding.left + 2, priceLabel_y, attributedStr.size.width, attributedStr.size.height)];
    }
}

/**
 *  日期
 */
- (void)drawDateLabel
{
    if (self.dataArray.count == 0 || self.startDrawIndex + self.countOfShowCandle > self.dataArray.count) return;
    // 开始绘制点的日期
    NSMutableAttributedString *startDateStr = [[NSMutableAttributedString alloc] initWithString:self.dataArray[self.startDrawIndex].date];
    [startDateStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.priceTextColor} range:NSMakeRange(0, startDateStr.string.length)];
    [startDateStr drawInRect:CGRectMake(self.padding.left, self.bounds.size.height - self.padding.bottom - startDateStr.size.height - 1, startDateStr.size.width, startDateStr.size.height)];
    // 结束绘制点的日期
    NSMutableAttributedString *stopDateStr = [[NSMutableAttributedString alloc] initWithString:self.dataArray[self.startDrawIndex + self.countOfShowCandle - 1].date];
    [stopDateStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.priceTextColor} range:NSMakeRange(0, stopDateStr.string.length)];
    [stopDateStr drawInRect:CGRectMake(self.bounds.size.width - self.padding.right - stopDateStr.size.width, self.bounds.size.height - self.padding.bottom - stopDateStr.size.height - 1, stopDateStr.size.width, stopDateStr.size.height)];
}

#pragma mark - 画蜡烛-价格均线
- (void)drawCandleAndAvgLine
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    if (self.dataArray.count == 0 || self.startDrawIndex + self.countOfShowCandle > self.dataArray.count) return;
    // 这两个for循环可以写成一个for循环,但是写在一个for循环里边均线会被遮挡一部分
    for (NSInteger i = self.startDrawIndex; i < self.startDrawIndex + self.countOfShowCandle; i ++) {
        YBStockChartModel *model = [self.dataArray objectAtIndex:i];
        CGFloat star_x = i == self.startDrawIndex ? self.candleWidth / 6 + self.padding.left + self.candleWidth / 2.0 : ((self.candleWidth + self.candleMargen) / 2) + (self.candleWidth + self.candleMargen) * (i - self.startDrawIndex) + self.padding.left;
        // 蜡烛四个关键点纵坐标
        CGFloat p1_y = kCalcCandlePoint_y(model.high);
        CGFloat p2_y = model.open < model.close ? kCalcCandlePoint_y(model.close) : kCalcCandlePoint_y(model.open);
        CGFloat p3_y = model.open < model.close ? kCalcCandlePoint_y(model.open) : kCalcCandlePoint_y(model.close);
        CGFloat p4_y = kCalcCandlePoint_y(model.low);
        CGPoint point1 = CGPointMake(star_x, p1_y);
        CGPoint point2 = CGPointMake(star_x, p2_y);
        CGPoint point3 = CGPointMake(star_x, p3_y);
        CGPoint point4 = CGPointMake(star_x, p4_y);
        // 涨跌幅
        YBStockState stockState = model.open <= model.close ? YBStockStateRise : YBStockStateFall;
        [self drawCandleWith:context maxStartPoint:point1 maxStopPoint:point2 minStartPoint:point3 minStopPoint:point4 stockState:stockState];
    }
    // 价格均线
    for (NSInteger i = self.startDrawIndex; i < self.startDrawIndex + self.countOfShowCandle; i ++) {
        YBStockChartModel *model = [self.dataArray objectAtIndex:i];
        CGFloat star_x = i == self.startDrawIndex ? self.candleWidth / 6 + self.padding.left + self.candleWidth / 2.0 : ((self.candleWidth + self.candleMargen) / 2) + (self.candleWidth + self.candleMargen) * (i - self.startDrawIndex) + self.padding.left;
        if (i + 1 < self.startDrawIndex + self.countOfShowCandle) {
            YBStockChartModel *nextModel = [self.dataArray objectAtIndex:i+1];
            if (i >= 4) {
                // 画五日均线
                [self drawAvgLineWith:context movePoint:CGPointMake(star_x, kCalcCandlePoint_y(model.ma5)) stopPoint:CGPointMake(star_x + self.candleWidth + self.candleMargen, kCalcCandlePoint_y(nextModel.ma5)) lineColor:self.ma5AvgLineColor];
            }
            if (i >= 9) {
                // 画十日均线
                [self drawAvgLineWith:context movePoint:CGPointMake(star_x, kCalcCandlePoint_y(model.ma10)) stopPoint:CGPointMake(star_x + self.candleWidth + self.candleMargen, kCalcCandlePoint_y(nextModel.ma10)) lineColor:self.ma10AvgLineColor];
            }
            if (i >= 19) {
                // 画二十日均线
                [self drawAvgLineWith:context movePoint:CGPointMake(star_x, kCalcCandlePoint_y(model.ma20)) stopPoint:CGPointMake(star_x + self.candleWidth + self.candleMargen, kCalcCandlePoint_y(nextModel.ma20)) lineColor:self.ma20AvgLineColor];
            }
        }
    }
    CGContextRestoreGState(context);
}

#pragma mark - 画下半部分不同类型的图表
- (void)drawDifferentTypeChart{
//    if (self.volumeChartType == YBStockChartTypeVolume) {
        [self drawChartTypeMaxAndMiddVolumeLabel];
        [self drawChartTypeVolume];
//    }
}

#pragma mark 成交量
/**
 *  图形
 */
- (void)drawChartTypeVolume
{
    if (self.dataArray.count == 0 || self.startDrawIndex + self.countOfShowCandle > self.dataArray.count) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (NSInteger i = self.startDrawIndex; i < self.startDrawIndex + self.countOfShowCandle; i ++) {
        YBStockChartModel *model = [self.dataArray objectAtIndex:i];
        CGFloat star_x = i == self.startDrawIndex ? self.candleWidth / 6 + self.padding.left + self.candleWidth / 2.0 : ((self.candleWidth + self.candleMargen) / 2) + (self.candleWidth + self.candleMargen) * (i - self.startDrawIndex) + self.padding.left;
        // 成交量纵坐标
        CGFloat volume_y = kCalcVolumePoint_y(model.volume);
        // 成交量
        if (model.open <= model.close) { // 涨幅
            [self drawVolumeWith:context starPoint:CGPointMake(star_x, volume_y) withRise:YBStockStateRise];
        }else{  // 跌幅
            [self drawVolumeWith:context starPoint:CGPointMake(star_x, volume_y) withRise:YBStockStateFall];
        }
        // 均线
        if (i + 1 < self.startDrawIndex + self.countOfShowCandle) {
            YBStockChartModel *nextModel = [self.dataArray objectAtIndex:i + 1];
            if (i >= 4) {
                // 五日成交量均线
                [self drawAvgLineWith:context movePoint:CGPointMake(star_x, kCalcVolumePoint_y(model.ma5Volume)) stopPoint:CGPointMake(star_x + self.candleWidth + self.candleMargen, kCalcVolumePoint_y(nextModel.ma5Volume)) lineColor:self.ma10AvgLineColor];
            }
            if (i >= 9) {
                // 十日成交量均线
                [self drawAvgLineWith:context movePoint:CGPointMake(star_x, kCalcVolumePoint_y(model.ma10Volume)) stopPoint:CGPointMake(star_x + self.candleWidth + self.candleMargen, kCalcVolumePoint_y(nextModel.ma10Volume)) lineColor:self.ma20AvgLineColor];
            }
        }
    }
}

/**
 *  纵坐标文字
 */
- (void)drawChartTypeMaxAndMiddVolumeLabel
{
    // 最大成交量
    NSString *maxVolumeStr = [self volumeTransformationWith:self.maxvolume];
    NSMutableAttributedString *maxVolumeAttributedStr = [[NSMutableAttributedString alloc] initWithString:maxVolumeStr];
    [maxVolumeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.priceTextColor} range:NSMakeRange(0, maxVolumeStr.length)];
    [maxVolumeAttributedStr drawInRect:CGRectMake(self.padding.left + 2, self.bounds.size.height * self.prop + self.upDownModeMargen, maxVolumeAttributedStr.size.width, maxVolumeAttributedStr.size.height)];
    // 一半成交量
    CGFloat half_y = (self.bounds.size.height * (1 - self.prop) - self.padding.bottom - self.defaultTextSize - self.upDownModeMargen - 4) / 2.0;
    NSString *middleVolumeStr = [self volumeTransformationWith:self.maxvolume / 2];
    NSMutableAttributedString *middleVolumeAttributedStr = [[NSMutableAttributedString alloc] initWithString:middleVolumeStr];
    [middleVolumeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.priceTextColor} range:NSMakeRange(0, middleVolumeStr.length)];
    [middleVolumeAttributedStr drawInRect:CGRectMake(self.padding.left + 2, self.bounds.size.height * self.prop + self.upDownModeMargen + half_y - middleVolumeAttributedStr.size.height, middleVolumeAttributedStr.size.width, middleVolumeAttributedStr.size.height)];
}

#pragma mark - 长按相关
/**
 *  画十字线
 */
- (void)drawCrossLine
{
    if (self.isLongPressMoveing == NO) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.crossLineColor.CGColor);
    CGContextMoveToPoint(context, self.touchPoint.x, self.padding.top);
    CGContextAddLineToPoint(context, self.touchPoint.x, self.bounds.size.height * self.prop);
    CGContextMoveToPoint(context, self.padding.left, self.touchPoint.y);
    CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.touchPoint.y);
    CGContextMoveToPoint(context, self.touchPoint.x, self.bounds.size.height * self.prop + self.upDownModeMargen);
    CGContextAddLineToPoint(context, self.touchPoint.x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
    CGContextStrokePath(context);
}

/**
 *  价格
 */
- (void)drawMovingPriceLabel
{
    if (self.isLongPressMoveing == NO) return;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat priceValue = (1 - ((self.touchPoint.y - self.padding.top) / ((self.bounds.size.height * self.prop - self.padding.top)))) * (self.maxPrice - self.minPrice) + self.minPrice;
    NSString *priceStr = [NSString stringWithFormat:@"%.2f", priceValue];
    NSMutableAttributedString *moveingPriceStr = [[NSMutableAttributedString alloc] initWithString:priceStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style}];
    CGFloat x = (self.touchPoint.x <= moveingPriceStr.size.width + 6 + self.padding.left &&self.touchPoint.x > 0) ? self.bounds.size.width - self.padding.right - moveingPriceStr.size.width - 6 : self.padding.left;
    CGFloat y = self.touchPoint.y - (moveingPriceStr.size.height / 2);
    y = y < self.padding.top ? self.padding.top : y;
    CGRect rect = CGRectMake(x, y, moveingPriceStr.size.width+6,moveingPriceStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:moveingPriceStr.size.height / 2.0];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [moveingPriceStr drawInRect:rect];
}

/**
 *  日期
 */
- (void)drawMovingDateLabel
{
    if (self.isLongPressMoveing == NO) return;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSMutableAttributedString *moveingDateStr = [[NSMutableAttributedString alloc] initWithString:self.dataArray[self.touchIndexOfDataArray].date attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style}];
    CGFloat x = self.touchPoint.x - moveingDateStr.size.width / 2.0 < self.padding.left ? self.padding.left : self.touchPoint.x - moveingDateStr.size.width / 2.0;
    x = x > self.bounds.size.width - self.padding.right - moveingDateStr.size.width ? self.bounds.size.width - self.padding.right - moveingDateStr.size.width - 2 : x;
    CGFloat y = self.bounds.size.height - self.padding.bottom - moveingDateStr.size.height - 1;
    CGRect rect = CGRectMake(x, y, moveingDateStr.size.width + 4, moveingDateStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:moveingDateStr.size.height / 2.0];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [moveingDateStr drawInRect:rect];
}

/**
 *  成交量
 */
- (void)drawDifferentTypeLabel
{
    NSString *volumeTypeStr = @"成交量";
//    if (self.volumeChartType == YBStockChartTypeVolume) volumeTypeStr = @"成交量";
//    if (self.volumeChartType == YBStockChartTypeMACD) volumeTypeStr = @"MACD";
//    if (self.volumeChartType == YBStockChartTypeKDJ) volumeTypeStr = @"KDJ";
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    YBStockChartModel *model = self.isLongPressMoveing ? self.dataArray[self.touchIndexOfDataArray] : self.dataArray.lastObject;
    NSString *volumeStr = [self volumeTransformationWith:model.volume];
    NSString *ma5Str = [NSString stringWithFormat:@" MA5:%@",[self volumeTransformationWith:model.ma5Volume]];
    NSString *ma10Str = [NSString stringWithFormat:@" MA10:%@",[self volumeTransformationWith:model.ma10Volume]];
    
    NSMutableAttributedString *moveingVolumeStr = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@%@", volumeStr, ma5Str, ma10Str]];
    [moveingVolumeStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor whiteColor], NSParagraphStyleAttributeName:style} range:NSMakeRange(0, volumeStr.length)];
    [moveingVolumeStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:self.ma10AvgLineColor, NSParagraphStyleAttributeName:style} range:NSMakeRange(volumeStr.length, ma5Str.length)];
    [moveingVolumeStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:self.ma20AvgLineColor, NSParagraphStyleAttributeName:style} range:NSMakeRange(volumeStr.length + ma5Str.length, ma10Str.length)];
    [self drawMovingVolumeLabelWithTypeString:volumeTypeStr volumeAttributedString:moveingVolumeStr];
}

- (void)drawMovingVolumeLabelWithTypeString:(NSString *)typeString volumeAttributedString:(NSMutableAttributedString *)volumeAttributedString
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSMutableAttributedString *moveingVolumeStr = [[NSMutableAttributedString alloc] initWithString:typeString attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0], NSForegroundColorAttributeName:[UIColor whiteColor], NSParagraphStyleAttributeName:style}];
    CGFloat x = self.padding.left;
    CGFloat y = self.bounds.size.height * self.prop + self.upDownModeMargen / 2.0 - moveingVolumeStr.size.height / 2.0;
    CGFloat w = moveingVolumeStr.size.width + 6;
    CGFloat h = moveingVolumeStr.size.height;
    CGRect rect = CGRectMake(x, y, w, h);
    CGContextSetFillColorWithColor(context, [UIColor colorWithRed:51 / 255.0 green:129 / 255.0 blue:227 / 255.0 alpha:1.0].CGColor);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3];
    CGContextAddPath(context, path.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [moveingVolumeStr drawInRect:rect];
    [volumeAttributedString drawInRect:CGRectMake(x + w + 2, self.bounds.size.height * self.prop + self.upDownModeMargen / 2.0 - volumeAttributedString.size.height / 2.0, volumeAttributedString.size.width, volumeAttributedString.size.height)];
}

#pragma mark - 画点
/**
 *  画K线点(蜡烛)
 *
 *  @param context       当前上下文
 *  @param maxStartPoint 上影线最高点
 *  @param maxStopPoint  上影线最低点
 *  @param minStartPoint 下影线最高点
 *  @param minStopPoint  下影线最低点
 *  @param stockState    涨跌幅
 */
- (void)drawCandleWith:(CGContextRef)context maxStartPoint:(CGPoint)maxStartPoint maxStopPoint:(CGPoint)maxStopPoint minStartPoint:(CGPoint)minStartPoint minStopPoint:(CGPoint)minStopPoint stockState:(YBStockState)stockState
{
    if (stockState == YBStockStateRise) {
        CGContextSetStrokeColorWithColor(context, self.candleRiseColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, maxStartPoint.x, maxStartPoint.y);
        CGContextAddLineToPoint(context, maxStopPoint.x, maxStopPoint.y);
        CGContextMoveToPoint(context, minStartPoint.x, minStartPoint.y);
        CGContextAddLineToPoint(context, minStopPoint.x, minStopPoint.y);
        CGContextStrokePath(context);
        CGContextStrokeRect(context, CGRectMake(maxStopPoint.x - self.candleWidth / 2.0, maxStopPoint.y, self.candleWidth, minStartPoint.y - maxStopPoint.y));
    }else{
        CGContextSetStrokeColorWithColor(context, self.candleFallColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextMoveToPoint(context, maxStartPoint.x, maxStartPoint.y);
        CGContextAddLineToPoint(context, minStopPoint.x, minStopPoint.y);
        CGContextStrokePath(context);
        CGContextSetFillColorWithColor(context, self.candleFallColor.CGColor);
        CGContextFillRect(context, CGRectMake(maxStartPoint.x - self.candleWidth / 2.0, maxStopPoint.y, self.candleWidth, minStartPoint.y - maxStopPoint.y));
    }
}

/**
 *  画线段
 *
 *  @param context   当前上下文
 *  @param movePoint 开始点
 *  @param stopPoint 结束点
 *  @param lineColor 线段颜色
 */
- (void)drawAvgLineWith:(CGContextRef)context movePoint:(CGPoint)movePoint stopPoint:(CGPoint)stopPoint lineColor:(UIColor *)lineColor
{
    CGContextSetStrokeColorWithColor(context, lineColor.CGColor);
    CGContextSetLineWidth(context, self.avgLineWidth);
    CGContextMoveToPoint(context, movePoint.x, movePoint.y);
    CGContextAddLineToPoint(context, stopPoint.x, stopPoint.y);
    CGContextStrokePath(context);
}

/**
 *  画矩形成交量点
 *
 *  @param context    当前上下文
 *  @param starPoint  开始点(结束点的x=开始点的x<也就是柱状横向中点>, 结束点得y是固定值)
 *  @param stockState 涨跌幅
 */
- (void)drawVolumeWith:(CGContextRef)context starPoint:(CGPoint)starPoint withRise:(YBStockState)stockState
{
    if (stockState == YBStockStateRise) {
        CGContextSetStrokeColorWithColor(context, self.candleRiseColor.CGColor);
        CGContextSetLineWidth(context, 1.0);
        CGContextStrokePath(context);
        CGContextStrokeRect(context, CGRectMake(starPoint.x - self.candleWidth / 2.0, starPoint.y, self.candleWidth, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4 - starPoint.y));
    }else{
        CGContextSetFillColorWithColor(context, self.candleFallColor.CGColor);
        CGContextFillRect(context, CGRectMake(starPoint.x - self.candleWidth / 2.0, starPoint.y, self.candleWidth, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4 - starPoint.y));
    }
}

#pragma mark - 计算最大值最小值以及单位转换等方法
/**
 *  计算 价格 成交量 的最大值最小值
 */
- (void)getCurrenShowDataMaxAndMin
{
    if (self.dataArray.count > 0) {
        self.maxPrice = self.dataArray[self.startDrawIndex].high;
        self.minPrice = self.dataArray[self.startDrawIndex].low;
        self.maxvolume = self.dataArray[self.startDrawIndex].volume;
        if (self.startDrawIndex + self.countOfShowCandle > self.dataArray.count) return;
        for (NSInteger i = self.startDrawIndex; i < self.startDrawIndex + self.countOfShowCandle; i ++) {
            YBStockChartModel *model = [self.dataArray objectAtIndex:i];
            self.maxPrice = self.maxPrice > model.high ? self.maxPrice : model.high;
            self.minPrice = self.minPrice < model.low ? self.minPrice : model.low;
            self.maxvolume = self.maxvolume > model.volume ? self.maxvolume : model.volume;
            if (model.ma5 > 0) {
                self.maxPrice = self.maxPrice > model.ma5 ? self.maxPrice : model.ma5;
                self.minPrice = self.minPrice < model.ma5 ? self.minPrice : model.ma5;
            }
            if (model.ma10 > 0) {
                self.maxPrice = self.maxPrice > model.ma10 ? self.maxPrice : model.ma10;
                self.minPrice = self.minPrice < model.ma10 ? self.minPrice : model.ma10;
            }
            if (model.ma20 > 0) {
                self.maxPrice = self.maxPrice > model.ma20 ? self.maxPrice : model.ma20;
                self.minPrice = self.minPrice < model.ma20 ? self.minPrice : model.ma20;
            }
        }
        if ((self.maxPrice - self.minPrice) < 0.3) {
            self.maxPrice += 0.5;
            self.minPrice -= 0.5;
        }
    }
}

/**
 *  成交量单位转换
 *
 *  @param volume 成交量
 *
 *  @return 单位成交量字符串
 */
- (NSString *)volumeTransformationWith:(NSInteger)volume
{
    if (volume > 100000000) {
        return [NSString stringWithFormat:@"%.1f亿", volume / 100000000.0];
    }else if(volume > 10000){
        return [NSString stringWithFormat:@"%.1f万", volume / 10000.0];
    }else{
        return [NSString stringWithFormat:@"%ld", volume];
    }
}

#pragma mark - 手势事件
// 轻拍
- (void)tapGestureRecognizerAction:(UITapGestureRecognizer *)sender
{
    CGPoint point = [sender locationInView:self];
    if (point.x > self.padding.left && (point.x < self.bounds.size.width - self.padding.right) && (point.y > self.bounds.size.height * self.prop + self.upDownModeMargen) && (point.y < self.bounds.size.height - self.padding.bottom - self.defaultTextSize)) {
//        NSLog(@"点击了成交量视图");
//        self.volumeChartType = self.volumeChartType + 1;
//        if (self.volumeChartType > 3) {
//            self.volumeChartType = 1;
//        }
        [self setNeedsDisplay];
    }
}

// 长按
- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer *)sender
{
    if (self.dataArray.count == 0 || self.dataArray == nil) return;
    CGPoint touchPoint = [sender locationInView:self];
    self.isLongPressMoveing = YES;
    if (sender.state == UIGestureRecognizerStateEnded) {
        self.isLongPressMoveing = NO;
    }
    if (touchPoint.x > self.padding.left && touchPoint.x < self.bounds.size.width - self.padding.right && touchPoint.y > self.padding.top && touchPoint.y < self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4) {
        self.touchPoint = touchPoint;
        if (_delegate && [_delegate respondsToSelector:@selector(longPressStockChartView:currentEntityModel:entityModelIndex:)]) {
            [_delegate longPressStockChartView:self currentEntityModel:self.dataArray[self.touchIndexOfDataArray] entityModelIndex:self.touchIndexOfDataArray];
        }
    }else{
        self.isLongPressMoveing = NO;
    }
    [self setNeedsDisplay];
}

// 啮合
- (void)pinGestureRecognizerAction:(UIPinchGestureRecognizer *)sender
{
    sender.scale = sender.scale - self.lastPinScale + 1;;
    sender.scale = (sender.scale > 1.5) ? sender.scale - 1 : sender.scale;
    self.candleWidth = sender.scale * self.candleWidth;
    NSInteger offset = (NSInteger)((self.lastPinCount - self.countOfShowCandle) / 2.0);
    if ((self.lastPinCount - self.countOfShowCandle) == 1)  offset = 1;
    if ((self.lastPinCount - self.countOfShowCandle) == -1) offset = -1;
    if (labs(offset)) {
        self.lastPinCount = self.countOfShowCandle;
        self.startDrawIndex = self.startDrawIndex + offset;
    }
    NSLog(@"dataCount --- %ld - startIndex ---- %ld -- offset --- %ld countShow -- %ld", self.dataArray.count, self.startDrawIndex, offset, self.countOfShowCandle);
    [self setNeedsDisplay];
    self.lastPinScale = sender.scale;
}

// 平移滑动
- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)sender
{
    CGPoint point = [sender translationInView:self];
    if (point.x > 0) {
        self.startDrawIndex -= (NSInteger)(point.x / 6.0);
    }else{
        self.startDrawIndex += (NSInteger)((-point.x) / 6.0);
    }
    [self setNeedsDisplay];
    // 手指每滑动6个像素移动一个点
    if (point.x > 6 || point.x < -6) {
        [sender setTranslation:CGPointMake(0, 0) inView:self];
    }
}

#pragma mark - setter
- (void)setDataArray:(NSMutableArray<YBStockChartModel *> *)dataArray
{
    _dataArray = dataArray;
    // 初始化要绘制的下标
    self.startDrawIndex = _dataArray.count - self.countOfShowCandle;
}

- (void)setStartDrawIndex:(NSInteger)startDrawIndex
{
    // 防止绘制的时候startDrawIndex越界
    if (startDrawIndex + self.countOfShowCandle >= self.dataArray.count) {
        startDrawIndex = self.dataArray.count - self.countOfShowCandle;
    }
    if (startDrawIndex < 0 || self.countOfShowCandle >= self.dataArray.count) {
        startDrawIndex = 0;
    }
    NSLog(@"%ld", startDrawIndex);
    _startDrawIndex = startDrawIndex;
}

- (void)setTouchPoint:(CGPoint)touchPoint
{
    NSInteger temp_x = (touchPoint.x - self.padding.left) / (self.candleWidth + self.candleMargen);
    temp_x = temp_x < 0 ? 0 : temp_x;
    temp_x = temp_x >= self.countOfShowCandle ? self.countOfShowCandle - 1 : temp_x;
    CGFloat x = ((self.candleWidth + self.candleMargen) / 2) + (self.candleWidth + self.candleMargen) * temp_x + self.padding.left;
    YBStockChartModel *model = (self.startDrawIndex + temp_x < self.dataArray.count) ? [self.dataArray objectAtIndex:self.startDrawIndex + temp_x] : self.dataArray.lastObject;
    CGFloat y = kCalcCandlePoint_y(model.close);
    _touchPoint = CGPointMake(x, y);
    self.touchIndexOfDataArray = self.startDrawIndex + temp_x;
}

- (void)setTapEnabled:(BOOL)tapEnabled
{
    _tapEnabled = tapEnabled;
    if (tapEnabled == YES) [self addGestureRecognizer:self.tap];
    else [self removeGestureRecognizer:self.tap];
}

- (void)setLongPressEnabled:(BOOL)longPressEnabled
{
    _longPressEnabled = longPressEnabled;
    if (longPressEnabled == YES) [self addGestureRecognizer:self.longPress];
    else [self removeGestureRecognizer:self.longPress];
}

- (void)setPinEnabled:(BOOL)pinEnabled
{
    _pinEnabled = pinEnabled;
    if (pinEnabled == YES) [self addGestureRecognizer:self.pin];
    else [self removeGestureRecognizer:self.pin];
}

- (void)setPanEnabled:(BOOL)panEnabled
{
    _panEnabled = panEnabled;
    if (panEnabled == YES) [self addGestureRecognizer:self.pan];
    else [self removeGestureRecognizer:self.pan];
}

#pragma mark - getter
- (UITapGestureRecognizer *)tap
{
    if (!_tap) _tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognizerAction:)];
    return _tap;
}

- (UILongPressGestureRecognizer *)longPress
{
    if (!_longPress) _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerAction:)];
    return _longPress;
}

- (UIPinchGestureRecognizer *)pin
{
    if (!_pin) _pin = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinGestureRecognizerAction:)];
    return _pin;
}

- (UIPanGestureRecognizer *)pan
{
    if (!_pan) _pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    return _pan;
}

- (NSMutableArray<YBStockChartModel *> *)dataArray
{
    if (!_dataArray) _dataArray = [NSMutableArray array];
    return _dataArray;
}

- (CGFloat)prop
{
    if (!_prop) _prop = 0.6;
    return _prop;
}

- (UIColor *)lineColor
{
    if (!_lineColor) _lineColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    return _lineColor;
}

- (CGFloat)upDownModeMargen
{
    if (!_upDownModeMargen) _upDownModeMargen = 20;
    return _upDownModeMargen;
}

- (UIColor *)bgColor
{
    if (!_bgColor) _bgColor = [UIColor blackColor];
    return _bgColor;
}

- (UIEdgeInsets)padding
{
    CGFloat top = _padding.top;
    CGFloat left = _padding.left;
    CGFloat bottom = _padding.bottom;
    CGFloat right = _padding.right;
    if (!top) top = 1;
    if (!left) left = 1;
    if (!bottom) bottom = 1;
    if (!right) right = 1;
    _padding = UIEdgeInsetsMake(top, left, bottom, right);
    return _padding;
}

- (UIColor *)longPressTextColor
{
    if (!_longPressTextColor) _longPressTextColor = [UIColor blackColor];
    return _longPressTextColor;
}

- (UIColor *)longPressLabelBgColor
{
    if (!_longPressLabelBgColor) _longPressLabelBgColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    return _longPressLabelBgColor;
}

- (UIColor *)candleRiseColor
{
    if (!_candleRiseColor) _candleRiseColor = [UIColor redColor];
    return _candleRiseColor;
}

- (UIColor *)candleFallColor
{
    if (!_candleFallColor) _candleFallColor = [UIColor colorWithRed:0/255.0 green:247/255.0 blue:247/255.0 alpha:1.0];
    return _candleFallColor;
}

- (UIColor *)priceTextColor
{
    if (!_priceTextColor) _priceTextColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    return _priceTextColor;
}

- (UIColor *)crossLineColor
{
    if (!_crossLineColor) _crossLineColor = [UIColor whiteColor];
    return _crossLineColor;
}

- (UIColor *)ma5AvgLineColor
{
    if (!_ma5AvgLineColor) _ma5AvgLineColor = [UIColor whiteColor];
    return _ma5AvgLineColor;
}

- (UIColor *)ma10AvgLineColor
{
    if (!_ma10AvgLineColor) _ma10AvgLineColor = [UIColor yellowColor];
    return _ma10AvgLineColor;
}

- (UIColor *)ma20AvgLineColor
{
    if (!_ma20AvgLineColor) _ma20AvgLineColor = [UIColor colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0];
    return _ma20AvgLineColor;
}

- (CGFloat)defaultTextSize
{
    if (!_defaultTextSize) _defaultTextSize = 10.0;
    return _defaultTextSize;
}

- (CGFloat)avgLineWidth
{
    if (!_avgLineWidth) _avgLineWidth = 1.0;
    return _avgLineWidth;
}

- (CGFloat)candleWidth
{
    if (!_candleWidth) _candleWidth = 8.0;
    if (_candleWidth < self.minCandleWidth) _candleWidth = self.minCandleWidth;
    if (_candleWidth > self.maxCandleWidth) _candleWidth = self.maxCandleWidth;
    return _candleWidth;
}

- (CGFloat)maxCandleWidth
{
    if (!_maxCandleWidth) _maxCandleWidth = 20;
    return _maxCandleWidth;
}

- (CGFloat)minCandleWidth
{
    if (!_minCandleWidth) _minCandleWidth = 1.0;
    return _minCandleWidth;
}

- (CGFloat)contentWidth
{
    return self.bounds.size.width - self.padding.left - self.padding.right;
}

- (NSInteger)countOfShowCandle
{
    _countOfShowCandle = self.contentWidth / (self.candleWidth + self.candleMargen);
    if (_countOfShowCandle > self.dataArray.count) {
        _countOfShowCandle = self.dataArray.count;
    }
    return _countOfShowCandle;
}

- (CGFloat)candleMargen
{
    return (self.candleWidth / 3.0) < 1 ? 1 : self.candleWidth / 3.0;
}

//- (YBStockChartType)volumeChartType
//{
//    if (!_volumeChartType) _volumeChartType = YBStockChartTypeVolume;
//    return _volumeChartType;
//}

@end
