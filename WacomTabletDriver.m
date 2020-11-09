///////////////////////////////////////////////////////////////////////////////
//
// DESCRIPTION
// 	Apple Event access to the Wacom tablet driver.
//
//
// 	To set values in the driver, you must create a "context" object to represent
// 	your application and its customized values. Contexts are tied both to your
// 	application and to a specific tablet; contexts take the place of tablets in
// 	the object hiearchy.
//
// 	You may retrieve values directly without creating a context. However, if you
// 	application does create a context, you should retrieve values through it
// 	instead of by querying the tablet directly. (See "Raw" vs. "Context-based"
// 	routing table methods.)
//
// COPYRIGHT
//    Copyright (c) 2008 - 2020 Wacom Co., Ltd.
//    All rights reserved
//
///////////////////////////////////////////////////////////////////////////////

#import "WacomTabletDriver.h"
#import "NSAppleEventDescriptorHelperCategory.h"

#define kTabletDriverAETimeout 360000 // in ticks 

///////////////////////////////////////////////////////////////////////////////
@implementation WacomTabletDriver

#pragma mark -
#pragma mark CONTEXT MANAGEMENT
#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to create a context for 
//					a tablet. A context is an application-specific sandbox in which 
//					your application may customize tablet properties. 
//
//	Parameters:	index_I 			- The index of the tablet of interest.
//					contextType_I	- How the context is initialized (see notes for AEContextType)
//
// Returns:		A unique UInt32 value that represents the context created for the 
//					application or 0 in case of error. 
//
// Notes:		An application needs to create a context before it can query or 
//					override functions of tablet controls. 
//

+ (UInt32) createContextForTablet:(UInt32)index_I type:(AEContextType)contextType_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor  *routingDesc   = nil;
	NSAppleEventDescriptor  *response      = nil;

	// create the apple event for object creation
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAECreateElement 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
				
	// set the object class to cContext
	[event setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:cContext] 
				 forKeyword:keyAEObjectClass];
	
	// add the tablet index to the apple event to indicate which tablet we are
	// creating the context for
	routingDesc = [self routingTableForTablet:index_I];
	[event setDescriptor:routingDesc
				 forKeyword:keyAEInsertHere];
						
	// indicate that we want a blank context
	[event setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:contextType_I]
				 forKeyword:'for '];
	
	// send the apple event
	response = [event sendExpectingReplyWithPriority:kAEHighPriority 
													  andTimeout:kTabletDriverAETimeout];

	// extract the context id and return it
	return [[response descriptorForKeyword:keyDirectObject] int32Value];
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to delete a context 
//					created for a tablet. 
//
//	Parameters:	context_I - The context to be deleted.
//
// Notes:		An application must destroy the context it creates when it's done 
//					with the context or upon termination. 
//

+ (void)destroyContext:(UInt32)context_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor  *routingDesc   = nil;
	
	// create the apple event for object deletion
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAEDelete 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];

	// add the context id to the event
	routingDesc = [self routingTableForContext:context_I];
	
	[event setDescriptor:routingDesc
				 forKeyword:keyDirectObject];
	
	// send the event
	[event sendWithPriority:kAEHighPriority andTimeout:kTabletDriverAETimeout];
}

#pragma mark -
#pragma mark GET DATA
#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Query for an attribute in the Wacom tablet driver.
//
//					In order to pick which attribute to get, you must supply an Apple 
//					Event routing table which directs this request within the 
//					driver's object hierarchy. A number of methods are defined in 
//					this class to create routing tables for various structures. 
//
//	Parameters:	attribute_I		 - ID of an attribute exposed by some object in the
//									  		driver (eg pName for tablet name).
//					dataType_I		 - Type of data (eg typeUTF8Text for name).
//					routingDesc_I	 - How to find the object which contains the attribute
//											in the driver object hierarchy. Pass the result of
//											one of the +routingTableForXXX methods defined
//											below.
//
//	Returns:		An autoreleased NSAppleEventDescriptor that contains the data for 
//					the attribute or nil in case of error. 
//
//

+ (NSAppleEventDescriptor*) dataForAttribute:(DescType)attribute_I
												  ofType:(DescType)dataType_I
										  routingTable:(NSAppleEventDescriptor *)routingDesc_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor  *attribDesc    = nil;
	NSAppleEventDescriptor  *reply         = nil;
	
	// create the apple event for getting attribute data
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAEGetData 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
	
	// create descriptor for the attribute of interest
	// the routingDesc is the container of the attribute
	attribDesc = [NSAppleEventDescriptor descriptorForObjectOfType:formPropertyID 
																			 withKey:[NSAppleEventDescriptor descriptorWithTypeCode:attribute_I]
																			  ofForm:formPropertyID
																				 from:routingDesc_I];
	
	// add the attribute descriptor to the event
	[event setDescriptor:attribDesc forKeyword:keyDirectObject];
	
	// indicate the data type of the attribute
	[event setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:dataType_I]
				 forKeyword:keyAERequestedType];
	
	// send the event and wait for reply
	reply = [event sendExpectingReplyWithPriority:kAEHighPriority 
												  andTimeout:kTabletDriverAETimeout];
	
	// return the data 
	return [reply descriptorForKeyword:keyDirectObject];
}

#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to query for the number 
//					of tablet controls of the specified type on a tablet. 
//
//	Parameters:	context_I - The context for the tablet of interest.
//								See createContextForTablet below.
//					controlType_I - Type of tablet control of interest.
//
//	Returns:		Number of the controls.
//

+ (UInt32) controlCountOfContext:(UInt32)context_I
						forControlType:(eAETabletControlType)controlType_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor  *routingDesc   = nil;
	NSAppleEventDescriptor  *response      = nil;
	
	// create the apple event for object count
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAECountElements 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
	
	// set type of control object to be counted to the input control type
	[event setDescriptor:[NSAppleEventDescriptor	descriptorWithTypeCode:[self descTypeFromControlType:controlType_I]]
				 forKeyword:keyAEObjectClass];
	
	// create context descriptor corresponding to the tablet of interest
	routingDesc = [self routingTableForContext:context_I];
	
	// add context descriptor to the event
	[event setDescriptor:routingDesc forKeyword:keyDirectObject];

	// send the event
	response = [event sendExpectingReplyWithPriority:kAEHighPriority 
													  andTimeout:kTabletDriverAETimeout];
	
	// extract the count from the reply and return it
	return [[response descriptorForKeyword:keyDirectObject] int32Value];
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to query for the number 
//					of functions for a specific tablet control. 
//
//	Parameters:	control_I - The index of the control of interest.
//					context_I - The context for the tablet of interest.
//									See createContextForTablet below.
//					controlType_I - Type of tablet control of interest.
//
//	Returns:		Number of the functions of the specified control.
//

+ (UInt32) functionCountOfControl:(UInt32)control_I
								ofContext:(UInt32)context_I
						 forControlType:(eAETabletControlType)controlType_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor	*routingDesc	= nil;
	NSAppleEventDescriptor  *response      = nil;
	
	// create the apple event for object count
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAECountElements 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
	
	// set type of object to be counted to control function
	[event setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:cWTDControlFunction]
				 forKeyword:keyAEObjectClass];
	
	// create descriptor for the control and control type of interest
	// contextDesc is the container
	routingDesc = [self routingTableForContext:context_I
												  control:control_I
											 controlType:controlType_I];
	
	// add the control descriptor to the event
	[event setDescriptor:routingDesc forKeyword:keyDirectObject];

	// send the apple event
	response = [event sendExpectingReplyWithPriority:kAEHighPriority 
													  andTimeout:kTabletDriverAETimeout];
						
	// extract the count from the reply and return it
	return [[response descriptorForKeyword:keyDirectObject] int32Value];
}

#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to query for the number 
//					of tablets. 
//
//	Returns:		Number of tablets.
//

+ (UInt32) tabletCount
{
	NSAppleEventDescriptor  *event      = nil;
	NSAppleEventDescriptor  *reply      = nil;
	
	// create the apple event for object count
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAECountElements 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
						
	// set object class to tablet to indicate that we want tablet count
	[event setDescriptor:[NSAppleEventDescriptor	descriptorWithTypeCode:cWTDTablet]
				 forKeyword:keyAEObjectClass];
						
	[event setDescriptor:[self routingTableForDriver] forKeyword:keyDirectObject];

	// send the event
	reply = [event sendExpectingReplyWithPriority:kAEHighPriority 
												  andTimeout:kTabletDriverAETimeout];
						
	// get the reply and return the count
	return [[reply descriptorForKeyword:keyDirectObject] int32Value];
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to query for the number 
//					of tranducers on a particular tablet. 
//
//	Returns:		Number of transducers.
//

+ (UInt32) transducerCountForTablet:(UInt32)tablet_I
{
	NSAppleEventDescriptor  *event      = nil;
	NSAppleEventDescriptor  *reply      = nil;
	NSAppleEventDescriptor  *routingDesc = nil;
	
	// create the apple event for object count
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAECountElements 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
	
	// set object class to tablet to indicate that we want tablet count
	[event setDescriptor:[NSAppleEventDescriptor	descriptorWithTypeCode:cWTDTransducer]
				 forKeyword:keyAEObjectClass];
	
	// create context descriptor corresponding to the tablet of interest
	routingDesc = [self routingTableForTablet:tablet_I];
	
	// add context descriptor to the event
	[event setDescriptor:routingDesc forKeyword:keyDirectObject];
	
	// send the event
	reply = [event sendExpectingReplyWithPriority:kAEHighPriority 
												  andTimeout:kTabletDriverAETimeout];
	
	// get the reply and return the count
	return [[reply descriptorForKeyword:keyDirectObject] int32Value];
}

#pragma mark -
#pragma mark SET DATA
#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Sets the value of an attribute in the Wacom tablet driver.
//
//					In order to pick which attribute to set, you must supply an Apple 
//					Event routing table which directs this request within the 
//					driver's object hierarchy. A number of methods are defined in 
//					this class to create routing tables for various structures. 
//
//	Parameters:	bytes			- Data for the attribute.
//					size			- Number of bytes of the attribute data.
//					dataType		- Data type for the attribute of interest.
//					attribute	- Attribute ID.
//					routingDesc	- How to get to the attribute. Pass the result of one 
//									  of the +routingTableForXXX methods defined below. 
//
//	Return:		YES if success or NO in case of error. 
//

+ (BOOL) setBytes:(void*)bytes_I
			  ofSize:(UInt32)size_I
			  ofType:(DescType)dataType_I
	  forAttribute:(DescType)attribute_I
	  routingTable:(NSAppleEventDescriptor *)routingDesc_I
{
	NSAppleEventDescriptor  *event         = nil;
	NSAppleEventDescriptor  *attribDesc    = nil;
	NSAppleEventDescriptor  *data          = nil;

	// create the apple event for setting data
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAECoreSuite 
																	 eventID:kAESetData 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];

	//---------- Routing --------------------------------------------------------
	
	// Add the attribute descriptor to the routing table
	attribDesc = [NSAppleEventDescriptor descriptorForObjectOfType:formPropertyID 
																			 withKey:[NSAppleEventDescriptor descriptorWithTypeCode:attribute_I]
																			  ofForm:formPropertyID
																				 from:routingDesc_I];
	// add the whole thing to the event
	[event setDescriptor:attribDesc
				 forKeyword:keyDirectObject];

	//---------- Data payload ---------------------------------------------------
	
	// Data type
	[event setDescriptor:[NSAppleEventDescriptor descriptorWithTypeCode:dataType_I]
				 forKeyword:keyAERequestedType];
	
	// Data bytes descriptor
	data = [NSAppleEventDescriptor descriptorWithDescriptorType:dataType_I
																			bytes:bytes_I
																		  length:size_I];
	[event setDescriptor:data
				 forKeyword:keyAEData];

	// send the event
	OSErr err = [event sendWithPriority:kAEHighPriority andTimeout:kTabletDriverAETimeout];

	return (err == noErr);
}

#pragma mark -
#pragma mark APPLE EVENT ROUTING TABLES
#pragma mark -

#pragma mark Raw

//////////////////////////////////////////////////////////////////////////////

//
// Note:			If you use the raw routing tables to set an attribute. That would
//					change the GLOBAL tablet object, so the changes you make will 
//					affect ALL applications. 
//


//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Create an autoreleased NSAppleEventDescriptor representing the 
//					tablet driver AppleEvent object. 
//

+ (NSAppleEventDescriptor *)routingTableForDriver
{
	return [NSAppleEventDescriptor descriptorForObjectOfType:cWTDDriver 
																	 withKey:[NSAppleEventDescriptor descriptorWithUInt32:1] // first and the only one
																	  ofForm:formAbsolutePosition];
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Apple Event descriptor which will send commands to the tablet 
//					object in the driver. 
//
// Parameters:	tablet	- tablet index, 1-relative
//
// Note:			You should ALMOST NEVER use this routing table to set an 
//					attribute. That would change the GLOBAL tablet object, so the 
//					changes you make will affect ALL applications. 
//
//					You may need this to get certain attributes, however.
//

+ (NSAppleEventDescriptor *) routingTableForTablet:(UInt32)tablet_I
{
	NSAppleEventDescriptor  *tabletDesc = nil;
	
	// create descriptor for the tablet of interest
	tabletDesc = [NSAppleEventDescriptor descriptorForObjectOfType:cWTDTablet 
																			 withKey:[NSAppleEventDescriptor descriptorWithUInt32:tablet_I]
																			  ofForm:formAbsolutePosition];
	return tabletDesc;
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Apple Event descriptor which will send commands to a transducer 
//					in the given tablet.
//
// Parameters:	tablet		- tablet index, 1-relative
//					transducer	- transducer index, 1-relative
//

+ (NSAppleEventDescriptor *) routingTableForTablet:(UInt32)tablet_I
													 transducer:(UInt32)transducer_I
{
	NSAppleEventDescriptor  *contextDesc   = nil;
	NSAppleEventDescriptor  *controlDesc   = nil;
	
	// create context descriptor
	contextDesc    = [self routingTableForTablet:tablet_I];
						
	// create control descriptor whose container is contextDesc
	controlDesc    = [NSAppleEventDescriptor descriptorForObjectOfType:cWTDTransducer
																				  withKey:[NSAppleEventDescriptor descriptorWithUInt32:transducer_I]
																					ofForm:formAbsolutePosition
																					  from:contextDesc];
	return controlDesc;
}
	
#pragma mark -
#pragma mark Context-Based

//////////////////////////////////////////////////////////////////////////////

//
// Note:			You should always set attributes within a context, so that your 
//					settings do not affect other applications. (So these are the 
//					methods you generally want to use!) 
//
//					However, some objects are not exposed through contexts. Refer to 
//					the tree diagram in TabletAEDictionary.h. 
//
//					These require you to have created a context with 
//					+createContextForTablet. 
//


//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Apple Event descriptor which will send commands to the context 
//					object in the driver. 
//
// Parameters:	context		- ID of custom context created by +createContextForTablet:type:
//									  Your application should create a context to issue 
//									  set requests. 
//

+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I
{
	NSAppleEventDescriptor  *contextDesc   = nil;
	
	// create context descriptor
	contextDesc    = [NSAppleEventDescriptor descriptorForObjectOfType:cContext 
																				  withKey:[NSAppleEventDescriptor descriptorWithUInt32:context_I]
																					ofForm:formUniqueID];
	
	return contextDesc;
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Apple Event descriptor which will send commands to a tablet 
//					control object in the driver. 
//

+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I
														  control:(UInt32)control_I
													 controlType:(eAETabletControlType)controlType_I
{
	NSAppleEventDescriptor  *contextDesc   = nil;
	NSAppleEventDescriptor  *controlDesc   = nil;
	
	// create context descriptor
	contextDesc    = [self routingTableForContext:context_I];
						
	// create control descriptor whose container is contextDesc
	controlDesc    = [NSAppleEventDescriptor descriptorForObjectOfType:[self descTypeFromControlType:controlType_I]
																				  withKey:[NSAppleEventDescriptor descriptorWithUInt32:control_I]
																					ofForm:formAbsolutePosition
																					  from:contextDesc];

	return controlDesc;
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Apple Event descriptor which will send commands to a function of 
//					a tablet control object in the driver. 
//

+ (NSAppleEventDescriptor *) routingTableForContext:(UInt32)context_I
														  control:(UInt32)control_I
													 controlType:(eAETabletControlType)controlType_I
														 function:(UInt32)function_I
{
	NSAppleEventDescriptor  *controlDesc   = nil;
	NSAppleEventDescriptor  *functionDesc  = nil;
	
	// create control descriptor whose container is contextDesc
	controlDesc    = [self routingTableForContext:context_I
													  control:control_I
												 controlType:controlType_I];

	functionDesc   = [NSAppleEventDescriptor descriptorForObjectOfType:cWTDControlFunction
																				  withKey:[NSAppleEventDescriptor descriptorWithUInt32:function_I]
																					ofForm:formAbsolutePosition
																					  from:controlDesc];
	return functionDesc;
}

#pragma mark -
#pragma mark UTILITIES
#pragma mark -

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Create an autoreleased NSAppleEventDescriptor for the tablet 
//					driver which is the target of the Apple Events to be sent from 
//					this application. 
//
//	Returns:		An autoreleased NSAppleEventDescriptor representing the target 
//					tablet driver. 
//

+ (NSAppleEventDescriptor *)driverAppleEventTarget
{
	OSType tdSig = kWacomDriverSig; // this is the tablet driver's AppleEvent signature
	
	return [NSAppleEventDescriptor descriptorWithDescriptorType:typeApplSignature
																			bytes:&tdSig 
																		  length:sizeof(tdSig)];
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Utility for translate an eAETabletControlType value to AppleEvent 
//					object class ID. 
//
//	Parameters:	controlType - Type of tablet control of interest.
//
//	Returns:		AppleEvent object class ID that corresponds to the input control 
//					type. 
//

+ (DescType)descTypeFromControlType:(eAETabletControlType)controlType_I
{
	if (controlType_I == eAETouchStrip)
	{
		return cWTDTouchStrip;
	}
	else if (controlType_I == eAEExpressKey)
	{
		return cWTDExpressKey;
	}
	return cWTDTouchRing;						
}

//////////////////////////////////////////////////////////////////////////////

//
// Purpose:		Send an Apple Event to the tablet driver to resend an event. 
//
// Parameters: tabletEventType - eEventProximity, eEventPointer
//

+ (void) resendLastTabletEventOfType:(DescType)tabletEventType_I
{
	NSAppleEventDescriptor  *event      = nil;
	NSAppleEventDescriptor  *reply      = nil;
	
	// create the apple event for object count
	event = [NSAppleEventDescriptor appleEventWithEventClass:kAEWacomSuite 
																	 eventID:eSendTabletEvent 
														 targetDescriptor:[self driverAppleEventTarget]
																	returnID:kAutoGenerateReturnID 
															 transactionID:kAnyTransactionID];
						
	// set object class to tablet to indicate that we want tablet count
	[event setDescriptor:[NSAppleEventDescriptor	descriptorWithEnumCode:tabletEventType_I]
				 forKeyword:keyAEData];

	// send the event
	reply = [event sendExpectingReplyWithPriority:kAEHighPriority 
												  andTimeout:kTabletDriverAETimeout];
}

@end
