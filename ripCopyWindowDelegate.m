//
//  ripCopyWindowDelegate.m
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import "ripCopyWindowDelegate.h"

#import "ripCopyAppDelegate.h"

@implementation ripCopyWindowDelegate

@synthesize appDelegate;

- (id) init
{
	NSLog(@"ripCopyWindowDelegate should NOT be created without app delegate!");
	self = [super init];
	return self;
}

- (id) initWithAppDelegate:(NSObject <NSApplicationDelegate> *)sender
{
    if (self = [super init])
    {
		[self setAppDelegate:sender];
	}
	
	return self;
}

- (BOOL) windowShouldClose:(id)sender
{
	ripCopyAppDelegate *app = (ripCopyAppDelegate *)[self appDelegate];
	if (!([app isEdited] || [app isRunning])) {
		if ([[app task] filename]) {
			NSLog(@"Auto-saving %@", [[app task] filename]);
			[app saveBackupTaskToFile:[[app task] filename]];
		}
		return YES;
	}
	
	NSBeginAlertSheet([NSString stringWithFormat:@"Do you want to save \"%@\"?",
					   [sender title]],
					  @"Save",
					  @"Cancel",
					  @"Don't Save",
					  sender,
					  (ripCopyAppDelegate *)[self appDelegate],
					  nil,
					  @selector(windowShouldClose:returnCode:contextInfo:),
					  NULL,
					  @"Your changes will be lost if you don't save them.");
	
	return NO;
}

@end
