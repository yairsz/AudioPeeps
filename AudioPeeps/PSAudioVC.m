//
//  YSAudioVC.m
//  AudioPeeps
//
//  Created by Yair Szarf on 2/23/14.
//  Copyright (c) 2014 The 2 Handed Consortium. All rights reserved.
//

#import "PSAudioVC.h"

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

@property (strong, nonatomic) NSMenu *editSubMenu;
@property (strong, nonatomic) NSMenuItem *redoItem;
@property (strong, nonatomic) NSMenuItem *undoItem;

@property (weak) IBOutlet NSButton *mixInput1;
@property (weak) IBOutlet NSButton *mixInput2;
@property (weak) IBOutlet NSButton *mixInput3;
@property (weak) IBOutlet NSButton *mixInput4;
@property (weak) IBOutlet NSButton *mixInput5;

@property (weak,nonatomic) IBOutlet NSPopUpButton * formatsPopUp;
@property (weak,nonatomic) IBOutlet NSTextField * durationTextField;
@property (weak,nonatomic) IBOutlet NSTextField * currentTimeTextField;
@property (weak,nonatomic) IBOutlet NSSlider * punchInSlider;
@property (weak,nonatomic) IBOutlet NSSlider * punchOutSlider;
@property (weak,nonatomic) IBOutlet NSSlider * seekSlider;
@property (weak,nonatomic) IBOutlet SSDragAudioImageView * introWell;
@property (weak,nonatomic) IBOutlet SSDragAudioImageView * outroWell;

@property (strong, nonatomic) NSArray *metadataArray;

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
    self.introWell.draggingDelegate = self;
    self.outroWell.draggingDelegate = self;
  
    [self assignPointersToMenuItems];
  
    [self.formatsPopUp addItemsWithTitles:AVAILABLE_FORMATS];
    self.fileType = [self fileTypeForIndex:0];
    self.fileExtension = [EXTENSIONS objectAtIndex:0];
    self.punchInValue = 0.0;
    self.punchOutValue = 1.0;
    
    self.audioPlayerState = kAudioPlayerNoFile;
    [self updatePlayerButtonStatus];
  [self updateMixInputButtons];
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

-(void)mixButtonsEnabled:(BOOL)enabler {
  if (enabler == YES) {
    [self.mixInput1 setEnabled:YES];
    [self.mixInput2 setEnabled:YES];
    [self.mixInput3 setEnabled:YES];
    [self.mixInput4 setEnabled:YES];
    [self.mixInput5 setEnabled:YES];
  } else {
    [self.mixInput1 setEnabled:NO];
    [self.mixInput2 setEnabled:NO];
    [self.mixInput3 setEnabled:NO];
    [self.mixInput4 setEnabled:NO];
    [self.mixInput5 setEnabled:NO];
  }
}

-(void)updatePlayerButtonStatus {
    
  switch (self.audioPlayerState) {
    case kAudioPlayerNoFile:
      [self.playButton setEnabled:NO];
      [self.playButton setTitle:@"Play"];
      [self.stopButton setEnabled:NO];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:NO];
      [self mixButtonsEnabled:NO];
      break;
    case kAudioPlayerStopped:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Play"];
      [self.stopButton setEnabled:NO];
      [self.deleteSelectionButton setEnabled:YES];
      [self.exportButton setEnabled:YES];
      [self mixButtonsEnabled:YES];
      break;
    case kAudioPlayerPlaying:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Pause"];
      [self.stopButton setEnabled:YES];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:NO];
      [self mixButtonsEnabled:YES];
      break;
    case kAudioPlayerPaused:
      [self.playButton setEnabled:YES];
      [self.playButton setTitle:@"Play"];
      [self.stopButton setEnabled:YES];
      [self.deleteSelectionButton setEnabled:NO];
      [self.exportButton setEnabled:YES];
      [self mixButtonsEnabled:YES];
      break;
  }
}

-(void)updateMixInputButtons {
  if (self.audioEditor.mixInputParameter1On) {
    [self.mixInput1 setTitle:@"1 on"];
  } else {
    [self.mixInput1 setTitle:@"1 off"];
  }
  if (self.audioEditor.mixInputParameter2On) {
    [self.mixInput2 setTitle:@"2 on"];
  } else {
    [self.mixInput2 setTitle:@"2 off"];
  }
  if (self.audioEditor.mixInputParameter3On) {
    [self.mixInput3 setTitle:@"3 on"];
  } else {
    [self.mixInput3 setTitle:@"3 off"];
  }
  if (self.audioEditor.mixInputParameter4On) {
    [self.mixInput4 setTitle:@"4 on"];
  } else {
    [self.mixInput4 setTitle:@"4 off"];
  }
  if (self.audioEditor.mixInputParameter5On) {
    [self.mixInput5 setTitle:@"5 on"];
  } else {
    [self.mixInput5 setTitle:@"5 off"];
  }
}

-(void)updateUndoAndRedoStatus {
  if ([self.audioEditor.undoManager canUndo]) {
    [self.undoButton setEnabled:YES];
    [self.undoItem setEnabled:YES];
  } else {
    [self.undoButton setEnabled:NO];
    [self.undoItem setEnabled:NO];
  }
  if ([self.audioEditor.undoManager canRedo]) {
    [self.redoButton setEnabled:YES];
    [self.redoItem setEnabled:YES];
  } else {
    [self.redoButton setEnabled:NO];
    [self.redoItem setEnabled:NO];
  }
}

#pragma mark - player methods

- (IBAction)loadPressed:(NSButton *)sender {

    
    
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowsMultipleSelection:NO];
    
    [openDlg setAllowedFileTypes:@[AVFileTypeAppleM4A, AVFileTypeAIFF, AVFileTypeAIFC, AVFileTypeWAVE]];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Enable the selection of directories in the dialog.
    [openDlg setCanChooseDirectories:NO];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSURL *soundFileURL = [openDlg URL];
            
            NSLog(@"sound file URL %@", soundFileURL);
            [self.audioEditor loadFile:soundFileURL completion:^(BOOL success) {
                [self.playButton setEnabled:YES];
                [self.deleteSelectionButton setEnabled:YES];
                [self.exportButton setEnabled:YES];
                [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
                self.audioPlayerState = kAudioPlayerStopped;
                [self updatePlayerButtonStatus];
              [self updateUndoAndRedoStatus];
              [self updateMixInputButtons];
                }];
        } else {
            return;
        }

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

- (IBAction)mixInputButtonPressed:(id)sender {
  MixInputNumber inputNumber;
  if ([[sender identifier] isEqualToString:@"mixInput1"]) {
    inputNumber = kMixInput1;
  } else if ([[sender identifier] isEqualToString:@"mixInput2"]) {
    inputNumber = kMixInput2;
  } else if ([[sender identifier] isEqualToString:@"mixInput3"]) {
    inputNumber = kMixInput3;
  } else if ([[sender identifier] isEqualToString:@"mixInput4"]) {
    inputNumber = kMixInput4;
  } else if ([[sender identifier] isEqualToString:@"mixInput5"]) {
    inputNumber = kMixInput5;
  } else {
    return;
  }
  [self.audioEditor toggleMixInput:inputNumber WithCompletion:^(BOOL success) {
    [self updateMixInputButtons];
  }];
}

#pragma mark - change state methods

- (IBAction)deletePressed:(id)sender {
  
  [self.audioEditor deleteAudioFrom:self.punchInValue to:self.punchOutValue];
  [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
  [self updateUndoAndRedoStatus];
}

- (IBAction)cut:(id)sender
{
    [self.audioEditor cutAudioFrom:self.punchInValue to:self.punchOutValue];
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
    [self updateUndoAndRedoStatus];
}
- (IBAction)copy:(id)sender
{
    [self.audioEditor copyAudioFrom:self.punchInValue to:self.punchOutValue];
    [self updateUndoAndRedoStatus];
}
- (IBAction)paste:(id)sender
{
    [self.audioEditor pasteAudioAt:self.punchInValue];
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
    [self updateUndoAndRedoStatus];
}

- (IBAction)export:(id)sender {
    
    // temporarily get metadata from hard coded info
  [self populateMetadata];
  
    // Create the File Open Dialog class.
    NSSavePanel* saveDlg = [NSSavePanel savePanel];
    NSInteger randomNumber = arc4random() % 1000;
  
    NSString * fileName = [NSString stringWithFormat:@"ExportAudio-%ld%@",randomNumber,self.fileExtension];
    [saveDlg setNameFieldStringValue:fileName];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    [saveDlg beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
          
            NSURL * URL = [saveDlg URL];
            self.audioExporter = [[PSAudioExporter alloc] initWithAsset:self.audioEditor.composition
                                                                 andURL:URL
                                                            andFileType:self.fileType
                                                            andAudioMix:self.audioEditor.audioMix
                                                       andMetadataArray:self.metadataArray];
        } else {
            return;
        }
    }];
}

-(void)populateMetadata {

  AVMutableMetadataItem *artistItem = [AVMutableMetadataItem metadataItem];
  AVMutableMetadataItem *albumItem = [AVMutableMetadataItem metadataItem];
  AVMutableMetadataItem *titleItem = [AVMutableMetadataItem metadataItem];
  
  artistItem.keySpace = AVMetadataKeySpaceCommon;
  albumItem.keySpace = AVMetadataKeySpaceCommon;
  titleItem.keySpace = AVMetadataKeySpaceCommon;
  
  artistItem.key = AVMetadataCommonKeyArtist;
  albumItem.key = AVMetadataCommonKeyAlbumName;
  titleItem.key = AVMetadataCommonKeyTitle;
  
  artistItem.value = @"Mr. Podcaster";
  albumItem.value = @"My podcast album";
  titleItem.value = @"Podcast numero uno";
  
  NSMutableArray *tempArray = [NSMutableArray new];
  [tempArray addObject:artistItem];
  [tempArray addObject:albumItem];
  [tempArray addObject:titleItem];
  self.metadataArray = [NSArray arrayWithArray:tempArray];
  
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
    if (![self.seekSlider.cell isHighlighted]) {
        self.playTime = value;
    }
}

- (NSString *) docsPath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = dirPaths[0];
    return [path stringByAppendingPathComponent:@"AudioPeeps"];
}

- (BOOL) allowDragglableFile:(id<NSDraggingInfo>)sender {
    
    NSPasteboardItem *draggedItem = [[[sender draggingPasteboard] pasteboardItems] objectAtIndex:0];
    NSString *type = [draggedItem types][0];
    NSURL * fileURL = [NSURL URLWithString:[draggedItem stringForType:type]];
    
    id resourceValue;
    [fileURL getResourceValue: &resourceValue
                       forKey: NSURLTypeIdentifierKey
                        error: nil];
    
    NSArray * fileTypes = [TYPES_DICT allKeys];
    
    if ([fileTypes containsObject:resourceValue]){
        return YES;
    } else {
        return NO;
    }
    
}

- (BOOL) didDropFile:(id<NSDraggingInfo>)sender
{
    NSPasteboardItem *draggedItem = [[[sender draggingPasteboard] pasteboardItems] objectAtIndex:0];
    NSString *type = [draggedItem types][0];
    NSURL * fileURL = [NSURL URLWithString:[draggedItem stringForType:type]];
    
    NSPoint dragPoint =[sender draggingLocation];
    if (dragPoint.x < self.view.frame.size.width/2) {
        [self.audioEditor loadIntro:fileURL completion:^(BOOL success) {
            [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
        }];
    } else {
        [self.audioEditor loadOutro:fileURL completion:^(BOOL success) {
            [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
        }];
    }
    return YES;
    
}

-(void)assignPointersToMenuItems {
  NSMenu *mainMenu = [[NSApplication sharedApplication] mainMenu];
  self.editSubMenu = [[mainMenu itemAtIndex:2] submenu];
  for (NSMenuItem *item in [self.editSubMenu itemArray]) {
    if ([item.title isEqualToString:@"Undo"]) {
      self.undoItem = item;
    } else if ([item.title isEqualToString:@"Redo"]) {
      self.redoItem = item;
    }
  }
}

@end
