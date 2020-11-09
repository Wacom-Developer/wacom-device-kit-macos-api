///////////////////////////////////////////////////////////////////////////////
//
// DESCRIPTION
// 	Apple Event access to the Wacom tablet driver.
//
// COPYRIGHT
//    Copyright (c) 2008 - 2020 Wacom Co., Ltd.
//    All rights reserved
//
///////////////////////////////////////////////////////////////////////////////

#pragma once

#import <Cocoa/Cocoa.h>
#import "TabletAEDictionary.h"

// All Apple Event indices are 1-based
#define kInvalidAppleEventIndex 0

@interface WacomTabletDriver : NSObject
{

}

// Context Management
+ (UInt32) createContextForTablet:(UInt32)index_I type:(AEContextType)contextType_I;
+ (void) destroyContext:(UInt32)context_I;

// Get Data
+ (NSAppleEventDescriptor*) dataForAttribute:(DescType)attribute_I
												  ofType:(DescType)dataType_I
										  routingTable:(NSAppleEventDescriptor *)routingDesc_I;
										  
+ (UInt32) controlCountOfContext:(UInt32)context_I
						forControlType:(eAETabletControlType)controlType_I;
						
+ (UInt32) functionCountOfControl:(UInt32)control_I
								ofContext:(UInt32)context_I
						 forControlType:(eAETabletControlType)controlType_I;

+ (UInt32) tabletCount;
+ (UInt32) transducerCountForTablet:(UInt32)tablet_I;

// Set Data
+ (BOOL) setBytes:(void*)bytes_I
			  ofSize:(UInt32)size_I
			  ofType:(DescType)dataType_I
	  forAttribute:(DescType)attribute_I
	  routingTable:(NSAppleEventDescriptor *)routingDesc_I;
	  
// Apple Event routing tables

// - Raw
+ (NSAppleEventDescriptor *) routingTableForDriver;
+ (NSAppleEventDescriptor *) routingTableForTablet:(UInt32)tablet_I;
+ (NSAppleEventDescriptor *) routingTableForTablet:(UInt32)context_I transducer:(UInt32)transducer_I;

// - Context-based
+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I;
+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I control:(UInt32)control_I controlType:(eAETabletControlType)controlType_I;
+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I control:(UInt32)control_I controlType:(eAETabletControlType)controlType_I function:(UInt32)function_I;

// Utilities
+ (NSAppleEventDescriptor *)driverAppleEventTarget;
+ (DescType)descTypeFromControlType:(eAETabletControlType)controlType_I;
+ (void) resendLastTabletEventOfType:(DescType)tabletEventType_I;

@end
