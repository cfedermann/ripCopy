//
//  cocoa_fooAppDelegate.h
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "AudioBackupTask.h"
#import "ripCopyWindowDelegate.h"

#define MAX_LINE_LENGTH 55

@interface ripCopyAppDelegate : NSObject <NSApplicationDelegate> {
    NSWindow *window;
	NSThread *processingThread;
	BOOL shouldTerminate;
	AudioBackupTask *task;
	ripCopyWindowDelegate *windowDelegate;
	
	IBOutlet id progressView;
	IBOutlet id progressFile;
	IBOutlet id progressStop;
	IBOutlet id sourceFolder;
	IBOutlet id targetFolder;
	IBOutlet id allowedExtensions;
	IBOutlet id startButton;
	IBOutlet id menuNew;
	IBOutlet id menuSave;
	IBOutlet id menuSaveAs;
	IBOutlet id bitByBitChecking;
	IBOutlet id createBackupFiles;
	
	IBOutlet id textView;
	IBOutlet NSPanel *logfile;
	IBOutlet id logfileSave;
}

- (IBAction) checkAllowedExtensions: sender;

- (IBAction) newBackupTask: sender;
- (IBAction) loadBackupTask: sender;
- (IBAction) saveBackupTask: sender;
- (IBAction) startBackupProcess: sender;
- (IBAction) stopBackupProcess: sender;
- (IBAction) saveLogfile: sender;

- (BOOL) isEdited;
- (BOOL) isRunning;

- (void) windowShouldClose:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo;
- (void) saveBackupTaskAndCloseWindow:(BOOL)closeWindow;
- (void) saveBackupTaskToFile:(NSString *)filename;
- (void) saveBackupTaskToFile:(NSString *)filename closeWindow:(BOOL)closeWindow;
- (void) loadBackupTaskFromFile:(NSString *)filename;

- (void) performBackup:(NSMutableDictionary *)hashes;

@property (assign) IBOutlet NSWindow *window;
@property (retain) NSThread *processingThread;
@property (assign) BOOL shouldTerminate;
@property (retain) AudioBackupTask *task;
@property (retain) ripCopyWindowDelegate *windowDelegate;

@end
