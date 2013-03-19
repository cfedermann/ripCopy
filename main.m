//
//  main.m
//
//  Copyright 2011-2013 Christian Federmann. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSDate *start_time = [NSDate date];

    int result = NSApplicationMain(argc,  (const char **) argv);

	NSDate *end_time = [NSDate date];
	NSLog(@"Runtime: %.2f sec", [end_time timeIntervalSinceDate:start_time]);
	
    [pool drain];	
	return result;
}