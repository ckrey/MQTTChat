
//
//  ViewController.m
//  MQTTChat
//
//  Created by Christoph Krey on 12.07.15.
//  Copyright (c) 2015 Owntracks. All rights reserved.
//

#import "ViewController.h"
#import "ChatCell.h"

@interface ViewController ()
/*
 * MQTTClient: keep a strong reference to your MQTTSessionManager here
 */
@property (strong, nonatomic) MQTTSessionManager *manager;


@property (strong, nonatomic) NSDictionary *mqttSettings;
@property (strong, nonatomic) NSMutableArray *chat;
@property (weak, nonatomic) IBOutlet UILabel *status;
@property (weak, nonatomic) IBOutlet UITextField *message;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSString *base;
@property (weak, nonatomic) IBOutlet UIButton *reconnect;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
    NSURL *mqttPlistUrl = [bundleURL URLByAppendingPathComponent:@"mqtt.plist"];
    self.mqttSettings = [NSDictionary dictionaryWithContentsOfURL:mqttPlistUrl];
    self.base = self.mqttSettings[@"base"];
    
    self.chat = [[NSMutableArray alloc] init];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 150;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.message.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    /*
     * MQTTClient: create an instance of MQTTSessionManager once and connect
     * will is set to let the broker indicate to other subscribers if the connection is lost
     */
    if (!self.manager) {
        self.manager = [[MQTTSessionManager alloc] init];
        self.manager.delegate = self;
        self.manager.subscriptions = [[NSMutableDictionary alloc] init];
        [self.manager.subscriptions setObject:[NSNumber numberWithInt:MQTTQosLevelExactlyOnce]
                                       forKey:[NSString stringWithFormat:@"%@/#", self.base]];
        [self.manager connectTo:self.mqttSettings[@"host"]
                           port:[self.mqttSettings[@"port"] intValue]
                            tls:[self.mqttSettings[@"tls"] boolValue]
                      keepalive:60
                          clean:true
                           auth:false
                           user:nil
                           pass:nil
                      willTopic:[NSString stringWithFormat:@"%@/%@", self.base, [UIDevice currentDevice].name]
                           will:[@"offline" dataUsingEncoding:NSUTF8StringEncoding]
                        willQos:MQTTQosLevelExactlyOnce
                 willRetainFlag:true
                   withClientId:[UIDevice currentDevice].name];
    } else {
        [self.manager connectToLast];
    }
    
    /*
     * MQTTCLient: observe the MQTTSessionManager's state to display the connection status
     */
    
    [self.manager addObserver:self
                   forKeyPath:@"state"
                      options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                      context:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.manager disconnect];
    [self.manager removeObserver:self forKeyPath:@"state"];
    [super viewWillDisappear:animated];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    switch (self.manager.state) {
        case MQTTSessionManagerStateClosed:
            self.status.text = @"closed";
            [self.reconnect setTitle:@"wait" forState:UIControlStateNormal];
            break;
        case MQTTSessionManagerStateClosing:
            self.status.text = @"closing";
            [self.reconnect setTitle:@"wait" forState:UIControlStateNormal];
            break;
        case MQTTSessionManagerStateConnected:
            self.status.text = [NSString stringWithFormat:@"connected as %@", [UIDevice currentDevice].name];
           [self.reconnect setTitle:@"disconnect" forState:UIControlStateNormal];
            [self.manager sendData:[@"joins chat" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:[NSString stringWithFormat:@"%@/%@", self.base, [UIDevice currentDevice].name]
             
                               qos:MQTTQosLevelExactlyOnce
                            retain:TRUE];

            break;
        case MQTTSessionManagerStateConnecting:
            self.status.text = @"connecting";
            [self.reconnect setTitle:@"wait" forState:UIControlStateNormal];
            break;
        case MQTTSessionManagerStateError:
            self.status.text = @"error";
            [self.reconnect setTitle:@"connect" forState:UIControlStateNormal];
            break;
        case MQTTSessionManagerStateStarting:
        default:
            self.status.text = @"not connected";
            [self.reconnect setTitle:@"connect" forState:UIControlStateNormal];
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void) animateTextField: (UITextField*) textField up: (BOOL) up {
    const int movementDistance = textField.frame.size.height + 224;
    const float movementDuration = 0.3f;
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"message" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self animateTextField: textField up: YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self animateTextField: textField up: NO];
}


- (IBAction)clear:(id)sender {
    [self.chat removeAllObjects];
    [self.tableView reloadData];
}

- (IBAction)reconnect:(id)sender {
    switch (self.manager.state) {
        case MQTTSessionManagerStateConnected:
            /*
             * MQTTClient: send goodby message and gracefully disconnect
             */
            
            [self.manager sendData:[@"leaves chat" dataUsingEncoding:NSUTF8StringEncoding]
                             topic:[NSString stringWithFormat:@"%@/%@", self.base, [UIDevice currentDevice].name]
             
                               qos:MQTTQosLevelExactlyOnce
                            retain:TRUE];
            [self.manager disconnect];
            break;
        case MQTTSessionManagerStateStarting:
            /*
             * MQTTClient: connect to same broker again
             */
            
            [self.manager connectToLast];
            break;
        case MQTTSessionManagerStateConnecting:
        case MQTTSessionManagerStateClosed:
        case MQTTSessionManagerStateClosing:
        case MQTTSessionManagerStateError:
        default:
            //
            break;
    }
}

- (IBAction)send:(id)sender {
    /*
     * MQTTClient: send data to broker
     */
    
    [self.manager sendData:[self.message.text dataUsingEncoding:NSUTF8StringEncoding]
                     topic:[NSString stringWithFormat:@"%@/%@", self.base, [UIDevice currentDevice].name]

                       qos:MQTTQosLevelExactlyOnce
                    retain:TRUE];
}

/*
 * MQTTSessionManagerDelegate
 */
- (void)handleMessage:(NSData *)data onTopic:(NSString *)topic retained:(BOOL)retained {
    /*
     * MQTTClient: process received message
     */
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *senderString = [topic substringFromIndex:self.base.length + 1];
    
    [self.chat insertObject:[NSString stringWithFormat:@"%@: %@", senderString, dataString] atIndex:0];
    [self.tableView reloadData];
}

/*
 * UITableViewDelegate
 */
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ChatCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"line"];
    cell.textView.text = self.chat[indexPath.row];
    return cell;
}

/*
 * UITableViewDataSource
 */

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.chat.count;
}

@end
