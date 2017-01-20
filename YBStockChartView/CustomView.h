//
//  CustomView.h
//  YBStockChartView
//
//  Created by YYB on 16/11/6.
//  Copyright © 2016年 YYB. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomView : UIView


@property (weak, nonatomic) IBOutlet UILabel *priceLabel;

@property (weak, nonatomic) IBOutlet UILabel *openLabel;

@property (weak, nonatomic) IBOutlet UILabel *closeLabel;

@property (weak, nonatomic) IBOutlet UILabel *volumeLabel;

@end
