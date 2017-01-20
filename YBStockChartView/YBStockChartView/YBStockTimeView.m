//
//  YBStockTimeView.m
//  YBStockChartView
//
//  Created by hxcj on 16/10/20.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import "YBStockTimeView.h"

#define kCalcLinePoint_y(parameter) (1 - (parameter - self.minPrice) / (self.maxPrice - self.minPrice)) * (self.bounds.size.height * self.prop - self.padding.top) + self.padding.top

@interface YBStockTimeView ()
/** 价格最大值 **/
@property (nonatomic, assign) CGFloat maxPrice;
/** 价格最小值 **/
@property (nonatomic, assign) CGFloat minPrice;
/** 最大成交量 **/
@property (nonatomic, assign) NSInteger maxVolume;
/** 绘制图标的内容区域宽度 **/
@property (nonatomic, assign) CGFloat contentWidth;
/** 长按手势 **/
@property (nonatomic, strong) UILongPressGestureRecognizer *longPress;
/** 长按手势触摸点 **/
@property (nonatomic, assign) CGPoint touchPoint;
/** 是否长按 **/
@property (nonatomic, assign) BOOL isLongPressing;
/** 长按选中的下标 **/
@property (nonatomic, assign) NSInteger currentSelectedIndex;
@end

@implementation YBStockTimeView

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

// 添加手势
- (void)setup
{
    [self addGestureRecognizer:self.longPress];
}

- (void)handleLongPressGestureAction:(UILongPressGestureRecognizer *)sender
{
    if(self.dataArray.count == 0 || self.dataArray == nil) return;
    CGPoint point = [sender locationInView:self];
    if (point.x > self.padding.left && point.x < self.bounds.size.width - self.padding.right && point.y > self.padding.top && point.y < self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4) {
        self.isLongPressing = YES;
        if (sender.state == UIGestureRecognizerStateEnded) self.isLongPressing = NO;
        self.touchPoint = point;
    }else{
        self.isLongPressing = NO;
    }
    [self setNeedsDisplay];
    if (_delegate && [_delegate respondsToSelector:@selector(longPressStockTimeView:currentEntityModel:entityModelIndex:)]) {
        [_delegate longPressStockTimeView:self currentEntityModel:[self.dataArray objectAtIndex:self.currentSelectedIndex] entityModelIndex:self.currentSelectedIndex];
    }
}

#pragma mark - 绘制
- (void)drawRect:(CGRect)rect
{
    [self drawBackgroundView];  // 背景
    [self drawTimeTextLabel];   // 时间
    [self calcGetMaxAndMinPrice];
    [self drawPricePercentAndMaxVolumeLabel];  // 左侧价格右侧百分比和最大成交量
    [self drawBrokenLineAndVolume];      // 画线
    [self drawCrossLine];    // 画十字线
    [self drawLongPressingLabel]; // 长按显示的label
}

#pragma mark - 画背景
- (void)drawBackgroundView
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
    CGFloat lineMargen = self.contentWidth / 4;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGFloat dash[] = {1,3};
    CGContextSetLineDash(context, 0, dash, 0);
    for (int i = 0 ; i < 5; i ++) {
        if (i == 0 || i == 4) {
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
    CGFloat lineMargen = self.contentWidth / 4;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0f);
    CGContextSetStrokeColorWithColor(context, self.lineColor.CGColor);
    CGFloat dash[] = {1,3};
    for (int i = 0 ; i < 5; i ++) {
        if (i == 0 || i == 4) {
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
 *  时间
 */
- (void)drawTimeTextLabel
{
    NSMutableAttributedString *openTimeAttributedStr = [[NSMutableAttributedString alloc] initWithString:@"9:30"];
    [openTimeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor} range:NSMakeRange(0, openTimeAttributedStr.length)];
    CGRect openRect = CGRectMake(self.padding.left + 1, self.bounds.size.height - self.padding.bottom - openTimeAttributedStr.size.height - 1, openTimeAttributedStr.size.width, openTimeAttributedStr.size.height);
    [openTimeAttributedStr drawInRect:openRect];
    
    NSMutableAttributedString *middenTimeAttributedStr = [[NSMutableAttributedString alloc] initWithString:@"11:30"];
    [middenTimeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor} range:NSMakeRange(0, middenTimeAttributedStr.length)];
    CGRect middenRect = CGRectMake((self.contentWidth - middenTimeAttributedStr.size.width) / 2 + self.padding.left, self.bounds.size.height - self.padding.bottom - openTimeAttributedStr.size.height - 1, middenTimeAttributedStr.size.width, middenTimeAttributedStr.size.height);
    [middenTimeAttributedStr drawInRect:middenRect];
    
    NSMutableAttributedString *closeTimeAttributedStr = [[NSMutableAttributedString alloc] initWithString:@"15:00"];
    [closeTimeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor} range:NSMakeRange(0, closeTimeAttributedStr.length)];
    CGRect closeRect = CGRectMake(self.bounds.size.width - self.padding.right - closeTimeAttributedStr.size.width, self.bounds.size.height - self.padding.bottom - openTimeAttributedStr.size.height - 1, closeTimeAttributedStr.size.width, closeTimeAttributedStr.size.height);
    [closeTimeAttributedStr drawInRect:closeRect];
}

/**
 *  画左侧价格和右侧百分比label及最大成交量
 */
- (void)drawPricePercentAndMaxVolumeLabel
{
    CGFloat priceMargen = (self.maxPrice - self.minPrice) / 4.0;
    CGFloat lineMargen_y = (self.bounds.size.height * self.prop - self.padding.top) / 4.0;
    CGFloat yesterdayBaseClose = self.dataArray.firstObject.yesterdayClose;
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
    // 最大成交量label
    NSString *maxVolumeStr = [NSString stringWithFormat:@"%ld", self.maxVolume];
    NSMutableAttributedString *maxVolumeAttributedStr = [[NSMutableAttributedString alloc] initWithString:maxVolumeStr];
    [maxVolumeAttributedStr setAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize],NSForegroundColorAttributeName:self.lineColor} range:NSMakeRange(0, maxVolumeStr.length)];
    [maxVolumeAttributedStr drawInRect:CGRectMake(self.padding.left + 2, self.bounds.size.height * self.prop + self.upDownModeMargen, maxVolumeAttributedStr.size.width + 6, maxVolumeAttributedStr.size.height)];
}

#pragma mark - 计算获取价格最大值和最小值
- (void)calcGetMaxAndMinPrice
{
    if (self.dataArray.count > 0) {
        CGFloat yesterdayBaseClose = self.dataArray.firstObject.yesterdayClose;
        self.maxPrice = self.dataArray.firstObject.price;
        self.minPrice = self.dataArray.firstObject.price;
        self.maxVolume = self.dataArray.firstObject.volume;
        for (NSInteger i = 0; i < self.dataArray.count; i ++) {
            YBStockTimeModel *model = [self.dataArray objectAtIndex:i];
            self.maxPrice = self.maxPrice > model.price ? self.maxPrice : model.price;
            self.minPrice = self.minPrice < model.price ? self.minPrice : model.price;
            self.maxVolume = self.maxVolume > model.volume ? self.maxVolume : model.volume;
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

#pragma mark - 画折线
- (void)drawBrokenLineAndVolume
{
    if (self.dataArray.count > 0) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 1.0f);
        CGContextSetStrokeColorWithColor(context, self.priceLineColor.CGColor);
        CGFloat dash[] = {1,3};
        CGContextSetLineDash(context, 0, dash, 0);
        // 即时成交价线
        for (int i = 0; i < self.dataArray.count; i ++) {
            YBStockTimeModel *model = [self.dataArray objectAtIndex:i];
            CGFloat x = (self.contentWidth / 242.0) * i + self.padding.left;
            CGFloat y = kCalcLinePoint_y(model.price);
            if (i == 0) {
                CGContextMoveToPoint(context, x, y);
            }
            else{
                CGContextAddLineToPoint(context, x, y);
            }
        }
        CGContextStrokePath(context);
        // 均线
        CGContextSetStrokeColorWithColor(context, self.avgLineColor.CGColor);
        for (int i = 0; i < self.dataArray.count; i ++) {
            YBStockTimeModel *model = [self.dataArray objectAtIndex:i];
            CGFloat x = (self.contentWidth / 242.0) * i + self.padding.left;
            CGFloat y = kCalcLinePoint_y(model.avgPrice);
            if (i == 0) {
                CGContextMoveToPoint(context, x, y);
            }
            else{
                CGContextAddLineToPoint(context, x, y);
            }
        }
        CGContextStrokePath(context);
        // 成交量
        CGFloat lineWidth = self.contentWidth / 242.0;
        if (lineWidth > 1) lineWidth = lineWidth - 0.5;
        CGContextSetLineWidth(context, lineWidth);
        for (int i = 0; i < self.dataArray.count; i ++) {
            YBStockTimeModel *model = [self.dataArray objectAtIndex:i];
            if (i > 0) {
                YBStockTimeModel *beforeModel = [self.dataArray objectAtIndex:i - 1];
                UIColor *volumeLineColor = model.price >= beforeModel.price ? self.riseVolumnColor : self.fallVolumnColor;
                CGContextSetStrokeColorWithColor(context, volumeLineColor.CGColor);
            }else{
                UIColor *volumeLineColor = model.price >= model.yesterdayClose ? self.riseVolumnColor : self.fallVolumnColor;
                CGContextSetStrokeColorWithColor(context, volumeLineColor.CGColor);
            }
            CGFloat x = (self.contentWidth / 242.0) * i + self.padding.left + lineWidth / 2 + 0.25;
            CGFloat y = (1 - (CGFloat)model.volume / self.maxVolume) * (self.bounds.size.height * (1 - self.prop) - self.upDownModeMargen - self.defaultTextSize - 4 - self.padding.bottom - 1) + self.bounds.size.height * self.prop + self.upDownModeMargen;
            CGContextMoveToPoint(context, x, y);
            CGContextAddLineToPoint(context, x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
            CGContextStrokePath(context);
        }
    }
}

#pragma mark - 长按相关
/**
 *  十字线
 */
- (void)drawCrossLine
{
    if (self.isLongPressing == NO) return;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 1.0);
    CGContextSetStrokeColorWithColor(context, self.crossLineColor.CGColor);
    CGFloat x = (self.contentWidth / 242) * self.currentSelectedIndex + self.padding.left;
    CGContextMoveToPoint(context, x, self.padding.top);
    CGContextAddLineToPoint(context, x, self.bounds.size.height * self.prop);
    CGContextMoveToPoint(context, x, self.bounds.size.height * self.prop + self.upDownModeMargen);
    CGContextAddLineToPoint(context, x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 4);
    YBStockTimeModel *model = [self.dataArray objectAtIndex:self.currentSelectedIndex];
    CGFloat y = kCalcLinePoint_y(model.price);
    CGContextMoveToPoint(context, self.padding.left, y);
    CGContextAddLineToPoint(context, self.bounds.size.width - self.padding.right, y);
    CGContextStrokePath(context);
}

/**
 *  长按显示的label
 */
- (void)drawLongPressingLabel
{
    if (self.isLongPressing == NO) return;
    YBStockTimeModel *model = [self.dataArray objectAtIndex:self.currentSelectedIndex];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.alignment = NSTextAlignmentCenter;
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 价格
    NSString *priceStr = [NSString stringWithFormat:@"%.2f", model.price];
    NSMutableAttributedString *priceAttributedStr = [[NSMutableAttributedString alloc] initWithString:priceStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style}];
    CGFloat x = self.touchPoint.x < self.padding.left + self.contentWidth / 2.0 ? self.bounds.size.width - self.padding.right - priceAttributedStr.size.width - 6 : self.padding.left;
    CGFloat y = kCalcLinePoint_y(model.price) - priceAttributedStr.size.height / 2.0;
    y = y < self.padding.top ? self.padding.top : y;
    CGRect priceStrRect = CGRectMake(x, y, priceAttributedStr.size.width + 6, priceAttributedStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *priceStrPath = [UIBezierPath bezierPathWithRoundedRect:priceStrRect cornerRadius:priceAttributedStr.size.height / 2.0];
    CGContextAddPath(context, priceStrPath.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [priceAttributedStr drawInRect:priceStrRect];
    // 时间
    NSString *dateStr = model.time;
    NSMutableAttributedString *dateAttributedStr = [[NSMutableAttributedString alloc] initWithString:dateStr attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:self.defaultTextSize], NSForegroundColorAttributeName:self.longPressTextColor, NSParagraphStyleAttributeName:style}];
    x = (self.contentWidth / 242) * self.currentSelectedIndex + self.padding.left - dateAttributedStr.size.width / 2 - 3;
    if (x < self.padding.left) x = self.padding.left;
    if (x > self.bounds.size.width - self.padding.right - dateAttributedStr.size.width - 6) x = self.bounds.size.width - self.padding.right - dateAttributedStr.size.width - 6;
    CGRect dateStrRect = CGRectMake(x, self.bounds.size.height - self.padding.bottom - self.defaultTextSize - 1, dateAttributedStr.size.width + 6, dateAttributedStr.size.height);
    CGContextSetFillColorWithColor(context, self.longPressLabelBgColor.CGColor);
    UIBezierPath *dateStrPath = [UIBezierPath bezierPathWithRoundedRect:dateStrRect cornerRadius:dateAttributedStr.size.height / 2.0];
    CGContextAddPath(context, dateStrPath.CGPath);
    CGContextDrawPath(context, kCGPathEOFill);
    [dateAttributedStr drawInRect:dateStrRect];
}

#pragma mark - setter
- (void)setTouchPoint:(CGPoint)touchPoint
{
    if (touchPoint.x < self.padding.left) touchPoint = CGPointMake(self.padding.left, touchPoint.y);
    if (touchPoint.x > self.bounds.size.width - self.padding.right) touchPoint = CGPointMake(self.bounds.size.width - self.padding.right, touchPoint.y);
    _touchPoint = touchPoint;
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

- (NSMutableArray<YBStockTimeModel *> *)dataArray
{
    if (!_dataArray) _dataArray = [NSMutableArray array];
    return _dataArray;
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

- (NSInteger)currentSelectedIndex
{
    _currentSelectedIndex = (NSInteger)((self.touchPoint.x - self.padding.left) / (self.contentWidth / 242.0));
    if (_currentSelectedIndex < 0) _currentSelectedIndex = 0;
    if (_currentSelectedIndex > 241) _currentSelectedIndex = 241;
    if (_currentSelectedIndex >= self.dataArray.count) _currentSelectedIndex = self.dataArray.count - 1;
    return _currentSelectedIndex;
}

@end
