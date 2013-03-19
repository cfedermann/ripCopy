//
//  cocoa_fooAppDelegate.m
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import "ripCopyAppDelegate.h"
#import "ripCopyWindowDelegate.h"
#import "AudioFileDescriptor.h"
#import "AudioBackupTask.h"


/*
 * BEGIN CODE FRAGMENTS FOR HASHING, ETC.
 */
 
#import <CommonCrypto/CommonDigest.h>

@interface NSTextView (Logging)
- (void) error:(NSString *)msg;
- (void) log:(NSString *)msg;
- (void) log:(NSString *)msg lineBreak:(BOOL)lineBreak;
- (void) log:(NSString *)msg lineBreak:(BOOL)lineBreak truncateLine:(BOOL)truncateLine;
- (void) logArray:(NSArray *)msgs;
@end

@implementation NSTextView (Logging)

- (void) error:(NSString *)msg
{
	[self log:msg lineBreak:YES truncateLine:NO];
}

- (void) log:(NSString *)msg
{
	[self log:msg lineBreak:YES truncateLine:YES];
}

- (void) log:(NSString *)msg lineBreak:(BOOL)lineBreak
{
	[self log:msg lineBreak:lineBreak truncateLine:YES];
}

- (void) log:(NSString *)msg lineBreak:(BOOL)lineBreak truncateLine:(BOOL)truncateLine
{
	if ([msg length] > MAX_LINE_LENGTH) {
		NSString *subMsg = [msg substringToIndex:MAX_LINE_LENGTH-2];
		if (lineBreak) {
			msg = [NSString stringWithFormat:@"%@...\n", subMsg];
		}
		else {
			msg = [NSString stringWithFormat:@"%@...", subMsg];
		}
	}
	
	NSFont *font = [NSFont fontWithName:@"Monaco" size:10];
	NSColor *color = [NSColor grayColor];
	NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:font,
								NSFontAttributeName, color,
								NSForegroundColorAttributeName, nil];
	
	NSAttributedString *amsg = [[NSAttributedString alloc]
								initWithString:msg attributes:attributes];
	
	[self scrollRangeToVisible: NSMakeRange([[self string] length], 0)];
	[[self textStorage] beginEditing];
	[[self textStorage] appendAttributedString:amsg];
	[[self textStorage] endEditing];
	[self didChangeText];
	[amsg release];
}

- (void) logArray:(NSArray *)msgs
{
	for (NSString *msg in msgs) {
		[self log:msg];
	}
}

@end

@interface NSData (Hash)
- (NSString*) md5Hash;
@end

@implementation NSData (Hash)

- (NSString*) md5Hash
{
	unsigned char hashcode[16];
	CC_MD5((const char*)[self bytes], [self length], hashcode);
	return [[NSData dataWithBytes:hashcode length:16] description];
	//	return [result stringByReplacingOccurrencesOfString:@" " withString:@""];
}

@end

/*
NSData* md5(const char *c_str, int len) {
	unsigned char hashcode[16];
	CC_MD5(c_str, len, hashcode);
	return [NSData dataWithBytes:hashcode length:16];
}
 */
/*
 * END CODE FRAGMENTS FOR HASHING, ETC.
 */

@implementation ripCopyAppDelegate

@synthesize window;
@synthesize processingThread;
@synthesize shouldTerminate;
@synthesize task;
@synthesize windowDelegate;

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
	if ([item action] == @selector(newBackupTask:) && [window isVisible]) {
        return NO;
    }
	
    return YES;
}

- (BOOL) application:(NSApplication *)theApplication openFile:(NSString *)filename
{
	NSLog(@"filename: %@", filename);
	if (!filename) {
		return NO;
	}
	@try {
		[self loadBackupTaskFromFile:filename];
	}
	@catch (NSException * e) {
		NSLog(@"ERROR: %@", e);
		[task release];
		task = [[AudioBackupTask alloc] init];
		return NO;
	}
	@finally {
		[window makeKeyAndOrderFront:self];
		return YES;		
	}
}

- (void) applicationWillFinishLaunching:(NSNotification *)notification
{
	task = [[AudioBackupTask alloc] init];

	windowDelegate = [[ripCopyWindowDelegate alloc] initWithAppDelegate:self];
	[window setDelegate:windowDelegate];
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification
{
	//NSArray *args = [[NSProcessInfo processInfo] arguments];

	if ([task filename]) {
		[window setTitle:[[task filename] lastPathComponent]];
	}
	else {
		[window setTitle:@"Untitled task"];
	}			
	
	[sourceFolder setURL:[NSURL fileURLWithPath:[task sourceFolder]]];
	[targetFolder setURL:[NSURL fileURLWithPath:[task targetFolder]]];
	[allowedExtensions setStringValue:@"m4a"];
	
	[task setAllowedExtensions:[allowedExtensions stringValue]];
	
	[window makeKeyAndOrderFront:self];
	[startButton setKeyEquivalent:@"\r"];
	[startButton setKeyEquivalentModifierMask:NSCommandKeyMask];
}

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender
{
	NSLog(@"visible: %d, edited: %d, running: %d", [window isVisible], [self isEdited], [self isRunning]);
	
	if ([self isEdited] || [self isRunning]) {
		[self setShouldTerminate:YES];
		[window performClose:self];
		return NSTerminateLater;
	}

	if ([task filename]) {
		NSLog(@"Auto-saving %@", [task filename]);
		[self saveBackupTaskToFile:[task filename]];
	}
	
	return NSTerminateNow;
}

- (IBAction) checkAllowedExtensions: sender
{
	if ([[allowedExtensions stringValue] isEqualToString:@""]) {
		if ([startButton isEnabled]) {
			[startButton setEnabled:NO];
			[startButton setNeedsDisplay:YES];
		}
	}
	else if (![startButton isEnabled]) {
		[startButton setEnabled:YES];
		[startButton setNeedsDisplay:YES];
	}
}

- (IBAction) newBackupTask:(id)sender
{
	// Do not open a new window if there is still one open.
	if ([window isVisible]) {
		NSLog(@"ERROR: This should NEVER happen!");
		NSBeep();
		return;
	}
	
	NSLog(@"Creating new backup task...");
	[task release];
	task = [[AudioBackupTask alloc] init];
	
	[window makeKeyAndOrderFront:self];
	
	if ([task filename]) {
		[window setTitle:[[task filename] lastPathComponent]];
	}
	else {
		[window setTitle:@"Untitled task"];
	}
	
	[sourceFolder setURL:[NSURL fileURLWithPath:[task sourceFolder]]];
	[targetFolder setURL:[NSURL fileURLWithPath:[task targetFolder]]];
	[allowedExtensions setStringValue:@"m4a"];

	[task setAllowedExtensions:[allowedExtensions stringValue]];
	[startButton setEnabled:YES];
}

- (IBAction) loadBackupTask: sender
{
	NSLog(@"Loading existing backup task...");
	BOOL windowWasVisible = [window isVisible];
	
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setResolvesAliases:YES];
	[openPanel setAllowsMultipleSelection:NO];
	
	[openPanel setDirectory:NSHomeDirectory()];
	[openPanel setAllowedFileTypes:[NSArray arrayWithObjects:@"ripCopy", nil]];
		
	[openPanel beginSheetModalForWindow:window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  NSURL *filename = [[openPanel URLs] lastObject];
							  [self loadBackupTaskFromFile:[filename path]];
						  }
						  else {
							  [window setIsVisible:windowWasVisible];
						  }

					  }];
}

- (IBAction) saveBackupTask:(id)sender
{
	if ((sender == menuSaveAs) || (![task filename])) {
		NSLog(@"SAVE_AS");
		[self saveBackupTaskAndCloseWindow:NO];
	}
	else {
		NSLog(@"SAVE_DIRECTLY: %@", [task filename]);
		[self saveBackupTaskToFile:[task filename]];
	}
}

- (IBAction) startBackupProcess: sender
{
	[startButton setEnabled:NO];
	[startButton displayIfNeeded];
	
/*
	if ([[sourceFolder URL] path] != [task sourceFolder]) {
		[[task hashes] removeAllObjects];		
	}
 */
	
	SEL callback = @selector(performBackup:);
	NSThread *backupThread = [[NSThread alloc] initWithTarget:self
													 selector:callback
													   object:[task hashes]];
	
	[backupThread autorelease];
	
	NSLog(@"Performing backup for folder: %@", [sourceFolder URL]);
	[self setProcessingThread:backupThread];
	[backupThread start];
}

- (IBAction) stopBackupProcess: sender
{
	if ([[self processingThread] isExecuting]) {
		[[self processingThread] cancel];
		[self setProcessingThread:nil];
	}
}

- (IBAction) saveLogfile: sender
{
	NSLog(@"WOULD NOW SAVE LOGFILE");
}

- (BOOL) isEdited
{
	BOOL A = ![[[sourceFolder URL] path] isEqualToString:[task sourceFolder]];
	BOOL B = ![[[targetFolder URL] path] isEqualToString:[task targetFolder]];
	BOOL C = [allowedExtensions stringValue] != [task allowedExtensions];
	
	return A || B || C;
}

- (BOOL) isRunning
{
	if ([[self processingThread] isExecuting]) {
		return YES;
	}

	[self setProcessingThread:nil];
	return NO;
}

- (void) windowShouldClose:(NSWindow *)sheet
				returnCode:(int)returnCode
			   contextInfo:(void *)contextInfo
{
	if (returnCode == NSAlertDefaultReturn) {
		NSLog(@"Yes selected -- invoking save method, NOT closing window");
		
		if (![task filename]) {
			NSLog(@"NO_MESSAGE_SAVE_AS");
			[self saveBackupTaskAndCloseWindow:YES];
		}
		else {
			NSLog(@"NO_MESSAGE_SAVE_DIRECTLY: %@", [task filename]);
			[self saveBackupTaskToFile:[task filename] closeWindow:YES];
		}
	}
	else if (returnCode == NSAlertOtherReturn) {
		NSLog(@"No selected -- not saving document, just closing window.");		
		[window orderOut:self];
		//CHECK		[task release];
		
		if ([[self processingThread] isExecuting]) {
			[[self processingThread] cancel];
			[self setProcessingThread:nil];
		}		
		
		if ([self shouldTerminate]) {
			[NSApp replyToApplicationShouldTerminate:YES];
		}
	}
	else if (returnCode == NSAlertAlternateReturn) {
		NSLog(@"Cancelled -- NOT saving, NOT closing window.");
		if ([self shouldTerminate]) {
			[NSApp replyToApplicationShouldTerminate:NO];
			[self setShouldTerminate:NO];
		}
	}
	else {
		NSLog(@"NSAlertErrorReturn");
	}
}

- (void) saveBackupTaskAndCloseWindow:(BOOL)closeWindow
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSString *nameField;
	NSString *directory;
	
	if ([task filename]) {
		nameField = [[task filename] lastPathComponent];
		directory = [[task filename] stringByDeletingLastPathComponent];
	}
	else {
		nameField = @"Untitled Backup";
		directory = NSHomeDirectory();
	}
	
	[savePanel setNameFieldStringValue:nameField];
	[savePanel setDirectory:directory];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setRequiredFileType:@"ripCopy"];
	
	[savePanel beginSheetModalForWindow:window
					  completionHandler:^(NSInteger result) {
						  if (result == NSFileHandlingPanelOKButton) {
							  [self saveBackupTaskToFile:[savePanel filename]
											 closeWindow:closeWindow];
						  }
						  else {
							  if (closeWindow) {
								  if ([[self processingThread] isExecuting]) {
									  [[self processingThread] cancel];
									  [self setProcessingThread:nil];
								  }
								  
								  [window orderOut:self];
							  }
							  
							  if ([self shouldTerminate]) {
								  [NSApp replyToApplicationShouldTerminate:YES];
							  }
						  }
					  }];
}

- (void) saveBackupTaskToFile:(NSString *)filename
{
	NSLog(@"closeWindow:NO");
	[self saveBackupTaskToFile:filename closeWindow:NO];
}

- (void) saveBackupTaskToFile:(NSString *)filename closeWindow:(BOOL)closeWindow
{
	[task setFilename:filename];
	[task setSourceFolder:[[sourceFolder URL] path]];
	[task setTargetFolder:[[targetFolder URL] path]];
	[task setAllowedExtensions:[allowedExtensions stringValue]];
	BOOL success = [NSKeyedArchiver archiveRootObject:task toFile:filename];
	
	if (!success) {
		// DISPLAY WARNING MESSAGE/RETRY?! THINGY HERE...
		NSLog(@"Could not save backup task?!?");
		[self setShouldTerminate:NO];
		return;
	}
	else {
		[window setTitle:[[task filename] lastPathComponent]];
	}
	
	if (closeWindow) {
		if ([[self processingThread] isExecuting]) {
			[[self processingThread] cancel];
			
			NSLog(@"SHOULD WAIT HERE...");
			while ([[self processingThread] isExecuting]) {
			}
			
			[self setProcessingThread:nil];
		}
		
		[window orderOut:self];
		
		if ([self shouldTerminate]) {
			[NSApp replyToApplicationShouldTerminate:YES];
		}
	}
}

- (void) loadBackupTaskFromFile:(NSString *)filename
{
	// ADD EXCEPTION HANDLING HERE!!!
	NSLog(@"Loading task data from %@", filename);
	
	if ([task filename]) {
		NSLog(@"Auto-saving %@", [task filename]);
		[self saveBackupTaskToFile:[task filename]];
	}	
	
	//CHECK: do we need this here?
	[task release];
	
	task = [[AudioBackupTask alloc] init];
	AudioBackupTask *loadedTask = (AudioBackupTask *)[NSKeyedUnarchiver unarchiveObjectWithFile:filename];
	
	[task setFilename:[loadedTask filename]];
	[task setSourceFolder:[loadedTask sourceFolder]];
	[task setTargetFolder:[loadedTask targetFolder]];
	[task setAllowedExtensions:[loadedTask allowedExtensions]];
	[task setHashes:[loadedTask hashes]];
	
	[sourceFolder setURL:[NSURL fileURLWithPath:[task sourceFolder]]];
	[targetFolder setURL:[NSURL fileURLWithPath:[task targetFolder]]];
	
	if ([task allowedExtensions]) {
		[allowedExtensions setStringValue:[task allowedExtensions]];
	}
	else {
		[allowedExtensions setStringValue:@"m4a"];
	}
	[startButton setEnabled:YES];	
	[window setTitle:[[task filename] lastPathComponent]];
}

- (void) performBackup:(NSMutableDictionary *)hashes {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *manager = [[[NSFileManager alloc] init] autorelease];
	
	NSRange endRange;
    endRange.location = [[textView textStorage] length];
    endRange.length = 0;
	[[textView textStorage] beginEditing];
	[[[textView textStorage] mutableString] setString:@""];
	[[textView textStorage] endEditing];
	
	[progressView setHidden:NO];
	[progressStop setHidden:NO];
	[progressFile setStringValue:@"Indexing..."];
	[progressFile setHidden:NO];
	[progressView setUsesThreadedAnimation:YES];
	[progressView setIndeterminate:YES];
	[progressView startAnimation:self];
	
	NSUInteger options = NSDirectoryEnumerationSkipsPackageDescendants
	                   ^ NSDirectoryEnumerationSkipsHiddenFiles;
	NSArray *properties = [NSArray arrayWithObjects:
						   NSURLFileSizeKey,
						   NSURLNameKey,
						   NSURLCreationDateKey,
						   NSURLContentAccessDateKey,
						   NSURLContentModificationDateKey,
						   NSURLAttributeModificationDateKey,
						   NSURLParentDirectoryURLKey,
						   nil];
	
	//MACOSX10.6
	NSDirectoryEnumerator *dirEnum = [manager enumeratorAtURL:[sourceFolder URL]
								   includingPropertiesForKeys:properties
													  options:options
												 errorHandler:NULL];
	
	//NSFileSystemFreeSize can be used to check if there's enough free space
	//in the target folder... Proper computation should only consider files that
	//need to be copied and the delta of updated files (wrt. to the older
	//versions in the backup?)
	
	NSError *err = nil;
	NSString *source = [[sourceFolder URL] path];
	NSString *target = [[targetFolder URL] path];
	NSArray *exts = [[[allowedExtensions stringValue]
					  stringByReplacingOccurrencesOfString:@"." withString:@""]
					 componentsSeparatedByString:@" "];

	NSMutableDictionary *copyFiles = [[NSMutableDictionary alloc] init];
	NSDate *start_time = [NSDate date];
	
	[logfile setIsVisible:YES];
	[textView log:[NSString stringWithFormat:@"Started indexing at [%@]\n\n",
				   start_time]];
	
	long long filesize = 0;
	__block long errors = 0;
	long initial = 0;
	long updated = 0;
	long skipped = 0;
	long indexed = 0;
	
	for (NSURL *theURL in dirEnum) {
		if ([[NSThread currentThread] isCancelled]) {
			[textView log:@"\nIndexing cancelled.\n\n"];
			[progressView setHidden:YES];
			[progressStop setHidden:YES];
			[progressFile setHidden:YES];
			[progressView setDoubleValue:0.0];
			[progressFile setStringValue:@""];
			[startButton setEnabled:YES];			
			[copyFiles release];
			[pool release];
			return;
		}
				
		// First, we check if the file has an allowed extension.
		NSString *fileName;
		[theURL getResourceValue:&fileName forKey:NSURLNameKey error:NULL];
		if (![exts containsObject:[fileName pathExtension]]) {
			skipped++;
			[textView log:[NSString stringWithFormat:@"Skipped %@\n", fileName]];
			continue;
		}
		
		[textView log:[NSString stringWithFormat:@"Indexing %@\n",
					   [theURL lastPathComponent]]];
		
		NSString *copyName;
		copyName = [[theURL path] stringByReplacingOccurrencesOfString:source
															withString:target];
		
		NSString *copyPath = [copyName stringByDeletingLastPathComponent];
		if (![manager fileExistsAtPath:copyPath]) {
			[textView log:[NSString stringWithFormat:@"Creating missing " \
						   "path(s) for %@...", copyPath] lineBreak:NO];
			
			BOOL result = [manager createDirectoryAtPath:copyPath
							 withIntermediateDirectories:YES
											  attributes:nil
												   error:&err];
			
			// If copyPath cannot be created, we have to skip this file.
			if (!result) {
				errors++;
				[textView log:[NSString stringWithFormat:@" ERROR\n%@\n", err]];
				continue;
			}
			else {
				[textView log:@" OK\n"];
			}
		}
		
		NSURL *copyURL = [NSURL fileURLWithPath:copyName];
		
		// Check if the file already exists at copyPath.
		if (![manager fileExistsAtPath:copyName]) {
			initial++;
			[copyFiles setObject:copyURL forKey:theURL];
		}
		else {
			BOOL fileContentsEqual = YES;
			
			if ([bitByBitChecking state] == NSOnState) {
				NSData *src = [[NSData alloc] initWithContentsOfFile:[theURL path]
															 options:NSDataReadingUncached
															   error:&err];
				
				NSString *srcHash = [src md5Hash];
				NSString *copyHash = [hashes objectForKey:copyURL];
				if (!copyHash || ![copyHash isEqualToString:srcHash]) {
					NSData *dst = [[NSData alloc] initWithContentsOfFile:copyName
																 options:NSDataReadingUncached
																   error:&err];
					fileContentsEqual = [src isEqualToData:dst];
					[dst release];
				}
				
				[src release];
			}
			else {
				NSDictionary *src = [manager attributesOfItemAtPath:[theURL path] error:&err];
				NSDictionary *dst = [manager attributesOfItemAtPath:copyName error:&err];

				fileContentsEqual = ([src objectForKey:NSFileType] == [dst objectForKey:NSFileType])
				|| ([src objectForKey:NSFileSize] == [dst objectForKey:NSFileSize])
				|| ([src objectForKey:NSFileCreationDate] == [dst objectForKey:NSFileCreationDate])
				|| ([src objectForKey:NSFileModificationDate] == [dst objectForKey:NSFileModificationDate]);
			}

			if (!fileContentsEqual) {
				updated++;
				if ([createBackupFiles state] == NSOnState) {
					NSString *backupName = [NSString stringWithFormat:@"%@.backup", copyName];
					NSURL *backupURL = [NSURL fileURLWithPath:backupName];
					
					[textView log:[NSString stringWithFormat:@"Creating "
								   "backup file: %@...", backupName] lineBreak:NO];
					
					//MACOSX10.6
					BOOL result = [manager moveItemAtURL:copyURL toURL:backupURL error:&err];
					
					if (!result) {
						errors++;
						[textView log:[NSString stringWithFormat:@" ERROR\n%@\n", err]];
						continue;
					}
					else {
						[textView log:@" OK\n"];
					}
				}
				else {
					[textView log:[NSString stringWithFormat:@"Deleting "
								   "existing file: %@...", copyName] lineBreak:NO];
					
					//MACOSX10.6
					BOOL result = [manager removeItemAtURL:copyURL error:&err];

					if (!result) {
						errors++;
						[textView log:[NSString stringWithFormat:@" ERROR\n%@\n", err]];
						continue;
					}
					else {
						[textView log:@" OK\n"];
					}					
				}
				
				[copyFiles setObject:[NSURL fileURLWithPath:copyName] forKey:theURL];
			}
		}

		NSString *status;
		status = [NSString stringWithFormat:@"Indexed %ld files...", ++indexed];
		[progressFile setStringValue:status];
	}
	
	NSDate *end_time = [NSDate date];
	[textView log:[NSString stringWithFormat:@"\nIndexed %ld files in %.2f "
				   "seconds.\n\n", indexed, [end_time timeIntervalSinceDate:start_time]]];
	
	[progressView stopAnimation:self];
	[progressView setIndeterminate:NO];
	[progressView setDoubleValue:0.0];
	
	if ([copyFiles count]) {
		start_time = [NSDate date];
		
		[textView log:[NSString stringWithFormat:@"Started copying at [%@]\n\n",
					   start_time]];
	}
	
	__block long copied = 0;
	double progressDelta = 100.0 / (1.0 * [copyFiles count]);
	
	[copyFiles enumerateKeysAndObjectsUsingBlock: ^(id key, id obj, BOOL *stop) {
		if ([[NSThread currentThread] isCancelled]) {
			[textView log:@"\nCopying cancelled.\n\n"];
			*stop = YES;
		}
		
		NSURL *theURL = key;
		NSURL *copyURL = obj;
		NSError *err = nil;
		
		[textView log:[NSString stringWithFormat:@"Copying %@...",
					   [theURL lastPathComponent]] lineBreak:NO];
		
		//MACOSX10.6
		BOOL result = [manager copyItemAtURL:theURL toURL:copyURL error:&err];
		
		if (!result) {
			errors++;
			[textView log:[NSString stringWithFormat:@" ERROR\n%@\n", err]];
		}
		else {
			NSDictionary *attrib = [manager attributesOfItemAtPath:[theURL path]
															 error:&err];
			
			[textView log:@" OK\n"];
			[textView log:[NSString stringWithFormat:@"Setting attributes "
						   "for %@...", [theURL lastPathComponent]] lineBreak:NO];
			result = [manager setAttributes:attrib
							   ofItemAtPath:[copyURL path]
									  error:&err];
			
			if (!result) {
				errors++;
				[textView error:[NSString stringWithFormat:@" ERROR\n%@\n", err]];
			}
			else {
				[textView log:@" OK\n"];
			}
			
			NSData *dst = [[NSData alloc] initWithContentsOfFile:[copyURL path]
														 options:NSDataReadingUncached
														   error:&err];
			
			copied++;
			[hashes setObject:[dst md5Hash] forKey:copyURL];
			[dst release];			
		}		
		
		NSString *status = [theURL lastPathComponent];
		[progressView incrementBy:progressDelta];
		[progressFile setStringValue:status]; 
    }];
	
	[copyFiles release];
	end_time = [NSDate date];
	if (copied) {
		[textView log:[NSString stringWithFormat:@"\nCopied %ld files in %.2f "
					   "seconds.\n\n", copied,
					   [end_time timeIntervalSinceDate:start_time]]];
	}
	
	[textView log:[NSString stringWithFormat:@"Finished backup at [%@]\n\n",
				   end_time]];
	
	NSArray *lines = [NSArray arrayWithObjects:
					  [NSString stringWithFormat:@"Indexed: %4d\n", indexed],
					  [NSString stringWithFormat:@" Copied: %4d\n", copied],
					  [NSString stringWithFormat:@" Errors: %4d\n", errors],
					  [NSString stringWithFormat:@"Skipped: %4d\n", skipped],
					  [NSString stringWithFormat:@"Initial: %4d\n", initial],
					  [NSString stringWithFormat:@"Updated: %4d\n", updated],
					  nil];
	[textView logArray:lines];
	
	[progressStop setHidden:YES];
	[progressView setHidden:YES];
	[progressFile setHidden:YES];
	[progressView setDoubleValue:0.0];
	[progressFile setStringValue:@""];
	[startButton setEnabled:YES];

	[pool release];
}

@end