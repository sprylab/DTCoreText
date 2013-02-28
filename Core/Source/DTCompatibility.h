//
//  DTCompatibility.h
//  DTCoreText
//
//  Created by Oliver Letterer on 09.04.12.
//  Copyright (c) 2012 Drobnik.com. All rights reserved.
//

// DTImage is UIImage on iOS, NSImage on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTView UIView;
#else
@compatibility_alias DTView NSView;
#endif

// DTColor is UIColor on iOS, NSColor on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTColor UIColor;
#else
@compatibility_alias DTColor NSColor;
#endif

// DTImage is UIImage on iOS, NSImage on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTImage UIImage;
#else
@compatibility_alias DTImage NSImage;
#endif

// DTFont is UIFont on iOS, NSFont on Mac
#if TARGET_OS_IPHONE
@compatibility_alias DTFont UIFont;
#else
@compatibility_alias DTFont NSFont;
#endif

// DTEdgeInsets is UIEdgeInsets on iOS, NSEdgeInsets on Mac
#if TARGET_OS_IPHONE
#define DTEdgeInsets UIEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) UIEdgeInsetsMake(a, b, c, d)
#define DTEdgeInsetsInsetRect(a, b) UIEdgeInsetsInsetRect(a, b)
#define DTEdgeInsetsEqualToEdgeInsets(a, b) UIEdgeInsetsEqualToEdgeInsets(a, b)
#else
#define DTEdgeInsets NSEdgeInsets
#define DTEdgeInsetsMake(a, b, c, d) NSEdgeInsetsMake(a, b, c, d)

// These may be out of place here. Feel free to move them!
// Sourced from https://github.com/andrep/RMModelObject
static inline NSString* NSStringFromCGRect(const CGRect rect)
{
	return NSStringFromRect(NSRectFromCGRect(rect));
}

static inline NSString* NSStringFromCGSize(const CGSize size)
{
	return NSStringFromSize(NSSizeFromCGSize(size));
}

static inline NSString* NSStringFromCGPoint(const CGPoint point)
{
	return NSStringFromPoint(NSPointFromCGPoint(point));
}

static inline CGRect DTEdgeInsetsInsetRect(CGRect rect, DTEdgeInsets insets) {
    rect.origin.x    += insets.left;
    rect.origin.y    += insets.top;
    rect.size.width  -= (insets.left + insets.right);
    rect.size.height -= (insets.top  + insets.bottom);
    return rect;
}

static inline BOOL DTEdgeInsetsEqualToEdgeInsets(DTEdgeInsets insets1, DTEdgeInsets insets2) {
    return insets1.left == insets2.left && insets1.top == insets2.top && insets1.right == insets2.right && insets1.bottom == insets2.bottom;
}

#define NSTextAlignmentLeft			NSLeftTextAlignment
#define NSTextAlignmentRight		NSRightTextAlignment
#define NSTextAlignmentCenter		NSCenterTextAlignment
#define NSTextAlignmentJustified	NSJustifiedTextAlignment
#define NSTextAlignmentNatural		NSNaturalTextAlignment

#endif
