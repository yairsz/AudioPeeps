//
//  SSDragAudioImageView.h
//  Popsicl
//
//  Created by Stevenson on 3/3/14.
//  Copyright (c) 2014 Pretty Great. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol SSDragAudioImageViewDraggingDelegate

- (BOOL)allowDragglableFile:(id<NSDraggingInfo>) sender;

- (BOOL)didDropFile:(id<NSDraggingInfo>) sender;

@end

@interface SSDragAudioImageView : NSImageView

@property (unsafe_unretained) id<SSDragAudioImageViewDraggingDelegate> draggingDelegate;

@end
