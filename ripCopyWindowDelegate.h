//
//  ripCopyWindowDelegate.h
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ripCopyWindowDelegate : NSObject <NSWindowDelegate> {
	NSObject <NSApplicationDelegate> *appDelegate;
}

- (id) initWithAppDelegate:(NSObject <NSApplicationDelegate> *)sender;

- (BOOL) windowShouldClose:(id)sender;

@property (retain) NSObject <NSApplicationDelegate> *appDelegate;

@end