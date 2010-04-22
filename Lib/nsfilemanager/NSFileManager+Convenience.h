#import <UIKit/UIKit.h>


@interface NSFileManager (Convenience)
+ (NSString*)sandBoxDocsPathForFileName:(NSString*)fileName;
+ (NSString*)resourcesPathForFileName:(NSString*)fileName;
+ (BOOL)fileNameExistsInDocumentsSandbox:(NSString*)fileName;
- (NSString*)sandBoxDocsPathForFileName:(NSString*)fileName;
- (NSString*)resourcesPathForFileName:(NSString*)fileName;
- (BOOL)fileNameExistsInDocumentsSandbox:(NSString*)fileName;
- (void)removeSandBoxItemNamed:(NSString*)itemName;
- (BOOL)copyResourceItem:(NSString*)item toFileNameInSandboxDocs:(NSString*)fileName andRetrunError:(NSError**)error;
@end