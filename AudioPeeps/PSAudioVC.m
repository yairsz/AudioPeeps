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
#define IN_TIME 0.1f
#define OUT_TIME 0.2f

@interface PSAudioVC ()


@property (weak,nonatomic) IBOutlet NSButton * setInButton;
@property (weak,nonatomic) IBOutlet NSButton * setOutButton;
@property (weak,nonatomic) IBOutlet NSButton * trimButton;
@property (nonatomic) int fileType;
@property (strong, nonatomic) PSAudioEditor * audioEditor;
@property (strong, nonatomic) PSAudioExporter * audioExporter;

@end

@implementation PSAudioVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
        self.fileType = PSAudioFileFormatAAC;
    }
    return self;
}

- (PSAudioEditor *)audioEditor
{
    if (!_audioEditor) {
        _audioEditor = [[PSAudioEditor alloc] init];
    }
    return _audioEditor;
}

- (IBAction)loadPressed:(NSButton *)sender {
    
    
    NSString *soundFilePath = [[self docsPath] stringByAppendingPathComponent:@"speech.aif"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSLog(@"%@", soundFileURL);
    [self.audioEditor loadFile:soundFileURL];
}

- (IBAction)playPressed:(id)sender {
    
    [self.audioEditor play];
}

- (IBAction)deletePressed:(id)sender {
    
    [self.audioEditor deleteAudioFrom:IN_TIME to:OUT_TIME];
    
}

- (IBAction)stopPressed:(id)sender {
    
    [self.audioEditor stop];
}

- (IBAction)export:(id)sender {
    
    NSURL * URL = [NSURL fileURLWithPath:[[self docsPath] stringByAppendingPathComponent:@"exportAudio.m4a"]];
    self.audioExporter = [[PSAudioExporter alloc] initWithAsset:self.audioEditor.composition
                                                         andURL:URL
                                                    andFileType:AVFileTypeAppleM4A];
}



- (NSString *) docsPath
{
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * path = dirPaths[0];
    return [path stringByAppendingPathComponent:@"AudioPeeps"];
}

@end
