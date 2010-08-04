//
//  YMSettingsViewController.m
//  Yammer
//
//  Created by Samuel Sutch on 7/15/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "YMSettingsViewController.h"
#import "YMWebService.h"


@interface FontSizeDatasource : NSObject <UITableViewDelegate, UITableViewDataSource>
{
  id<DKCallback> chooseSize;
  NSArray *fontSizes;
  int chosenIndex;
}

@property(retain) id<DKCallback> chooseSize;
@property(assign) int chosenIndex;
@property(retain) NSArray *fontSizes;

@end


@implementation YMSettingsViewController

- (void)loadView
{
  self.tableView = [[UITableView alloc] initWithFrame:
                    CGRectMake(0, 0, 320, 460) style:UITableViewStyleGrouped];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;
  self.actionTableViewHeaderClass = NULL;
  self.title = @"Settings";
//  self.useSubtitleHeader = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.tableView reloadData];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 2;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  if (section == 1) return 2;
  return 1;
}

- (UITableViewCell *) tableView:(UITableView *)tableView 
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *c = [[[UITableViewCell alloc]
                         initWithStyle:UITableViewCellStyleValue1
                         reuseIdentifier:nil] autorelease];
  if (indexPath.section == 0) {
    c.textLabel.text = @"Font Size";
    id x = PREF_KEY(@"fontsize");
    if (!x) x = nsni(13);
    c.detailTextLabel.text = [NSString stringWithFormat:@"%ipt", intv(x)];
    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  }
//  if (indexPath.section == 1) {
//    c.textLabel.text = @"Push Notifications";
//    id x = PREF_KEY(@"pushnotifications");
//    if (!x) x = nsnb(YES);
//    c.detailTextLabel.text = boolv(x) ? @"Enabled" : @"Disabled";
//    c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
//  }
  if (indexPath.section == 1) {
    if (indexPath.row == 0) {
      c.textLabel.text = [NSString stringWithFormat:@"Version"];
      c.detailTextLabel.text = [NSString stringWithFormat:@"%@", 
                           PREF_KEY(@"YMPreviousBundleVersion")];
    } else if (indexPath.row == 1) {
      c.textLabel.text = @"Send Feedback";
      c.detailTextLabel.text = @"";
      c.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  return c;
}

- (void) tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.section == 0) {
    NSArray *fontSizes = array_(nsni(11), nsni(12), nsni(13), nsni(14), 
                                nsni(15), nsni(16), nsni(17), nsni(18));
    UITableViewController *t = [[[UITableViewController alloc] initWithStyle:
                                 UITableViewStyleGrouped] autorelease];
    FontSizeDatasource *d = [[FontSizeDatasource alloc] init];
    d.fontSizes = fontSizes;
    d.chooseSize = callbackTS(self, chooseFontSize:);
    id x = PREF_KEY(@"fontsize");
    if (!x) x = nsni(13);
    d.chosenIndex = [fontSizes indexOfObject:x];
    t.title = @"Font Size";
    [self.navigationController pushViewController:t animated:YES];
    t.tableView.dataSource = d;
    t.tableView.delegate = d;
    [t.tableView reloadData];
  }
//  if (indexPath.section == 1) {
//    id x = PREF_KEY(@"pushnotifications");
//    if (!x) x = nsnb(YES);
//    if (!boolv(x)) [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
//                   (UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeBadge)];
//    else [[YMWebService sharedWebService] setPushID:@""];
//    PREF_SET(@"pushnotifications", nsnb((!boolv(x))));
//    [self.tableView reloadData];
//  }
  if (indexPath.section == 1 && indexPath.row == 1) {
    MFMailComposeViewController *v = [[[MFMailComposeViewController alloc] 
                                       init] autorelease];
    v.mailComposeDelegate = self;
    [v setSubject:[NSString stringWithFormat:@"Feedback on Yammer.app %@",
                   PREF_KEY(@"YMPreviousBundleVersion")]];
    [v setToRecipients:array_(@"iphone@yammer-inc.com")];
    [self presentModalViewController:v animated:YES];
  }
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(void) mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
  [self dismissModalViewControllerAnimated:YES];
}

- (id)chooseFontSize:(NSNumber *)size
{
  PREF_SET(@"fontsize", size);
  PREF_SYNCHRONIZE;
  [self.navigationController popViewControllerAnimated:YES];
  return nil;
}

-(BOOL) shouldAutorotateToInterfaceOrientation:
(UIInterfaceOrientation)toInterfaceOrientation
{
  return YES;
}

@end


@implementation FontSizeDatasource

@synthesize fontSizes, chosenIndex, chooseSize;

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
  return [fontSizes count];
}

- (UITableViewCell *) tableView:(UITableView *)tableView 
          cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  UITableViewCell *c = [[[UITableViewCell alloc]
                         initWithStyle:UITableViewCellStyleDefault
                         reuseIdentifier:nil] autorelease];
  c.textLabel.text = [NSString stringWithFormat:@"%ipt", 
                      intv([fontSizes objectAtIndex:indexPath.row])];
  if (indexPath.row == chosenIndex)
    c.accessoryType = UITableViewCellAccessoryCheckmark;
  return c;
}

- (void) tableView:(UITableView *)tableView 
didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  [self.chooseSize :[fontSizes objectAtIndex:indexPath.row]];
  [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
