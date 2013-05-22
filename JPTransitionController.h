//
//  JPTransitionController.h
//
//  Created by James Potter on 24/03/2013.
//  Copyright (c) 2013 Takota. All rights reserved.
//

#import <UIKit/UIKit.h>

#define JP_TRANSITION_CONTROLLER_DEFAULT_DURATION 0.65
#define JP_AUTORESIZE_FILL UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

typedef enum {
    JPTransitionControllerDirectionForward,
    JPTransitionControllerDirectionBack
} JPTransitionControllerDirection;

@class JPTransitionController;

/*
 All view controllers transitioned to should conform to this protocol. This ensures they have a pointer
 back to the instance of JPTransitionController managing them, so that they can transition to other view controllers.
*/
@protocol JPTransitionViewController <NSObject>

@property (nonatomic, weak) JPTransitionController *transitionController;

@end


@interface JPTransitionController : UIViewController {
@private
    BOOL _locked; // YES when a transition animation is currently in progress
    NSMutableArray *_queue;
}

// Previous view controller is discarded after the transition completes
- (void)transitionToViewController:(UIViewController *)viewController
                          animated:(BOOL)animated
                         direction:(JPTransitionControllerDirection)direction;

@property (nonatomic, strong) UIViewController *visibleViewController;

@property (nonatomic, assign) CGFloat transitionDuration; // defaults to JP_TRANSITION_CONTROLLER_DEFAULT_DURATION

@end
