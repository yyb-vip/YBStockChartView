//
//  YBStockFiveDayView.m
//  YBStockChartView
//
//  Created by YYB on 16/10/23.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import "YBStockFiveDayView.h"
// 转换坐标
#define kCalcLinePoint_y(parameter) (1 - (parameter - self.minPrice) / (self.maxPrice - self.minPrice)) * (self.bounds.size.height * self.prop - self.padding.top) + self.padding.top

@interface YBStockFiveDayView ()
/** 绘制图标的内容区域宽度 **/
@property (nonatomic, assign) CGFloat contentWidth;
/** 最大价格 **/
@property (nonatomic, assign) CGFloat maxPrice;
/** 最小价格 **/
@property (nonatomic, assign) CGFloat minPrice;
/** 最大成交量 **/
@property (nonatomic, assign) NSInteger maxVolume;
/** 是否长按 **/
@property (nonatomic, assign) BOOL isLongPressing;
/** 两个点之间的间隔 **/
@property (nonatomic, assign) CGFloat pointMargen;

/** 长按手势 **/
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
/** 手指触摸点 **/
@property (nonatomic, assign) CGPoint touchPoint;

/** 触摸点在数组中的下标 **/
@property (nonatomic, assign) NSInteger section;
/** 触摸点在数组中的数组中的下标 **/
@property (nonatomic, assign) NSInteger index;

@end

@implementation YBStockFiveDayView

#pragma mark - 初始化view
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
    [self addGestureRecognizer:self.longPress];
}

#pragma mark - 绘制
- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    [self drawBackground];  // 背景
    [self calcGetMaxAndMinPrice];   // 获取最大最小值
    [self drawPriceAndPercentTextLabel];    // 画价格label和百分比
    [self drawDateTimeLabel];   // 日期时间
    [self drawBrokenLineAndVolume]; // 折线
    [self drawCrossLine];   // 十字线
    [self drawPriceAndTimeLabel]; // 价格-时间
}


#pragma mark - 画背景
- (void)drawBackground
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
    CGFloat lineMargen_x = self.bounds.size.height * self.prop - self.padding.top;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGFloat dash[] = {1,3};
    CGContextSetLineDash(context, 0, dash, 0);
    for (int i = 0; i < 2; i ++) {
        CGContextMoveToPoint(context, self.padding.left, self.padding.top + i * lineMargen_x);
        CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.padding.top + i * lineMargen_x);
    }
    CGContextStrokePath(context);
    for (int i = 0; i < 3; i ++) {
        if (i == 1) {
            CGContextSetLineDash(context, 0, dash, 0);
        }else {
            CGContextSetLineDash(context, 0, dash, 2);
        }
        CGContextMoveToPoint(context, self.padding.left, self.padding.top + i * (lineMargen_x / 4) + lineMargen_x / 4);
        CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.padding.top + i * (lineMargen_x / 4) + lineMargen_x / 4);
        CGContextStrokePath(context);
    }
}

/**
 *  上半部分竖线
 */
- (void)drawLineForTopAsixY
{
    CGFloat lineMargen = self.contentWidth / 5;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGFloat dash[] = {1,3};
    CGContextSetLineDash(context, 0, dash, 0);
    for (int i = 0 ; i < 6; i ++) {
        if (i == 0 || i == 5) {
            CGContextSetLineDash(context, 0, dash, 0);
        }else{
            CGContextSetLineDash(context, 0, dash, 2);
        }
        CGContextMoveToPoint(context, self.padding.left + i * lineMargen, self.padding.top);
        CGContextAddLineToPoint(context, self.padding.left + i * lineMargen, self.bounds.size.height * self.prop);
        CGContextStrokePath(context);
    }
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
    CGFloat dash[] = {1,3};
    CGContextSetLineDash(context, 0, dash, 2);
    CGContextMoveToPoint(context, self.padding.left, self.bounds.size.height * self.prop + self.upDownModeMargen + lineMargen);
    CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.bounds.size.height * self.prop + self.upDownModeMargen +lineMargen);
    CGContextStrokePath(context);
    CGContextSetLineDash(context, 0, dash, 0);
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
    CGFloat lineMargen = self.contentWidth / 5;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGFloat dash[] = {1,3};
    for (int i = 0 ; i < 6; i ++) {
        if (i == 0 || i == 5) {
            CGContextSetLineDash(context, 0, dash, 0);
        }else{
            CGContextSetLineDash(context, 0, dash, 2);
        }
        CGContextMoveToPoint(context, self.padding.left + i * lineMargen, self.bounds.size.height * self.prop + self.upDownModeMargen);
        CGContextAddLineToPoint(context, self.padding.left + i * lineMargen, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
        CGContextStrokePath(context);
    }
}

#pragma mark - 画label
/**
 *  画日期时间
 */
- (void)drawDateTimeLabel
{
    CGFloat lineMargen = self.contentWidth / 5;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    for (int i = 0; i < self.dataArray.count; i ++) {
        NSString *dateStr = self.dataArray[i].firstObject.date;
        NSMutableAttributedString *dateAttributedStr = [[NSMutableAttributedString alloc] initWithString:dateStr];
        [dateAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor, NSParagraphStyleAttributeName:style} range:NSMakeRange(0, dateAttributedStr.length)];
        CGRect dateRect = CGRectMake(self.padding.left + i * lineMargen, self.bounds.size.height - self.padding.bottom - dateAttributedStr.size.height - 1, lineMargen, dateAttributedStr.size.height);
        [dateAttributedStr drawInRect:dateRect];
    }
}

/**
 *  画左侧价格和右侧百分比label以及最大成交量label
 */
- (void)drawPriceAndPercentTextLabel
{
    CGFloat priceMargen = (self.maxPrice - self.minPrice) / 4.0;
    CGFloat lineMargen_y = (self.bounds.size.height * self.prop - self.padding.top) / 4.0;
    CGFloat yesterdayBaseClose = self.dataArray.firstObject.firstObject.yesterdayClose;
    for (int i = 4; i >= 0; i --) {
        UIColor *textColor = self.lineColor;
        if (i == 4 || i == 3) textColor = [UIColor redColor];
        if (i == 1 || i == 0) textColor = [UIColor greenColor];
        // 左侧价格
        NSString *priceStr = [NSString stringWithFormat:@"%.2f", self.minPrice + i * priceMargen];
        NSMutableAttributedString *priceAttributedStr = [[NSMutableAttributedString alloc] initWithString:priceStr];
        [priceAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:textColor} range:NSMakeRange(0, priceStr.length)];
        CGFloat y = self.padding.top + (4 - i) * lineMargen_y;
        if (i != 4) y = y - priceAttributedStr.size.height / 2.0;
        if (i == 0) y = y - priceAttributedStr.size.height / 2.0;
        [priceAttributedStr drawInRect:CGRectMake(self.padding.left + 2, y, priceAttributedStr.size.width, priceAttributedStr.size.height)];
        // 右侧百分比
        NSString *percentStr = [NSString stringWithFormat:@"%.2f%%", ((self.minPrice + i * priceMargen - yesterdayBaseClose) / yesterdayBaseClose) * 100];
        percentStr = yesterdayBaseClose == 0 ? @"0.00%" : percentStr;
        NSMutableAttributedString *percentAttributedStr = [[NSMutableAttributedString alloc] initWithString:percentStr];
        [percentAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:textColor} range:NSMakeRange(0, percentStr.length)];
        [percentAttributedStr drawInRect:CGRectMake(self.bounds.size.width - self.padding.right - percentAttributedStr.size.width - 1, y, percentAttributedStr.size.width, percentAttributedStr.size.height)];
    }
    
    NSString *maxVolumeStr = [NSString stringWithFormat:@"%ld", self.maxVolume];
    NSMutableAttributedString *maxVolumeAttributedStr = [[NSMutableAttributedString alloc] initWithString:maxVolumeStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor}];
    [maxVolumeAttributedStr drawInRect:CGRectMake(self.padding.left + 2, self.bounds.size.height * self.prop + self.upDownModeMargen, maxVolumeAttributedStr.size.width, maxVolumeAttributedStr.size.height)];
}

#pragma mark - 画折线
- (void)drawBrokenLineAndVolume
{
    if (self.dataArray.count > 0) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGFloat dash[] = {1,3};
        CGContextSetLineDash(context, 0, dash, 0);
        NSInteger k = 0;
        if (self.dataArray.count == 1) k = 4;
        if (self.dataArray.count == 2) k = 3;
        if (self.dataArray.count == 3) k = 2;
        if (self.dataArray.count == 4) k = 1;
        for (int i = 0; i < self.dataArray.count; i ++) {
            NSArray *dayArray = self.dataArray[i];
            if (dayArray.count > 0) {
                CGContextSetLineWidth(context, 1.0f);
                // 均线
                CGContextSetStrokeColorWithColor(context, [UIColor yellowColor].CGColor);
                for (int j = 0; j < dayArray.count; j ++) {
                    YBStockFiveDayModel *model = dayArray[j];
                    CGFloat x = self.padding.left + (k * 242 + j) * self.pointMargen;
                    CGFloat y = kCalcLinePoint_y(model.avgPrice);
                    if (j == 0) {
                        CGContextMoveToPoint(context, x, y);
                    }else{
                        CGContextAddLineToPoint(context, x, y);
                    }
                }
                CGContextStrokePath(context);
                // 价格
                CGContextSetStrokeColorWithColor(context, self.priceLineColor.CGColor);
                for (int j = 0; j < dayArray.count; j ++) {
                    YBStockFiveDayModel *model = dayArray[j];
                    CGFloat x = self.padding.left + (k * 242 + j) * self.pointMargen;
                    CGFloat y = kCalcLinePoint_y(model.price);
                    if (j == 0) {
                        CGContextMoveToPoint(context, x, y);
                    }else{
                        CGContextAddLineToPoint(context, x, y);
                    }
                }
                CGContextStrokePath(context);
                // 成交量
                CGContextSetLineWidth(context, self.pointMargen);
                for (int j = 0; j < dayArray.count; j ++) {
                    YBStockFiveDayModel *model = dayArray[j];
                    if (j > 0) {
                        YBStockFiveDayModel *beforeModel = [self.dataArray[i] objectAtIndex:j - 1];
                        UIColor *volumeLineColor = model.price >= beforeModel.price ? self.riseVolumnColor : self.fallVolumnColor;
                        CGContextSetStrokeColorWithColor(context, volumeLineColor.CGColor);
                    }else{
                        UIColor *volumeLineColor = model.price >= model.yesterdayClose ? self.riseVolumnColor : self.fallVolumnColor;
                        CGContextSetStrokeColorWithColor(context, volumeLineColor.CGColor);
                    }
                    CGFloat x = self.padding.left + (k * 242 + j) * self.pointMargen;
                    CGFloat y = (1 - (CGFloat)model.volume / self.maxVolume) * (self.bounds.size.height * (1 - self.prop) - self.upDownModeMargen - self.defaultTextSize - 4 - self.padding.bottom - 1) + self.bounds.size.height * self.prop + self.upDownModeMargen;
                    CGContextMoveToPoint(context, x, y);
                    CGContextAddLineToPoint(context, x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
                    CGContextStrokePath(context);
                }
                k = k + 1;;
            }
        }
    }
}

#pragma mark - 长按相关
- (void)drawCrossLine
{
    if (self.isLongPressing == NO) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.crossLineColor.CGColor);
    CGContextMoveToPoint(context, self.padding.left, self.touchPoint.y);
    CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, self.touchPoint.y);
    CGContextMoveToPoint(context, self.touchPoint.x, self.padding.top);
    CGContextAddLineToPoint(context, self.touchPoint.x, self.bounds.size.height * self.prop);
    CGContextMoveToPoint(context, self.touchPoint.x, self.bounds.size.height * self.prop + self.upDownModeMargen);
    CGContextAddLineToPoint(context, self.touchPoint.x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
    CGContextStrokePath(context);
}

/**
 *  画价格时间label
 */
- (void)drawPriceAndTimeLabel
{
    if (self.isLongPressing == NO) return;
    YBStockFiveDayModel *model = self.dataArray[self.section][self.index];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 价格
    NSString *priceStr = [NSString stringWithFormat:@"%.2f", model.price];
    NSMutableAttributedString *priceAttrinbutedStr = [[NSMutableAttributedString alloc] initWithString:priceStr];
    [priceAttrinbutedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style} range:NSMakeRange(0, priceStr.length)];
    CGFloat x = self.touchPoint.x < self.padding.left + self.contentWidth / 2.0 ? self.bounds.size.width - self.padding.right - priceAttrinbutedStr.size.width - 6 : self.padding.left;
    CGFloat y = self.touchPoint.y - priceAttrinbutedStr.size.height / 2.0;
    y = y < self.padding.top ? self.padding.top : y;
    CGRect priceStrRect = CGRectMake(x, y, priceAttrinbutedStr.size.width + 6, priceAttrinbutedStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *priceStrPath = [UIBezierPath bezierPathWithRoundedRect:priceStrRect cornerRadius:priceAttrinbutedStr.size.height / 2.0];
    CGContextAddPath(context, priceStrPath.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [priceAttrinbutedStr drawInRect:priceStrRect];
    // 时间
    NSMutableAttributedString *timeAttributedStr = [[NSMutableAttributedString alloc] initWithString:model.time];
    [timeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style} range:NSMakeRange(0, timeAttributedStr.length)];
    x = self.touchPoint.x - 3 - timeAttributedStr.size.width / 2.0;
    x = x < self.padding.left ? self.padding.left : x;
    x = x > self.bounds.size.width -  self.padding.right - timeAttributedStr.size.width - 6 ? self.bounds.size.width -  self.padding.right - timeAttributedStr.size.width - 6 : x;
    y = self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 1;
    CGRect timeRect = CGRectMake(x, y, timeAttributedStr.size.width + 6, timeAttributedStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *timeStrPath = [UIBezierPath bezierPathWithRoundedRect:timeRect cornerRadius:timeAttributedStr.size.height / 2.0];
    CGContextAddPath(context, timeStrPath.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [timeAttributedStr drawInRect:timeRect];
}

#pragma mark - 计算获取价格最大值和最小值
- (void)calcGetMaxAndMinPrice
{
    if (self.dataArray.count > 0) {
        CGFloat yesterdayBaseClose = self.dataArray.firstObject.firstObject.yesterdayClose;
        self.maxPrice = self.minPrice = self.dataArray.firstObject.firstObject.price;
        self.maxVolume = self.dataArray.firstObject.firstObject.volume;
        for (int i = 0;  i < self.dataArray.count; i ++) {
            for (int j = 0; j < self.dataArray[i].count; j ++) {
                YBStockFiveDayModel *model = self.dataArray[i][j];
                self.maxPrice = self.maxPrice > model.price ? self.maxPrice : model.price;
                self.minPrice = self.minPrice < model.price ? self.minPrice : model.price;
                self.maxVolume = self.maxVolume > model.volume ? self.maxVolume : model.volume;
            }
        }
        CGFloat a = self.maxPrice - yesterdayBaseClose;
        CGFloat b = yesterdayBaseClose - self.minPrice;
        if (a > b) {
            self.minPrice = yesterdayBaseClose - a;
        } else if (a < b) {
            self.maxPrice = yesterdayBaseClose + b;
        } else {
            self.maxPrice = a == 0 ? yesterdayBaseClose * 1.1 : yesterdayBaseClose + a;
            self.minPrice = a == 0 ? yesterdayBaseClose * 0.9 : yesterdayBaseClose - a;
        }
    }
}

#pragma mark - 长按手势事件
- (void)handleLongPressGestureAction:(UILongPressGestureRecognizer *)sender
{
    if (self.dataArray.count == 0) return;
    CGPoint point = [sender locationInView:self];
    if (point.x > self.padding.left && point.x < self.bounds.size.width - self.padding.right && point.y > self.padding.top && point.y < self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4) {
        self.isLongPressing = YES;
        if (sender.state == UIGestureRecognizerStateEnded) self.isLongPressing = NO;
        self.touchPoint = point;
        self.section = (NSInteger)((self.touchPoint.x - self.padding.left) / self.pointMargen) / 242;
        self.index = (NSInteger)((self.touchPoint.x - self.padding.left) / self.pointMargen) % 242;
        if (self.index > self.dataArray[self.section].count - 1) {
            self.index = self.dataArray[self.section].count - 1;
        }
    }else{
        self.isLongPressing = NO;
    }
    [self setNeedsDisplay];
    if (_delegate && [_delegate respondsToSelector:@selector(longPressStockFiveDayView:currentEntityModel:entityModelIndexPath:)]) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.index inSection:self.section];
        [_delegate longPressStockFiveDayView:self currentEntityModel:self.dataArray[self.section][self.index] entityModelIndexPath:indexPath];
    }
}

#pragma mark - setter
- (void)setTouchPoint:(CGPoint)touchPoint
{
    YBStockFiveDayModel *model = self.dataArray[self.section][self.index];
    CGFloat x = touchPoint.x;
    CGFloat y = kCalcLinePoint_y(model.price);
    if (self.dataArray.count != 5 && x < self.padding.left + (self.contentWidth / 5.0) * (5 - self.dataArray.count)) {
        x = self.padding.left + (self.contentWidth / 5.0) * (5 - self.dataArray.count);
        y = kCalcLinePoint_y(self.dataArray[self.section].firstObject.price);
    }
    _touchPoint = CGPointMake(x, y);
}

- (void)setSection:(NSInteger)section
{
    if (self.dataArray.count != 5) {
        section = section - (5 - self.dataArray.count);
        if (self.touchPoint.x <= self.padding.left + (self.contentWidth / 5.0) * (5 - self.dataArray.count)) {
            section = 0;
        }
    }
    _section = section;
}

- (void)setLongPressEnabled:(BOOL)longPressEnabled
{
    _longPressEnabled = longPressEnabled;
    if (longPressEnabled == YES) [self addGestureRecognizer:self.longPress];
    else [self removeGestureRecognizer:self.longPress];
}

#pragma mark - getter
- (UILongPressGestureRecognizer *)longPress
{
    if (!_longPress) _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressGestureAction:)];
    return _longPress;
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

- (CGFloat)prop
{
    if (!_prop) _prop = 0.7;
    return _prop;
}

- (CGFloat)upDownModeMargen
{
    if (!_upDownModeMargen) _upDownModeMargen = 0.0;
    return _upDownModeMargen;
}

- (CGFloat)defaultTextSize
{
    if (!_defaultTextSize) _defaultTextSize = 10.0;
    return _defaultTextSize;
}

- (UIColor *)lineColor
{
    if (!_lineColor) _lineColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    return _lineColor;
}

- (UIColor *)bgColor
{
    if (!_bgColor) _bgColor = [UIColor blackColor];
    return _bgColor;
}

- (UIColor *)riseVolumnColor
{
    if (!_riseVolumnColor) _riseVolumnColor = [UIColor redColor];
    return _riseVolumnColor;
}

- (UIColor *)fallVolumnColor
{
    if (!_fallVolumnColor) _fallVolumnColor = [UIColor greenColor];
    return _fallVolumnColor;
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

- (UIColor *)priceLineColor
{
    if (!_priceLineColor) _priceLineColor = [UIColor whiteColor];
    return _priceLineColor;
}

- (UIColor *)avgLineColor
{
    if (!_avgLineColor) _avgLineColor = [UIColor yellowColor];
    return _avgLineColor;
}

- (UIColor *)crossLineColor
{
    if (!_crossLineColor) _crossLineColor = [UIColor whiteColor];
    return _crossLineColor;
}

- (CGFloat)contentWidth
{
    if (!_contentWidth) {
        _contentWidth = self.bounds.size.width - self.padding.left - self.padding.right;
    }
    return _contentWidth;
}

- (CGFloat)pointMargen
{
    return self.contentWidth / (242 * 5.0);
}

@end
