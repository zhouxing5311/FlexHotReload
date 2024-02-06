//
//  FlexTestViewController.m
//  FlexHotReload
//
//  Created by 周兴 on 2024/2/6.
//

#import "FlexTestViewController.h"
#import "FlexTestView.h"

@interface FlexTestViewController ()

@property (nonatomic, strong) FlexTestView *testView;

@end

@implementation FlexTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testView = ({
        FlexTestView *testView = [[FlexTestView alloc] initWithFrame:CGRectMake(50, 200, UIScreen.mainScreen.bounds.size.width - 100, 100)];
        testView;
    });
    [self.view addSubview:self.testView];
}

@end
