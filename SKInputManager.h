//
//  SKInputManager.h
//  OfficeAttacks
//
//  Created by Steve Kanter on 12/8/11.
//  Copyright (c) 2011 Steve Kanter. All rights reserved.
//

/** This object is the basic object that the SKInputManager class deals with.  For each object that is to be handled, one of these is created and used for input forwarding as well as prioritizing. */

@interface SKInputManagerHandler : NSObject {
@private
	id nodeObject;
	int priority;
	SKInputHandlerBlock inputBeganBlock;
	SKInputHandlerBlock inputMovedBlock;
	SKInputHandlerBlock inputEndedBlock;
	SKInputHandlerBlock inputCancelledBlock;
	
	SKInputHandlerBlock mouseMovedBlock;
}

/**
 @name Required Properties
 */

/** The object which is being handled, such as the "button" object. */
@property(nonatomic, readwrite, strong) id nodeObject;

/** The priority of the object to get the input.  Higher priority is pinged first as to whether or not they want the input. */
@property(nonatomic, readwrite, assign) int priority;


/**
 @name Optional input blocks
 */

/** The block to be called when input begins.
 @warning *Note:* if set, this block is called as WELL as the input methods on the object. */
@property(nonatomic, readwrite, copy, setter=setInputBeganBlock:) SKInputHandlerBlock inputBeganBlock;
/** The block to be called when input moves.
 @warning *Note:* if set, this block is called as WELL as the input methods on the object. */
@property(nonatomic, readwrite, copy, setter=setInputMovedBlock:) SKInputHandlerBlock inputMovedBlock;
/** The block to be called when input ends.
 @warning *Note:* if set, this block is called as WELL as the input methods on the object. */
@property(nonatomic, readwrite, copy, setter=setInputEndedBlock:) SKInputHandlerBlock inputEndedBlock;
/** The block to be called when input cancelles.
 @warning *Note:* if set, this block is called as WELL as the input methods on the object. */
@property(nonatomic, readwrite, copy, setter=setInputCancelledBlock:) SKInputHandlerBlock inputCancelledBlock;

/** The block to be called when the mouse moves.  Set a block here and you will be called every time the mouse moves.
 @warning *Warning:* this is ONLY ever called *_on Mac_*.  It has no effect on iOS. */
@property(nonatomic, readwrite, copy, setter=setMouseMovedBlock:) SKInputHandlerBlock mouseMovedBlock;

/** Call this to release and zero out all the properties on this handler object.
 @bug *Warning:*  do not call if the handler is still registered on the SKInputManager. */
-(void) resetHandler;
@end


/** Basic manager for handling touches and clicks. */
@interface SKInputManager : SKSingleton

/** Enable this property when you're adding a large quantity of touch handlers at once. **When this property is set back to NO, the handlers are once again, resorted and ready to handle input.**
 @warning __*NOTE!*__  if this property is set to YES, any input that comes in before it's set back to NO will **NOT** test against any handlers added while YES. */
@property(nonatomic, readwrite, assign) BOOL disableReSortingOfHandlers;

/** Shared instance of the input manager */
+(SKInputManager *) sharedInputManager;
/** Remove handler from the manager.
 @param obj the object to remove */
-(void) removeHandler:(id)obj;
/** Remove all handlers from the manager.*/
-(void) removeAllHandlers;
/** Add handler to the manager with a specific priority.  If this handler is already registered, it will simply update the priority.
 @param obj the object to remove
 @param priority priority of this object to get called with the input.  Highest gets it first.  Set to -1 for the highest.
 @returns the handler object created for this node */
-(SKInputManagerHandler *) addHandler:(id<SKKitInput>)obj withPriority:(int)priority;
/** Touches and clicks are sent to this method when they begin.  Generally ,you don't call this method directly.  If using an SKCCLayer or a SKCCLayerColor, just set self.isTouchEnabled or self.isMouseEnabled to YES.
 @param input on iOS the UITouch, on Mac, nil
 @param event on iOS the UIEvent, on Mac, the NSEvent */
-(void) inputBegan:(id)input withEvent:(id)event;
/** Touches and clicks are sent to this method when they move.  Generally ,you don't call this method directly.  If using an SKCCLayer or a SKCCLayerColor, just set self.isTouchEnabled or self.isMouseEnabled to YES.
 @param input on iOS the UITouch, on Mac, nil
 @param event on iOS the UIEvent, on Mac, the NSEvent */
-(void) inputMoved:(id)input withEvent:(id)event;
/** Touches and clicks are sent to this method when they end.  Generally ,you don't call this method directly.  If using an SKCCLayer or a SKCCLayerColor, just set self.isTouchEnabled or self.isMouseEnabled to YES.
 @param input on iOS the UITouch, on Mac, nil
 @param event on iOS the UIEvent, on Mac, the NSEvent */
-(void) inputEnded:(id)input withEvent:(id)event;
/** Touches and clicks are sent to this method when they are cancelled.  Generally ,you don't call this method directly.  If using an SKCCLayer or a SKCCLayerColor, just set self.isTouchEnabled or self.isMouseEnabled to YES.
 @param input on iOS the UITouch, on Mac, nil
 @param event on iOS the UIEvent, on Mac, the NSEvent */
-(void) inputCancelled:(id)input withEvent:(id)event;
/** Mouse moves without mouse down are sent to this method.  They are then sent to any handler that specifically requests to be told when the mouse moves.  There is no corresponding node call, only a block callback.  Generally, you don't call this method directly.  If using an SKCCLayer or a SKCCLayerColor, just set self.isMouseEnabled to YES.
 @param event the NSEvent
 @warning *Warning* This is _*Mac Only*_.  This method has no effect on iOS
 @bug *Requires setting setAcceptsMouseMovedEvents: on the window.**/
-(void) mouseMovedWithEvent:(id)event;
/** Whether or not the specified handler is registered with the input manager
 @param handler handler in question
 @returns whether or not the handler is registered */
-(BOOL) handlerIsRegistered:(id)handler;
/** Get the handler object for the node
 @param node node to get the handler for
 @returns the handler object created for this node */
-(SKInputManagerHandler *) handlerObjectForNode:(id)node;


@property(nonatomic, readwrite) BOOL inputEnabled;

@end