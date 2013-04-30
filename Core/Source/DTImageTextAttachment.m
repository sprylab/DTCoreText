//
//  DTTextAttachmentImage.m
//  DTCoreText
//
//  Created by Oliver Drobnik on 22.04.13.
//  Copyright (c) 2013 Drobnik.com. All rights reserved.
//

#import "DTCoreText.h"

#import "DTBase64Coding.h"

static NSCache *imageCache = nil;

@interface DTImageTextAttachment () // private stuff

+ (NSCache *)sharedImageCache;

@end


@implementation DTImageTextAttachment
{
	DTImage *_image;
}

- (id)initWithElement:(DTHTMLElement *)element options:(NSDictionary *)options
{
	self = [super initWithElement:element options:options];
	
	if (self)
	{
		// get base URL
		NSURL *baseURL = [options objectForKey:NSBaseURLDocumentOption];
		NSString *src = [element.attributes objectForKey:@"src"];
		
		[self _decodeImageSrc:src relativeToBaseURL:baseURL];
	}
	
	return self;
}

- (id)initWithImage:(DTImage *)image
{
	self = [super init];
	
	if (self)
	{
		self.image = image;
	}
	
	return self;
}


- (void)_decodeImageSrc:(NSString *)src relativeToBaseURL:(NSURL *)baseURL
{
	NSURL *contentURL = nil;
	
	// decode content URL
	if ([src length]) // guard against img with no src
	{
		if ([src hasPrefix:@"data:"])
		{
			NSString *cleanStr = [[src componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
			
			NSURL *dataURL = [NSURL URLWithString:cleanStr];
			
			// try native decoding first
			NSData *decodedData = [NSData dataWithContentsOfURL:dataURL];
			
			// try own base64 decoding
			if (!decodedData)
			{
				NSRange range = [cleanStr rangeOfString:@"base64,"];
				
				if (range.length)
				{
					NSString *encodedData = [cleanStr substringFromIndex:range.location + range.length];
					
					decodedData = [DTBase64Coding dataByDecodingString:encodedData];
				}
			}
			
			// if we have image data, get the default display size
			if (decodedData)
			{
				self.image = [[DTImage alloc] initWithData:decodedData];
				_contentURL = nil;
			}
		}
		else // normal URL
		{
			contentURL = [NSURL URLWithString:src];
			
			if(!contentURL)
			{
				src = [src stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
				contentURL = [NSURL URLWithString:src relativeToURL:baseURL];
			}
			
			if (![contentURL scheme])
			{
				// possibly a relative url
				if (baseURL)
				{
					contentURL = [NSURL URLWithString:src relativeToURL:baseURL];
				}
				else
				{
					// file in app bundle
					NSBundle *bundle = [NSBundle mainBundle];
					NSString *path = [bundle pathForResource:src ofType:nil];
					
					if (path)
					{
						// Prevent a crash if path turns up nil.
						contentURL = [NSURL fileURLWithPath:path];
					}
					else
					{
						// might also be in a different bundle, e.g. when unit testing
						bundle = [NSBundle bundleForClass:[DTTextAttachment class]];
						
						path = [bundle pathForResource:src ofType:nil];
						if (path)
						{
							// Prevent a crash if path turns up nil.
							contentURL = [NSURL fileURLWithPath:path];
						}
					}
				}
			}
		}
	}
	
	// if it's a local file we need to inspect it to get it's dimensions
	if (!_displaySize.width || !_displaySize.height)
	{
		DTImage *image = _image;
		
		// let's check if we have a cached image already then we can inspect that
		if (!_image)
		{
			image = [[DTImageTextAttachment sharedImageCache] objectForKey:[contentURL absoluteString]];
		}
		
		if (!image)
		{
			// only local files we can directly load without punishment
			if ([contentURL isFileURL])
			{
				image = [[DTImage alloc] initWithContentsOfFile:[contentURL path]];
			}
			
			// cache that for later
			if (image)
			{
				[[DTImageTextAttachment sharedImageCache] setObject:image forKey:[contentURL absoluteString]];
			}
		}
		
		// we have an image, so we can set the original size and default display size
		if (image)
		{
			_contentURL = nil;
			[self _updateSizesFromImage:image];
		}
	}
	
	// only remote images should have a URL
	_contentURL = contentURL;
}

- (void)_updateSizesFromImage:(DTImage *)image
{
	_originalSize = image.size;
	
	// initial display size matches original
	if (!_displaySize.width || !_displaySize.height)
	{
		_displaySize = _originalSize;
	}
	
	if (!CGSizeEqualToSize(_maxImageSize, CGSizeZero))
	{
		// adjust the display size if there is a restriction and it's too large
		if (_maxImageSize.width < _displaySize.width || _maxImageSize.height < _displaySize.height)
		{
			_displaySize = sizeThatFitsKeepingAspectRatio(_displaySize, _maxImageSize);
		}
	}
}

+ (NSCache *)sharedImageCache {
	if (imageCache) return imageCache;
	
	static dispatch_once_t onceToken; // lock
	dispatch_once(&onceToken, ^{ // this block run only once
		imageCache = [[NSCache alloc] init];
	});
	return imageCache;
}

#pragma mark - Alternative Representations

// makes a data URL of the image
- (NSString *)dataURLRepresentation
{
	DTImage *image = self.image;
	
	if (!image)
	{
		return nil;
	}
	
	NSData *data = [image dataForPNGRepresentation];
	NSString *encoded = [DTBase64Coding stringByEncodingData:data];
	
	return [@"data:image/png;base64," stringByAppendingString:encoded];
}

#pragma mark - DTTextAttachmentDrawing

- (void)drawInRect:(CGRect)rect context:(CGContextRef)context
{
#if TARGET_OS_IPHONE
		CGContextDrawImage(context, rect, self.image.CGImage);
#else
		CGContextDrawImage(context, rect, [self.image CGImageForProposedRect:&rect context:(__bridge NSGraphicsContext *)(context) hints:nil]);
#endif
}

#pragma mark - DTTextAttachmentHTMLEncoding

- (NSString *)stringByEncodingAsHTML
{
	NSMutableString *retString = [NSMutableString string];
	NSString *urlString;
	
	if (_contentURL)
	{
		
		if ([_contentURL isFileURL])
		{
			NSString *path = [_contentURL path];
			
			NSRange range = [path rangeOfString:@".app/"];
			
			if (range.length)
			{
				urlString = [path substringFromIndex:NSMaxRange(range)];
			}
			else
			{
				urlString = [_contentURL absoluteString];
			}
		}
		else
		{
			urlString = [_contentURL relativeString];
		}
	}
	else
	{
		urlString = [self dataURLRepresentation];
	}
	
	// output tag start
	[retString appendString:@"<img"];
	
	// build style for img/video
	NSMutableString *styleString = [NSMutableString string];
	
	switch (_verticalAlignment)
	{
		case DTTextAttachmentVerticalAlignmentBaseline:
		{
			//				[classStyleString appendString:@"vertical-align:baseline;"];
			break;
		}
		case DTTextAttachmentVerticalAlignmentTop:
		{
			[styleString appendString:@"vertical-align:text-top;"];
			break;
		}
		case DTTextAttachmentVerticalAlignmentCenter:
		{
			[styleString appendString:@"vertical-align:middle;"];
			break;
		}
		case DTTextAttachmentVerticalAlignmentBottom:
		{
			[styleString appendString:@"vertical-align:text-bottom;"];
			break;
		}
	}
	
	if (_originalSize.width>0)
	{
		[styleString appendFormat:@"width:%.0fpx;", _originalSize.width];
	}
	
	if (_originalSize.height>0)
	{
		[styleString appendFormat:@"height:%.0fpx;", _originalSize.height];
	}
	
	// add local style for size, since sizes might vary quite a bit
	if ([styleString length])
	{
		[retString appendFormat:@" style=\"%@\"", styleString];
	}
	
	[retString appendFormat:@" src=\"%@\"", urlString];
	
	// attach the attributes dictionary
	NSMutableDictionary *tmpAttributes = [_attributes mutableCopy];
	
	// remove src,style, width and height we already have these
	[tmpAttributes removeObjectForKey:@"src"];
	[tmpAttributes removeObjectForKey:@"style"];
	[tmpAttributes removeObjectForKey:@"width"];
	[tmpAttributes removeObjectForKey:@"height"];
	
	for (__strong NSString *oneKey in [tmpAttributes allKeys])
	{
		oneKey = [oneKey stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSString *value = [[tmpAttributes objectForKey:oneKey] stringByAddingHTMLEntities];
		[retString appendFormat:@" %@=\"%@\"", oneKey, value];
	}
	
	// end
	[retString appendString:@" />"];
	
	return retString;
}

#pragma mark - Properties

/**
 Accessor for the contents instance variable. If the content type is DTTextAttachmentTypeImage this returns a DTImage instance of the contents.
 @returns Contents. If it is an image, a DTImage instance is returned. Otherwise it is returned as is.
 */
- (DTImage *)image
{
	if (!_image)
	{
		if (_contentURL)
		{
			DTImage *image = [[DTImageTextAttachment sharedImageCache] objectForKey:[_contentURL absoluteString]];
			
			// only local files can be loaded into cache
			if (!image && [_contentURL isFileURL])
			{
				image = [[DTImage alloc] initWithContentsOfFile:[_contentURL path]];
				
				// cache it
				if (image)
				{
					[[DTImageTextAttachment sharedImageCache] setObject:image forKey:[_contentURL absoluteString]];
				}
			}
			
			return image;
		}
	}
	
	return _image;
}

- (void)setImage:(DTImage *)image
{
	if (_image != image)
	{
		_image = image;
		
		[self _updateSizesFromImage:_image];
	}
}

- (void)setDisplaySize:(CGSize)displaySize
{
	_displaySize = displaySize;
}

@end