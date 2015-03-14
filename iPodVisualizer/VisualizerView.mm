//
//  VisualizerView.m
//  iPodVisualizer
//
//  Created by Xinrong Guo on 13-3-30.
//  Copyright (c) 2013 Xinrong Guo. All rights reserved.
//

#import "VisualizerView.h"
#import <QuartzCore/QuartzCore.h>
#import "MeterTable.h"

@implementation VisualizerView {
  MeterTable meterTable;
    CBCentralManager *centralManager;
    CBPeripheral *targetperipheral;
    CBCharacteristic *targetcharacteristic;
    NSTimeInterval pretime;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    [self setBackgroundColor:[UIColor blackColor]];
    CADisplayLink *dpLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(update)];
    [dpLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
  }
    
    targetperipheral = nil;
    targetcharacteristic = nil;
    centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
  return self;
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"State Updated %ld", central.state);
    if(central.state == CBCentralManagerStatePoweredOn){
        NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                            forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
        [centralManager scanForPeripheralsWithServices:nil options:options];
    }
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    targetperipheral = peripheral;
    peripheral.delegate = self;
    NSLog(@"didDiscoverPeripheral %@", peripheral.name);
    if (!peripheral.isConnected && [peripheral.name compare:@"Otosam"] == NSOrderedSame){
        [centralManager connectPeripheral:peripheral options:nil];
    }
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"didConnectPeripheral %@", peripheral.name);
    [peripheral discoverServices:nil];
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services){
        NSLog(@"didDiscoverServices %@", service.UUID);
        if ([service.UUID isEqual:[CBUUID UUIDWithString:@"1B7E8251-2877-41C3-B46E-CF057C562023"]]){
            NSLog(@"Found Service");
            [peripheral discoverCharacteristics:nil forService:service];
        }
    }
}
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        NSLog(@"didDiscoverCharacteristicsForService %@", characteristic.UUID);
        if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"5E9BF2A8-F93F-4481-A67E-3B2F4A07891A"]]){
            NSLog(@"Found Characteristic");
            targetcharacteristic = characteristic;
            pretime =  [NSDate timeIntervalSinceReferenceDate];
        }
    }
}

- (void)update
{
  static float h = 0.0;
  float s = 1.0, v = 0.0;
  h += 0.001;
    if(h > 1.0)h -= 1.0;
  if (_audioPlayer.playing )
  {
    [_audioPlayer updateMeters];
    
    float power = 0.0f;
    for (int i = 0; i < [_audioPlayer numberOfChannels]; i++) {
      power += [_audioPlayer averagePowerForChannel:i];
    }
    power /= [_audioPlayer numberOfChannels];
    
    float level = meterTable.ValueAt(power);
      v = 0.1 + 0.9*(level * level * level);
  }
    
    // (float h, float s, float v)
    float r = v;
    float g = v;
    float b = v;
    if (s > 0.0f) {
        int i = (int) (h*6.0f)%6;
        float f = (h*6.0f) - (float) i;
        switch (i) {
            default:
            case 0:
                g *= 1 - s * (1 - f);
                b *= 1 - s;
                break;
            case 1:
                r *= 1 - s * f;
                b *= 1 - s;
                break;
            case 2:
                r *= 1 - s;
                b *= 1 - s * (1 - f);
                break;
            case 3:
                r *= 1 - s;
                g *= 1 - s * f;
                break;
            case 4:
                r *= 1 - s * (1 - f);
                g *= 1 - s;
                break;
            case 5:
                g *= 1 - s;
                b *= 1 - s * f;
                break;
        }
    }
    [self setBackgroundColor:[UIColor colorWithRed:r green:g blue:b alpha:1.0]];
    NSTimeInterval nowtime = [NSDate timeIntervalSinceReferenceDate];
    if(nowtime - pretime > 0.2){
        if(targetcharacteristic && targetperipheral.isConnected) {
            unsigned char data[18] = {0};
            for(int i = 0; i < 18; i+= 3){
                data [i + 0] = r * 255;
                data [i + 1] = g * 255;
                data [i + 2] = b * 255;
            }
            [targetperipheral writeValue:[NSData dataWithBytes:data length:18] forCharacteristic:targetcharacteristic type:CBCharacteristicWriteWithResponse];
        }
        pretime = nowtime;
    }
}

@end