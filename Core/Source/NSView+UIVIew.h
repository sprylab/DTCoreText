//
//  NSView+UIVIew.h
//  DTCoreText
//
//  Created by Sebastian Grimme on 21.02.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>

@interface NSView (UIVIew) {

}

@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) BOOL opaque;
@property (nonatomic, assign) NSInteger tag;

- (void)setNeedsLayout;
- (void)setNeedsDisplay;
- (void)sizeToFit;

@end
#endif