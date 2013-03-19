//
//  AudioBackupTask.m
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import "AudioBackupTask.h"


@implementation AudioBackupTask

@synthesize filename;
@synthesize sourceFolder;
@synthesize targetFolder;
@synthesize allowedExtensions;
@synthesize hashes;

- (void) encodeWithCoder: (NSCoder*)coder
{
    [coder encodeObject: filename];
    [coder encodeObject: sourceFolder];
    [coder encodeObject: targetFolder];
    [coder encodeObject: allowedExtensions];
    [coder encodeObject: hashes];
}

- (id) initWithCoder: (NSCoder*)coder
{
	if (self=[super init]) {
		[self setFilename: [coder decodeObject]];
		[self setSourceFolder: [coder decodeObject]];
		[self setTargetFolder: [coder decodeObject]];
		[self setAllowedExtensions: [coder decodeObject]];
		[self setHashes: [coder decodeObject]];
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
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
		NSString *desktopDirectory = [paths objectAtIndex:0];
		paths = NSSearchPathForDirectoriesInDomains(NSMusicDirectory, NSUserDomainMask, YES);
		NSString *musicDirectory = [paths objectAtIndex:0];
		
		[self setFilename:nil];
        [self setSourceFolder:musicDirectory];
        [self setTargetFolder:desktopDirectory];
		[self setAllowedExtensions:nil];
		hashes = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void) dealloc
{
	[filename release];
	[sourceFolder release];
    [targetFolder release];
    [allowedExtensions release];
	[hashes release];
    [super dealloc];
}


@end
