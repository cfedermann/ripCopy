//
//  AudioFileDescriptor.m
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import "AudioFileDescriptor.h"

@implementation AudioFileDescriptor

@synthesize filename;
@synthesize checksum;
@synthesize filesize;
@synthesize created;
@synthesize modified;

- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: filename];
    [coder encodeObject: checksum];
    [coder encodeValueOfObjCType: @encode(long) at:&filesize];
	[coder encodeObject: created];
    [coder encodeObject: modified];
}

- (id) initWithCoder: (NSCoder*)coder
{
	if (self=[super init]) {
		[self setFilename: [coder decodeObject]];
		[self setChecksum: [coder decodeObject]];
		[coder decodeValueOfObjCType:@encode(long) at: &filesize];
		[self setCreated: [coder decodeObject]];
		[self setModified: [coder decodeObject]];
	}
	
	return self;
}

- (id) initWithFilename: (NSString*)input
{
	[self init];
	[self setFilename:input];
	return self;
}

- (id) init
{
    if (self = [super init])
    {
		[self setFilename:nil];
        [self setChecksum:nil];
        [self setFilesize:0];
		[self setCreated:nil];
		[self setModified:nil];
    }
    return self;
}

- (void) dealloc
{
	[filename release];
	[checksum release];
    [created release];
    [modified release];
    [super dealloc];
}

@end
