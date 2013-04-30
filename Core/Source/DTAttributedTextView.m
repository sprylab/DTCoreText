//
//  DTAttributedTextView.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 1/12/11.
//  Copyright 2011 Drobnik.com. All rights reserved.
//

#import "DTAttributedTextView.h"
#import "DTCoreText.h"
#import <QuartzCore/QuartzCore.h>

@interface DTAttributedTextView () {
	
#if !TARGET_OS_IPHONE
	NSRect _originalFrame;
#endif
}

- (void)_setup;

@end



@implementation DTAttributedTextView
{
	DTView *_backgroundView;

	// these are pass-through, i.e. store until the content view is created
	__unsafe_unretained id textDelegate;
	NSAttributedString *_attributedString;
	
	BOOL _shouldDrawLinks;
	BOOL _shouldDrawImages;
}

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	
	if (self)
	{
		[self _setup];
	}
	
	return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}
/*
#if !TARGET_OS_IPHONE
- (void)viewWillMoveToSuperview:(NSView*)newSuperview
{
    [self _setFlippedFrameWithSuperview:newSuperview];
}

- (void)_setFlippedFrameWithSuperview:(NSView*)superView
{
    NSPoint o1 = _originalFrame.origin;
    NSSize s1 = _originalFrame.size;
    
    if (nil == superView )
    {
        self.frame = _originalFrame;
    }
    else
    {
        NSSize s0 = superView.frame.size;
        
        self.frame = NSMakeRect(o1.x, s0.height - o1.y - s1.height, s1.width, s1.height);
    }
}
#endif
*/
#if TARGET_OS_IPHONE
- (void)layoutSubviews
{
	[super layoutSubviews];
	
	[self attributedTextContentView];
	
	// layout custom subviews for visible area
	[_attributedTextContentView layoutSubviewsInRect:self.bounds];
}
#else
- (void)layout
{
	[super layout];
	
	[self attributedTextContentView];
	
	// layout custom subviews for visible area
	[_attributedTextContentView layoutSubviewsInRect:self.bounds];
}
#endif

- (void)awakeFromNib
{
	[self _setup];
}

// default
- (void)_setup
{
#if !TARGET_OS_IPHONE
	_originalFrame = self.frame;
//	self.wantsLayer = YES;
	self.drawsBackground = NO;
#endif
	
	self.autoresizesSubviews = NO;
	
#if TARGET_OS_IPHONE
	self.clipsToBounds = YES;
#else
	self.attributedTextContentView;
	// TODO SG nothing
#endif
	
	// defaults
	_shouldDrawLinks = YES;
	_shouldDrawImages = YES;
}

// override class e.g. for mutable content view
- (Class)classForContentView
{
	return [DTAttributedTextContentView class];
}

#pragma mark External Methods
- (void)scrollToAnchorNamed:(NSString *)anchorName animated:(BOOL)animated
{
	NSRange range = [self.attributedTextContentView.attributedString rangeOfAnchorNamed:anchorName];
	
	if (range.length != NSNotFound)
	{
		[self scrollRangeToVisible:range animated:animated];
	}
}

- (void)scrollRangeToVisible:(NSRange)range animated:(BOOL)animated
{
	// get the line of the first index of the anchor range
	DTCoreTextLayoutLine *line = [self.attributedTextContentView.layoutFrame lineContainingIndex:range.location];

#if TARGET_OS_IPHONE
	// make sure we don't scroll too far
	CGFloat maxScrollPos = self.contentSize.height - self.bounds.size.height + self.contentInset.bottom + self.contentInset.top;
	CGFloat scrollPos = MIN(line.frame.origin.y, maxScrollPos);

	// scroll
	[self setContentOffset:CGPointMake(0, scrollPos) animated:animated];
#else
	// TODO SG
#endif
}

- (void)relayoutText
{
	// need to reset the layouter because otherwise we get the old framesetter or cached layout frames
	_attributedTextContentView.layouter=nil;
	
	// here we're layouting the entire string, might be more efficient to only relayout the paragraphs that contain these attachments
	[_attributedTextContentView relayoutText];
	
	// layout custom subviews for visible area
	[self setNeedsLayout];
}

#pragma mark Notifications
- (void)contentViewDidLayout:(NSNotification *)notification
{
	if (![NSThread mainThread])
	{
		[self performSelectorOnMainThread:@selector(contentViewDidLayout:) withObject:notification waitUntilDone:YES];
		return;
	}
	
	NSDictionary *userInfo = [notification userInfo];

#if TARGET_OS_IPHONE
	CGRect optimalFrame = [[userInfo objectForKey:@"OptimalFrame"] CGRectValue];
	CGRect frame = DTEdgeInsetsInsetRect(self.bounds, self.contentInset);
#else
	CGRect optimalFrame = [[userInfo objectForKey:@"OptimalFrame"] rectValue];
	CGRect frame = self.bounds;
#endif

	// ignore possibly delayed layout notification for a different width
	if (optimalFrame.size.width == frame.size.width)
	{
		_attributedTextContentView.frame = optimalFrame;
		
#if TARGET_OS_IPHONE
		self.contentSize = [_attributedTextContentView intrinsicContentSize];
#else
		CGSize contentSize = [_attributedTextContentView intrinsicContentSize];
		[self.documentView setFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)];
#endif
	}
}

#pragma mark Properties
- (DTAttributedTextContentView *)attributedTextContentView
{
	if (!_attributedTextContentView)
	{
		// subclasses can specify a DTAttributedTextContentView subclass instead
		Class classToUse = [self classForContentView];
		
		CGRect frame = CGRectZero;
		
#if TARGET_OS_IPHONE
		frame = DTEdgeInsetsInsetRect(self.bounds, self.contentInset);
#else
		// TODO SG ?? no insets
		NSEdgeInsets contentInset = NSEdgeInsetsMake(0, 0, 0, 0);
		frame = DTEdgeInsetsInsetRect(self.bounds, contentInset);
#endif

		if (frame.size.width<=0 || frame.size.height<=0)
		{
			frame = CGRectZero;
		}
		
		_attributedTextContentView = [[classToUse alloc] initWithFrame:frame];
		
#if TARGET_OS_IPHONE
		_attributedTextContentView.userInteractionEnabled = YES;
#endif
		
		_attributedTextContentView.backgroundColor = self.backgroundColor;
		_attributedTextContentView.shouldLayoutCustomSubviews = NO; // we call layout when scrolling

		// set text delegate if it was set before instantiation of content view
		_attributedTextContentView.delegate = textDelegate;
		
		// pass on setting
		_attributedTextContentView.shouldDrawLinks = _shouldDrawLinks;
		
		// notification that tells us about the actual size of the content view
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(contentViewDidLayout:) name:DTAttributedTextContentViewDidFinishLayoutNotification object:_attributedTextContentView];

		// temporary frame to specify the width
		_attributedTextContentView.frame = frame;
		
		// set text we previously got, this also triggers a relayout
		_attributedTextContentView.attributedString = _attributedString;

		// this causes a relayout and the resulting notification will allow us to set the final frame
		
#if TARGET_OS_IPHONE
		[self addSubview:_attributedTextContentView];
#else
		self.documentView = _attributedTextContentView;
#endif
	}
	
	return _attributedTextContentView;
}
/*
- (void)setBackgroundColor:(DTColor *)newColor
{
	if ([newColor alphaComponent]<1.0)
	{
		super.backgroundColor = newColor;
		_attributedTextContentView.backgroundColor = [DTColor clearColor];
		self.opaque = NO;
	}
	else 
	{
		super.backgroundColor = newColor;

		if (_attributedTextContentView.opaque)
		{
			_attributedTextContentView.backgroundColor = newColor;
		}
	}
}
*/

#if TARGET_OS_IPHONE
- (void)setContentInset:(DTEdgeInsets)contentInset
{
	if (!DTEdgeInsetsEqualToEdgeInsets(self.contentInset, contentInset))
	{
		[super setContentInset:contentInset];
		
		// height does not matter, that will be determined anyhow
		CGRect contentFrame = CGRectMake(0, 0, self.frame.size.width - self.contentInset.left - self.contentInset.right, _attributedTextContentView.frame.size.height);
		
		_attributedTextContentView.frame = contentFrame;
	}
}
#endif

- (DTView *)backgroundView
{
	if (!_backgroundView)
	{
		_backgroundView = [[DTView alloc] initWithFrame:self.bounds];
		
#if TARGET_OS_IPHONE
		_backgroundView.backgroundColor	= [DTColor whiteColor];
#else
		// TODO SG color
#endif

#if TARGET_OS_IPHONE
		// default is no interaction because background should have no interaction
		_backgroundView.userInteractionEnabled = NO;
#endif

#if TARGET_OS_IPHONE
		[self insertSubview:_backgroundView belowSubview:self.attributedTextContentView];
#else
		// TODO SG ??
		[self addSubview:_backgroundView positioned:NSWindowBelow relativeTo:self.attributedTextContentView];
#endif
		
		// make content transparent so that we see the background
		_attributedTextContentView.backgroundColor = [DTColor clearColor];
		_attributedTextContentView.opaque = NO;
	}
	
	return _backgroundView;
}

- (void)setBackgroundView:(DTView *)backgroundView
{
	if (_backgroundView != backgroundView)
	{
		[_backgroundView removeFromSuperview];
		_backgroundView = backgroundView;

		if (_attributedTextContentView)
		{
#if TARGET_OS_IPHONE
			[self insertSubview:_backgroundView belowSubview:_attributedTextContentView];
#else
			// TODO SG ??
			[self addSubview:_backgroundView positioned:NSWindowBelow relativeTo:_attributedTextContentView];
#endif
		}
		else
		{
			[self addSubview:_backgroundView];
		}
		
		if (_backgroundView)
		{
			// make content transparent so that we see the background
			_attributedTextContentView.backgroundColor = [DTColor clearColor];
			_attributedTextContentView.opaque = NO;
		}
		else
		{
			_attributedTextContentView.backgroundColor = [DTColor whiteColor];
			_attributedTextContentView.opaque = YES;
		}
	}
}

- (void)setAttributedString:(NSAttributedString *)string
{
	_attributedString = string;

	// might need layout for visible custom views
	[self setNeedsLayout];
	
	if (_attributedTextContentView)
	{
		// pass it along if contentView already exists
		_attributedTextContentView.attributedString = string;
		
		// this causes a relayout and the resulting notification will allow us to set the frame and contentSize
	}
}

- (NSAttributedString *)attributedString
{
	return _attributedString;
}

- (void)setFrame:(CGRect)frame
{
	CGRect oldFrame = self.frame;
	
	if (!CGRectEqualToRect(oldFrame, frame))
	{
		[super setFrame:frame]; // need to set own frame first because layout completion needs this updated frame
		
		if (oldFrame.size.width != frame.size.width)
		{
#if TARGET_OS_IPHONE
			// height does not matter, that will be determined anyhow
			CGRect contentFrame = CGRectMake(0, 0, frame.size.width - self.contentInset.left - self.contentInset.right, _attributedTextContentView.frame.size.height);
			
			_attributedTextContentView.frame = contentFrame;
#else
			// TODO SG ??
			CGRect contentFrame = CGRectMake(0, 0, frame.size.width, 0);
			_attributedTextContentView.frame = contentFrame;
#endif
		}
	}
}

- (void)setTextDelegate:(id<DTAttributedTextContentViewDelegate>)aTextDelegate
{
	// store unsafe pointer to delegate because we might not have a contentView yet
	textDelegate = aTextDelegate;
	
	// set it if possible, otherwise it will be set in contentView lazy property
	_attributedTextContentView.delegate = aTextDelegate;
}

- (id<DTAttributedTextContentViewDelegate>)textDelegate
{
	return _attributedTextContentView.delegate;
}

- (void)setShouldDrawLinks:(BOOL)shouldDrawLinks
{
	_shouldDrawLinks = shouldDrawLinks;
	_attributedTextContentView.shouldDrawLinks = _shouldDrawLinks;
}

- (void)setShouldDrawImages:(BOOL)shouldDrawImages
{
	_shouldDrawImages = shouldDrawImages;
	_attributedTextContentView.shouldDrawImages = _shouldDrawImages;
}

@synthesize attributedTextContentView = _attributedTextContentView;
@synthesize attributedString = _attributedString;
@synthesize textDelegate = _textDelegate;

@synthesize shouldDrawLinks = _shouldDrawLinks;

@end
