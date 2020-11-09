///////////////////////////////////////////////////////////////////////////////
//
// DESCRIPTION
// 	Apple Event Descriptors helper
//
// COPYRIGHT
//    Copyright (c) 2008 - 2020 Wacom Co., Ltd.
//    All rights reserved
//
///////////////////////////////////////////////////////////////////////////////

#pragma once

#include <Cocoa/Cocoa.h>

@interface NSAppleEventDescriptor (WacomExtension)

+ (NSAppleEventDescriptor *)descriptorWithUInt32:(UInt32)unsignedInt_I;

+ (NSAppleEventDescriptor *)descriptorForObjectOfType:(DescType)objType_I
															 withKey:(NSAppleEventDescriptor *)keyDesc_I
															  ofForm:(DescType)keyForm_I;

+ (NSAppleEventDescriptor *)descriptorForObjectOfType:(DescType)objType_I
															 withKey:(NSAppleEventDescriptor *)keyDesc_I
															  ofForm:(DescType)keyForm_I
																 from:(NSAppleEventDescriptor *)fromDesc_I;

- (OSErr)sendWithPriority:(UInt32)priority andTimeout:(UInt32)timeout_I;

- (NSAppleEventDescriptor*)sendExpectingReplyWithPriority:(UInt32)priority_I
															  andTimeout:(UInt32)timeout_I;
@end
