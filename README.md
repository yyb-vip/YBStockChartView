# YBStockChartView

### 注: 因为用的是新浪的接口, 在每天09:30之前demo会因为对新浪的数据处理不合理会crash

### 初始化K线图, 分时图和五日视图初始化方式差不多
```
// 初始化K线图:
self.stockChartView = [[YBStockChartView alloc] initWithFrame:CGRectMake(0, 150, [UIScreen mainScreen].bounds.size.width, 300)];
// 上下模块比例
self.stockChartView.prop = 0.7;
// 设置代理
self.stockChartView.delegate = self;
// 内边距
self.stockChartView.padding = UIEdgeInsetsMake(10, 10, 0, 10);
[self.view addSubview:self.stockChartView];

// modelArray存放的是YBStockChartModel对象的模型数组
self.stockChartView.dataArray = modelArray; // 赋值
[self.stockChartView setNeedsDisplay];  //  刷新界面

```



## 效果图

![效果图.gif](https://github.com/YangYiBo23/YBStockChartView/blob/master/%E6%95%88%E6%9E%9C%E5%9B%BE.gif)
