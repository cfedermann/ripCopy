//
//  AudioFileDescriptor.h
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AudioFileDescriptor : NSObject {
	NSString *filename;	// Filename
	NSString *checksum;	// MD5 checksum
	long filesize;		// NSFileSize
	NSDate *created;	// NSFileCreationDate
	NSDate *modified;	// NSFileModificationDate
}

- (id) initWithFilename: (NSString *)input;

@property (retain) NSString* filename;
@property (retain) NSString* checksum;
@property long filesize;
@property (retain) NSDate* created;
@property (retain) NSDate* modified;

@end
