//
//  ViewController.h
//  MQTTChat
//
//  Created by Christoph Krey on 12.07.15.
//  Copyright (c) 2015 Owntracks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MQTTClient/MQTTClient.h>
#import <MQTTClient/MQTTSessionManager.h>


@interface ViewController : UIViewController <MQTTSessionManagerDelegate, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>


@end

