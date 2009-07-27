#import <UIKit/UIKit.h>
#import "SpinnerWithText.h"

@interface ComposeYamController : UIViewController <UITextViewDelegate, 
                                                    UIImagePickerControllerDelegate, 
                                                    UIActionSheetDelegate,
                                                    UINavigationControllerDelegate> {
  UITextView *input;
  SpinnerWithText *topSpinner;
  SpinnerWithText *previousSpinner;
  NSData *imageData;
}

@property (nonatomic,retain) UITextView *input;
@property (nonatomic,retain) SpinnerWithText *topSpinner;
@property (nonatomic,retain) SpinnerWithText *previousSpinner;
@property (nonatomic,retain) NSData *imageData;

- (void)sendMessage;
- (id)initWithSpinner:(SpinnerWithText *)spinner;
- (void)sendUpdate:(NSString *)text;
- (void)photoSelect;
- (void)setSendEnabledState;

@end
