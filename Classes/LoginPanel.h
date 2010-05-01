#import <Three20/Three20.h>

@interface LoginPanel : TTTableViewController {
  TTStyledTextLabel* _message;
}

@property (nonatomic, retain) TTStyledTextLabel* message;

+ (void)handleLogin;
- (void)createDataSource;

- (id)gotLoginCredentials:(id)loggedInUser;
- (id)gotNetworks:(id)listOfNetworks;


@end
