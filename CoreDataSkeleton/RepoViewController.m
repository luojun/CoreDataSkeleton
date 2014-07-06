//
//  DetailViewController.m
//  CoreDataSkeleton
//
//  Created by Jun Luo on 2014-07-04.
//  Copyright (c) 2014 Jun Luo. All rights reserved.
//

#import "RepoViewController.h"

@interface RepoViewController ()
            
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation RepoViewController

#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self configureView];
}

#pragma mark - managing the detail item

- (void)setDetailObject:(NSManagedObject *)detailObject {
    if (_detailObject != detailObject) {
        _detailObject = detailObject;
            
        // Update the view.
        [self configureView];
    }

    if (self.masterPopoverController != nil) {
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)configureView {
    // Update the user interface for the detail item.
    if (self.detailObject) {
        self.detailDescriptionLabel.text = [[self.detailObject valueForKey:@"userName"] description];
    }
}

#pragma mark - split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Master", @"Master");
    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    // Called when the view is shown again in the split view, invalidating the button and popover controller.
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.masterPopoverController = nil;
}

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
    return YES;
}

@end
