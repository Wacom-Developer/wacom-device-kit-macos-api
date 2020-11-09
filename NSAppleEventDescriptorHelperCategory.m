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

#import "NSAppleEventDescriptorHelperCategory.h"

@implementation NSAppleEventDescriptor (WacomExtension)

//////////////////////////////////////////////////////////////////////////////

//
//	Purpose:
//		Create an autoreleased NSAppleEventDescriptor instance for an Apple Event 
//		object from type objType, key keyDesc, and form key.
//
//	Parameters:
//		objType_I - The object class of the desired Apple event objects.
//		keyDesc_I - The key data for the object specifier.
//		keyForm_I - The key form for the object specifier.
//
//	Return:
//		An NSAppleEventDescriptor instance or nil in case of error.
//
//	Notes:
//		This is used to create descriptor for an object that has no container.
//

+ (NSAppleEventDescriptor *) descriptorForObjectOfType:(DescType)objType_I
															  withKey:(NSAppleEventDescriptor *)keyDesc_I
																ofForm:(DescType)keyForm_I
{
	NSAppleEventDescriptor * __autoreleasing result = nil;
	AEDesc resultDesc;
	OSErr err = CreateObjSpecifier(objType_I,
											(AEDesc*)[[NSAppleEventDescriptor nullDescriptor] aeDesc], // null descriptor means no container
											keyForm_I,
											(AEDesc*)[keyDesc_I aeDesc],
											NO,
											&resultDesc);
	if (err == noErr)
	{
		result = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultDesc];
	}
	return result;
}



//////////////////////////////////////////////////////////////////////////////

//
//	Purpose:
//		Create an autoreleased NSAppleEventDescriptor instance for an Apple Event 
//		object from type objType, key keyDesc, and form key.
//
//	Parameters:
//		objType	- The object class of the desired Apple event objects.
//		keyDesc	- The key data for the object specifier record.
//		keyForm	- The key form for the object specifier record.
//		fromDesc	- The container object of the requested Apple Event object.
//
//	Return:
//		An NSAppleEventDescriptor instance or nil in case of error.
//

+ (NSAppleEventDescriptor *) descriptorForObjectOfType:(DescType)objType_I
															  withKey:(NSAppleEventDescriptor *)keyDesc_I
																ofForm:(DescType)keyForm_I
																  from:(NSAppleEventDescriptor *)fromDesc_I
{
	NSAppleEventDescriptor * __autoreleasing result     = nil;
	AEDesc                  resultDesc;
	
	OSErr err = CreateObjSpecifier(objType_I,
											(AEDesc*)[fromDesc_I aeDesc],
											keyForm_I,
											(AEDesc*)[keyDesc_I aeDesc],
											NO,
											&resultDesc);
	if (err == noErr)
	{
		result = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultDesc];
	}
	return result;
}



//////////////////////////////////////////////////////////////////////////////

//
//	Purpose:
//		Create and return an autoreleased NSAppleEventDescriptor that contains 
//		an UIInt32 value.
//
//	Parameters:
//		unsignedInt - The UInt32 value to place into the Apple Event descriptor.
//
//	Return:
//		An NSAppleEventDescriptor instance that represents an UIInt32 value.
//

+ (NSAppleEventDescriptor *)descriptorWithUInt32:(UInt32)unsignedInt_I
{
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeUInt32
						bytes:&unsignedInt_I length:sizeof(unsignedInt_I)];
}



//////////////////////////////////////////////////////////////////////////////

//
//	Purpose:
//		Send the Apple Event represented by this NSAppleEventDescriptor
//		without waiting for a reply from the target.
//
//	Parameters:
//		priority - Priority for the delivery of the Apple Event.
//		timeout - Timeout in ticks.
//
//	Return:
//		An OSErr code.
//

- (OSErr) sendWithPriority:(UInt32)__unused priority_I andTimeout:(UInt32)timeout_I
{
	// Send the apple event without waiting for a reply.
	return (OSErr)AESendMessage([self aeDesc], NULL, kAENoReply, timeout_I);
}



//////////////////////////////////////////////////////////////////////////////

//
//	Purpose:
//		Send the Apple Event represented by this NSAppleEventDescriptor.
//		This method waits for a reply from the target and returns the reply
//		as an NSAppleEventDescriptor.
//
//	Parameters:
//		priority - Priority for the delivery of the Apple Event.
//		timeout - Timeout in ticks.
//
//	Return:
//		An autoreleased NSAppleEventDescriptor that contains the reply or
//		nil if error occurs.
//

- (NSAppleEventDescriptor*) sendExpectingReplyWithPriority:(UInt32)__unused priority_I
																andTimeout:(UInt32)timeout_I
{
	NSAppleEventDescriptor * __autoreleasing result = nil;
	AppleEvent resultDesc;
	
	// send the apple event
	OSStatus err = AESendMessage([self aeDesc], &resultDesc, kAEWaitReply, timeout_I);
	
	// get the reply
	if (err == noErr)
	{
		result = [[NSAppleEventDescriptor alloc] initWithAEDescNoCopy:&resultDesc];
	}

	return result;
}

@end
