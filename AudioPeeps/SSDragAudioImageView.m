//
//  SSDragAudioImageView.m
//  Popsicl
//
//  Created by Stevenson on 3/3/14.
//  Copyright (c) 2014 Pretty Great. All rights reserved.
//

#import "SSDragAudioImageView.h"

@implementation SSDragAudioImageView

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
    //to get path of the dragged file
//    NSPasteboardItem *draggedItem = [[[sender draggingPasteboard] pasteboardItems] objectAtIndex:0];
//    NSString *type = [draggedItem types][0];
//    
//    NSLog(@"object type: %@",type);
//    NSLog(@"object stringForType: %@",[draggedItem stringForType:type]);
    
    BOOL allowDrop = [self.draggingDelegate allowDragglableFile:sender];
    if (allowDrop) {
        return NSDragOperationCopy;
    } else {
        return NSDragOperationNone;
    }
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
    [self.draggingDelegate didDropFile:sender];
    return YES;
}

@end
