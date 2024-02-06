//
//  ViewController.m
//  FlexHotReload
//
//  Created by 周兴 on 2024/2/6.
//

#import "ViewController.h"
#import "FlexTestViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"FlexHotReload";
    [self.view addSubview:self.button];
}

- (void)openFlexVC {
    FlexTestViewController *vc = [[FlexTestViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - Get
- (UIButton *)button {
    if (!_button) {
        _button = [UIButton buttonWithType:UIButtonTypeCustom];
        _button.backgroundColor = [UIColor orangeColor];
        _button.frame = CGRectMake((UIScreen.mainScreen.bounds.size.width - 150)/2.0, 200, 150, 50);
        [_button setTitle:@"跳转flex页面" forState:UIControlStateNormal];
        [_button addTarget:self action:@selector(openFlexVC) forControlEvents:UIControlEventTouchUpInside];
    }
    return _button;
}

@end
