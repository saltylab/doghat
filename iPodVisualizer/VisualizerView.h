//
//  VisualizerView.h
//  iPodVisualizer
//
//  Created by Xinrong Guo on 13-3-30.
//  Copyright (c) 2013 Xinrong Guo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface VisualizerView : UIView <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

@end
