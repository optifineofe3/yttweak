#import "ELMPBElement.h"

@class ELMPBCommand;

@interface ELMPBShowActionSheetCommand : GPBMessage
@property (nonatomic, readwrite, copy) NSString *sheetId;
@property (nonatomic, readwrite, strong) ELMPBElement *header;
@property (nonatomic, readwrite, strong) ELMPBElement *footer;
@property (nonatomic, readwrite, strong) NSMutableArray *listOptionArray;
@property (nonatomic, strong, readwrite) ELMPBCommand *onAppear;
@property (nonatomic, assign, readwrite) BOOL hasOnAppear;
@end
