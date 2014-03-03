//
//  YSAudioVC.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioVC.h"
#import "PSAudioEditor.h"
#import "PSAudioExporter.h"
#import "Constants.h"

#define AVAILABLE_FORMATS @[@"M4A",@"AIFF",@"WAVE"]

@interface PSAudioVC () <PSAudioEditorDelegate>

@property AudioPlayerState audioPlayerState;

@property (weak,nonatomic) IBOutlet NSButton * deleteSelectionButton;
@property (weak,nonatomic) IBOutlet NSButton * stopButton;
@property (weak,nonatomic) IBOutlet NSButton * exportButton;
@property (weak,nonatomic) IBOutlet NSButton * playButton;
@property (weak) IBOutlet NSButton *redoButton;
@property (weak) IBOutlet NSButton *undoButton;

@property (weak,nonatomic) IBOutlet NSPopUpButton * formatsPopUp;
@property (weak,nonatomic) IBOutlet NSTextField * durationTextField;
@property (weak,nonatomic) IBOutlet NSTextField * currentTimeTextField;
@property (weak,nonatomic) IBOutlet NSSlider * punchInSlider;
@property (weak,nonatomic) IBOutlet NSSlider * punchOutSlider;
@property (weak,nonatomic) IBOutlet NSSlider * seekSlider;
@property (strong, nonatomic) PSAudioEditor * audioEditor;
@property (strong, nonatomic) PSAudioExporter * audioExporter;
@property (strong,nonatomic) NSString * fileType;
@property (strong,nonatomic) NSString * fileExtension;

@property (nonatomic) float punchInValue;
@property (nonatomic) float punchOutValue;

@end

@implementation PSAudioVC

#pragma mark - init, view, and accessor methods

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        
        
    }
    return self;
}

- (void) loadView {
    [super loadView];
    [self viewDidLoad];
}

- (void) viewDidLoad
{
  
    [self.formatsPopUp addItemsWithTitles:AVAILABLE_FORMATS];
    self.fileType = [self fileTypeForIndex:0];
    self.fileExtension = [EXTENSIONS objectAtIndex:0];
    self.punchInValue = 0.0;
    self.punchOutValue = 1.0;
  self.audioPlayerState = kAudioPlayerNoFile;
  [self updatePlayerButtonStatus];
  [self updateUndoAndRedoStatus];
    
}

- (PSAudioEditor *)audioEditor
{
    if (!_audioEditor) {
        _audioEditor = [[PSAudioEditor alloc] init];
        _audioEditor.delegate = self;
    }
    return _audioEditor;
}

-(void)updatePlayerButtonStatus {
  switch (self.audioPlayerState) {
    case kAudioPlayerNoFile:
      [self.playButton setEnabled:NO];
      [self.playButton setTitle:@"Play"];
      [self.stopButton setEnabled:NO];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:NO];
      break;
    case kAudioPlayerStopped:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Play"];
      [self.stopButton setEnabled:NO];
      [self.deleteSelectionButton setEnabled:YES];
      [self.exportButton setEnabled:YES];
      break;
    case kAudioPlayerPlaying:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Pause"];
      [self.stopButton setEnabled:YES];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:NO];
      break;
    case kAudioPlayerPaused:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Unpause"];
      [self.stopButton setEnabled:YES];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:NO];
      break;
  }
}

-(void)updateUndoAndRedoStatus {
  if ([self.audioEditor.undoManager canUndo]) {
    [self.undoButton setEnabled:YES];
  } else {
    [self.undoButton setEnabled:NO];
  }
  if ([self.audioEditor.undoManager canRedo]) {
    [self.redoButton setEnabled:YES];
  } else {
    [self.redoButton setEnabled:NO];
  }
}

#pragma mark - player methods

- (IBAction)loadPressed:(NSButton *)sender {
    NSString *soundFilePath = [[self docsPath] stringByAppendingPathComponent:@"Stravinsky.m4a"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSLog(@"%@", soundFileURL);
    [self.audioEditor loadFile:soundFileURL completion:^(BOOL success) {
      [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
      self.audioPlayerState = kAudioPlayerStopped;
      [self updatePlayerButtonStatus];
    }];
}

- (IBAction)playPressed:(id)sender {
    if ([self.audioEditor isPlaying]) {
        [self.audioEditor pause];
      self.audioPlayerState = kAudioPlayerPaused;
    } else {
        [self.audioEditor play];
        [self.stopButton setEnabled:YES];
      self.audioPlayerState = kAudioPlayerPlaying;
    }
  [self updatePlayerButtonStatus];
}

- (IBAction)stopPressed:(id)sender {
  [self.audioEditor stop];
  self.audioPlayerState = kAudioPlayerStopped;
  [self updatePlayerButtonStatus];
}

- (void) playerDidFinishPLaying
{
  self.audioPlayerState = kAudioPlayerStopped;
  [self updatePlayerButtonStatus];
}

#pragma mark - change state methods

- (IBAction)deletePressed:(id)sender {
  
  [self.audioEditor deleteAudioFrom:self.punchInValue to:self.punchOutValue];
  [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
  [self updateUndoAndRedoStatus];
}

- (IBAction)export:(id)sender {
    NSInteger randomNumber = arc4random() % 1000;
    NSString * fileName = [NSString stringWithFormat:@"export-%ld%@",(long)randomNumber,self.fileExtension];
    NSURL * URL = [NSURL fileURLWithPath:[[self docsPath] stringByAppendingPathComponent:fileName]];
    self.audioExporter = [[PSAudioExporter alloc] initWithAsset:self.audioEditor.composition
                                                         andURL:URL
                                                    andFileType:self.fileType];
}

#pragma mark - undo and redo methods

-(IBAction)redoLastUndo:(id)sender {
  [self.audioEditor redoLatestUndoWithCompletion:^(BOOL success) {
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
    [self updateUndoAndRedoStatus];
  }];
}

-(IBAction)undoLastChange:(id)sender {
  [self.audioEditor undoLatestOperationWithCompletion:^(BOOL success) {
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
    [self updateUndoAndRedoStatus];
  }];
}

#pragma mark - slider and popup change methods

- (IBAction)seekSliderChangedValue:(NSSlider *)sender {
  [self.audioEditor seekToTime:sender.floatValue];
}

- (IBAction)punchInSliderChangedValue:(NSSlider *)sender
{
    self.punchInValue = sender.floatValue;
}

- (IBAction)punchOutSliderChangedValue:(NSSlider *)sender
{
    self.punchOutValue = sender.floatValue;
}

- (IBAction)formatChangedValue:(NSPopUpButton *)sender
{
  NSInteger index = [sender indexOfSelectedItem];
  self.fileType = [self fileTypeForIndex: index];
  self.fileExtension = [EXTENSIONS objectAtIndex:index];
}

#pragma mark - file helper methods

- (NSString *) fileTypeForIndex:(NSInteger) index
{
    NSString * formatKey = [AVAILABLE_FORMATS objectAtIndex:index];
    NSDictionary * formatsDict = AVAILABLE_FORMATS_DICT;
    return  [formatsDict valueForKey:formatKey];
}

- (void) updateCurrentTime:(NSString *)currentTime andFloat:(float)value
{
    [self.currentTimeTextField setStringValue:currentTime];
    [self.seekSlider setFloatValue:value];
}

- (NSString *) docsPath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = dirPaths[0];
    return [path stringByAppendingPathComponent:@"AudioPeeps"];
}



@end
