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

@property (weak,nonatomic) IBOutlet NSButton * deleteSelectionButton;
@property (weak,nonatomic) IBOutlet NSButton * stopButton;
@property (weak,nonatomic) IBOutlet NSButton * exportButton;
@property (weak,nonatomic) IBOutlet NSButton * playButton;
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
    
}

- (PSAudioEditor *)audioEditor
{
    if (!_audioEditor) {
        _audioEditor = [[PSAudioEditor alloc] init];
        _audioEditor.delegate = self;
    }
    return _audioEditor;
}

- (IBAction)loadPressed:(NSButton *)sender {
    
    
    // Create the File Open Dialog class.
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setAllowsMultipleSelection:NO];
    
    [openDlg setAllowedFileTypes:@[AVFileTypeAppleM4A, AVFileTypeAIFF, AVFileTypeWAVE]];
    
    // Enable the selection of files in the dialog.
    [openDlg setCanChooseFiles:YES];
    
    // Enable the selection of directories in the dialog.
    [openDlg setCanChooseDirectories:NO];
    
    // Display the dialog.  If the OK button was pressed,
    // process the files.
    [openDlg beginWithCompletionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton) {
            
            NSURL *soundFileURL = [openDlg URL];
            
            NSLog(@"%@", soundFileURL);
            [self.audioEditor loadFile:soundFileURL completion:^(BOOL success) {
                [self.playButton setEnabled:YES];
                [self.deleteSelectionButton setEnabled:YES];
                [self.exportButton setEnabled:YES];
                [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
            }];
        } else {
            return;
        }
    }];
}

- (IBAction)playPressed:(id)sender {
    
    if ([self.audioEditor isPlaying]) {
        [self.audioEditor pause];
        [self.playButton setTitle:@"Play"];
        [self.stopButton setEnabled:NO];
    } else {
        [self.audioEditor play];
        [self.stopButton setEnabled:YES];
        [self.playButton setTitle:@"Pause"];
    }
    
}

- (IBAction)deletePressed:(id)sender {
    
    [self.audioEditor deleteAudioFrom:self.punchInValue to:self.punchOutValue];
    [self.exportButton setEnabled:YES];
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
}

- (IBAction)stopPressed:(id)sender {
    
    [self.audioEditor stop];
    [self.stopButton setEnabled:NO];
    [self.playButton setTitle:@"Play"];
}

- (IBAction)export:(id)sender {
    
    
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
                                                            andFileType:self.fileType];
            
            
        } else {
            return;
        }
    }];

    
    
    
    
    
}

- (IBAction)formatChangedValue:(NSPopUpButton *)sender
{
    NSInteger index = [sender indexOfSelectedItem];
    self.fileType = [self fileTypeForIndex: index];
    self.fileExtension = [EXTENSIONS objectAtIndex:index];
}
-(IBAction)undoLastChange:(NSButton *)sender {
  [self.audioEditor undoLatestOperationWithCompletion:^(BOOL success) {
    [self.durationTextField setStringValue:[self.audioEditor fileDuration]];
  }];
}

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

- (void) playerDidFinishPLaying
{
    [self.stopButton setEnabled:NO];
    [self.playButton setTitle:@"Play"];
}


- (NSString *) docsPath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = dirPaths[0];
    return [path stringByAppendingPathComponent:@"AudioPeeps"];
}



@end
