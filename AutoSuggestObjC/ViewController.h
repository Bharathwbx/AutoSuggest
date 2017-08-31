//
//  ViewController.h
//  AutoSuggestObjC
//
//  Created by Bharatraj Rai on 29/08/17.
//  Copyright © 2017 Bharatraj Rai. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SuggestionsWindowController.h"


@interface ViewController : NSViewController<NSTextFieldDelegate>


@property(nonatomic, strong)NSMutableArray *bankList;
@property(nonatomic, strong)NSMutableArray *timeZoneList;
@property(nonatomic, strong)SuggestionsWindowController *suggestionsController;
@property (weak) IBOutlet NSTextField *searchField;
@property (assign) BOOL skipNextSuggestion;




@end

