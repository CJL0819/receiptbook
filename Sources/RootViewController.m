// SPDX-License-Identifier: MIT
// Copyright (c) 2026
#import "RootViewController.h"
#import "ReceiptListViewController.h"
#import "AddReceiptViewController.h"
#import "StatsViewController.h"

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UINavigationController *list = [[UINavigationController alloc]
        initWithRootViewController:[[ReceiptListViewController alloc] init]];
    list.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"收据"
                                                    image:[UIImage systemImageNamed:@"doc.text"]
                                            selectedImage:[UIImage systemImageNamed:@"doc.text.fill"]];

    UINavigationController *add = [[UINavigationController alloc]
        initWithRootViewController:[[AddReceiptViewController alloc] init]];
    add.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"扫描"
                                                   image:[UIImage systemImageNamed:@"camera.viewfinder"]
                                           selectedImage:[UIImage systemImageNamed:@"camera.viewfinder"]];

    UINavigationController *stats = [[UINavigationController alloc]
        initWithRootViewController:[[StatsViewController alloc] init]];
    stats.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"统计"
                                                     image:[UIImage systemImageNamed:@"chart.bar"]
                                             selectedImage:[UIImage systemImageNamed:@"chart.bar.fill"]];

    self.viewControllers = @[list, add, stats];
}

@end
