//
//  NSView+UIVIew.m
//  DTCoreText
//
//  Created by Sebastian Grimme on 21.02.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import "NSView+UIVIew.h"
#import <QuartzCore/QuartzCore.h>

@implementation NSView (UIVIew)

@dynamic alpha;
@dynamic opaque;
@dynamic tag;

- (void)setAlpha:(CGFloat)alpha
{
	// TODO SG ??
	self.layer.opacity = alpha;
}

- (void)setOpaque:(BOOL)opaque
{
	// TODO SG ??
	self.layer.opaque = opaque;
}

- (void)setNeedsLayout
{
	[self setNeedsLayout:YES];
}

- (void)setNeedsDisplay
{
	[self setNeedsDisplay:YES];
}

- (void)sizeToFit
{
	// TODO SG ??
	NSLog(@"TODO NSView+UIView Category, sizeToFit");
}

@end

#endif
