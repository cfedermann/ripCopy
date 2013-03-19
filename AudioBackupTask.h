//
//  AudioBackupTask.h
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AudioBackupTask : NSObject {
	NSString *filename;
	NSString *sourceFolder;
	NSString *targetFolder;
	NSString *allowedExtensions;
	NSMutableDictionary *hashes;
}

@property (retain) NSString *filename;
@property (retain) NSString *sourceFolder;
@property (retain) NSString *targetFolder;
@property (retain) NSString *allowedExtensions;
@property (retain) NSMutableDictionary *hashes;

@end
