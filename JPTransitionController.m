//
//  JPTransitionController.m
//
//  Created by James Potter on 24/03/2013.
//  Copyright (c) 2013 Takota. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "JPTransitionController.h"

@interface JPTransitionController ()

- (void)_transitionToViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                          direction:(JPTransitionControllerDirection)direction;

- (void)processQueue;

@end

@implementation JPTransitionController

- (id)init
{
    self = [super init];
    if (self) {
        _visibleViewController = nil;
        _queue = [NSMutableArray array];
        _transitionDuration = JP_TRANSITION_CONTROLLER_DEFAULT_DURATION;
    }
    return self;
}

- (void)viewDidLayoutSubviews
{
    if (self.visibleViewController) self.visibleViewController.view.frame = self.view.bounds;
}

- (void)transitionToViewController:(UIViewController *)viewController
                          animated:(BOOL)animated
                         direction:(JPTransitionControllerDirection)direction
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        [self _transitionToViewController:viewController animated:animated direction:direction];
    }];
    
    if (!_locked) {
        [operation main];
    } else {
        [_queue addObject:operation];
    }
}

#pragma mark -
#pragma mark Private

- (void)processQueue
{
    if ([_queue count] > 0) {
        NSBlockOperation *operation = _queue[0];
        [_queue removeObjectAtIndex:0];
        [operation main];
    }
}

- (void)unlock
{
    @synchronized(self) {
        _locked = NO;
        [self processQueue];
    }
}

- (void)_transitionToViewController:(UIViewController *)viewController
                           animated:(BOOL)animated
                          direction:(JPTransitionControllerDirection)direction
{
    _locked = YES;
    
    CGFloat offset;
    CGSize screenSize = [[UIScreen mainScreen] applicationFrame].size;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsPortrait(interfaceOrientation)) {
        offset = screenSize.width;
    } else {
        offset = screenSize.height;
    }
    
    if (direction == JPTransitionControllerDirectionBack) offset = -offset;
    
    double duration = self.transitionDuration;
    if (animated == NO) duration = 0.0;
    
    // -- Shrink transition --
    
    if (animated) {
        CGAffineTransform transform = self.view.transform;
        [UIView animateWithDuration:duration/2.0 animations:^{
            self.view.transform = CGAffineTransformScale(self.view.transform, 0.95, 0.95);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:duration/2.0 animations:^{
                self.view.transform = transform;
            }];
        }];
    }
    
    // -- Slide new view controller in --
    
    if ([viewController conformsToProtocol:@protocol(JPTransitionViewController)]) {
        UIViewController<JPTransitionViewController> *vc = (UIViewController<JPTransitionViewController> *)viewController;
        vc.transitionController = self;
    }
    
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    viewController.view.frame = self.view.bounds;
    
    // Move to correct side of the screen
    UIView *view = viewController.view;
    CGRect frame = view.frame;
    frame.origin.x = offset;
    view.frame = frame;
    
    [UIView animateWithDuration:duration animations:^{
        CGRect frame = view.frame;
        frame.origin.x = 0;
        view.frame = frame;
    }];
    
    // -- Slide old view controller out and discard --
    
    if (_visibleViewController) {
        
        UIView *coverView = [[UIView alloc] initWithFrame:_visibleViewController.view.bounds];
        coverView.backgroundColor = [UIColor blackColor];
        coverView.layer.opacity = 0.0f;
        coverView.autoresizingMask = JP_AUTORESIZE_FILL;
        [_visibleViewController.view addSubview:coverView];
        
        [UIView animateWithDuration:duration animations:^{
            
            CGRect bounds = _visibleViewController.view.bounds;
            bounds.origin.x = offset;
            _visibleViewController.view.bounds = bounds;
            
            coverView.layer.opacity = 1.0f;
            
        } completion:^(BOOL finished) {
            [coverView removeFromSuperview];
            
            if ([_visibleViewController conformsToProtocol:@protocol(JPTransitionViewController)]) {
                UIViewController<JPTransitionViewController> *vc = (UIViewController<JPTransitionViewController> *)_visibleViewController;
                vc.transitionController = nil;
            }
            
            [_visibleViewController removeFromParentViewController];
            [_visibleViewController.view removeFromSuperview];
            
            _visibleViewController = viewController;
            [self unlock];
        }];
    } else {
        _visibleViewController = viewController;
        [self unlock];
    }
    
}

@end
