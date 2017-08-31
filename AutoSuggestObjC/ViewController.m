//
//  ViewController.m
//  AutoSuggestObjC
//
//  Created by Bharatraj Rai on 29/08/17.
//  Copyright © 2017 Bharatraj Rai. All rights reserved.
//

#import "ViewController.h"
#import "SuggestibleTextFieldCell.h"
#import "SuggestionsWindow.h"


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
//    self.imageURLS = [NSMutableArray array];
//    [self initialize];
    [self initializeTimezone];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

- (void)initializeTimezone {
    self.timeZoneList = [NSMutableArray array];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"timezones" ofType:@"json"];
    NSError *error;
    NSString *rawJson = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    NSArray *jsonDataArray = [NSJSONSerialization JSONObjectWithData:[rawJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    NSDictionary *timezoneDict = [jsonDataArray valueForKey:@"timezones"];
    for (NSDictionary *timezone in timezoneDict) {
        NSString *abbrName = [timezone valueForKey:@"abbr"];
        NSArray *utcList = [timezone valueForKey:@"utc"];
        for (NSString *utc in utcList) {
            NSDictionary *timeZoneDetails = [NSDictionary dictionaryWithObjectsAndKeys:utc, @"utc", abbrName, @"abbr", nil];
            [self.timeZoneList addObject:timeZoneDetails];
        }
    }
}

- (void)initialize {
    self.bankList = [NSMutableArray array];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"zips" ofType:@"json"];
    NSError *error;
    NSString *rawJson = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
    
    NSArray *jsonDataArray = [NSJSONSerialization JSONObjectWithData:[rawJson dataUsingEncoding:NSUTF8StringEncoding] options:0 error:&error];
    NSDictionary *bankDetailDict = [jsonDataArray valueForKey:@"zipcodes"];
    for (NSDictionary *bank in bankDetailDict) {
        [self.bankList addObject:bank];
    }
}

/* Update the field editor with a suggested string. The additional suggested characters are auto selected.
 */
- (void)updateFieldEditor:(NSText *)fieldEditor withSuggestion:(NSString *)suggestion {
    NSRange selection = NSMakeRange([fieldEditor selectedRange].location, [suggestion length]);
    [fieldEditor setString:suggestion];
    [fieldEditor setSelectedRange:selection];
}

- (void)updateSuggestionsFromControl:(NSControl*)control {
    NSText *fieldEditor = [self.view.window fieldEditor:NO forObject:control];
    NSRange selection = [fieldEditor selectedRange];
    NSString *text = [[fieldEditor string] substringToIndex:selection.location];
    NSArray *suggestions = [self suggestionsForText:text.uppercaseString];
    if ([suggestions count] > 0) {
        NSString *countryName = [[suggestions objectAtIndex:0] valueForKey:@"utc"];
        [self updateFieldEditor:fieldEditor withSuggestion:countryName];
        [self.suggestionsController updateSuggestions:suggestions];
        if (![self.suggestionsController.window isVisible]) {
            [self.suggestionsController beginForTextField:(NSTextField*)control];
        }
    }
    else {
        [self.suggestionsController cancelSuggestions];
    }

    
}

- (NSArray *)suggestionsForText:(NSString*)text {
    NSMutableArray *suggestions = [NSMutableArray arrayWithCapacity:1];
    for (NSDictionary *timezone in self.timeZoneList) {
        if ([[[timezone valueForKey:@"utc"] uppercaseString] containsString:text.uppercaseString]) {
            [suggestions addObject:timezone];
        }
        if (suggestions.count > 9) {
            return suggestions;
        }
    }
    return suggestions;
}

/* This is the action method for when the user changes the suggestion selection. Note, this action is called continuously as the suggestion selection changes while being tracked and does not denote user committal of the suggestion. For suggestion committal, the text field's action method is used (see above). This method is wired up programatically in the -controlTextDidBeginEditing: method below.
 */
- (IBAction)updateWithSelectedSuggestion:(id)sender {
    NSDictionary *entry = [sender selectedSuggestion];
    if (entry) {
        NSText *fieldEditor = [self.view.window fieldEditor:NO forObject:self.searchField];
        if (fieldEditor) {
            [self updateFieldEditor:fieldEditor withSuggestion:[entry valueForKey:@"utc"]];
        }
    }
}


#pragma mark NSTextFieldDelegate methods

/* In interface builder, we set this class object as the delegate for the search text field. When the user starts editing the text field, this method is called. This is an opportune time to display the initial suggestions.
 */
- (void)controlTextDidBeginEditing:(NSNotification *)notification {
    // We keep the suggestionsController around, but lazely allocate it the first time it is needed.
    if (!self.suggestionsController) {
        self.suggestionsController = [[SuggestionsWindowController alloc] init];
        self.suggestionsController.target = self;
        self.suggestionsController.action = @selector(updateWithSelectedSuggestion:);
    }
    NSUInteger characterlength = [[[notification object]stringValue]length];

    if (characterlength > 2) {
        [self updateSuggestionsFromControl:notification.object];
    }
}


- (void)controlTextDidChange:(NSNotification *)notification {
    NSUInteger characterlength = [[[notification object]stringValue]length];

    if(!self.skipNextSuggestion && characterlength > 2) {
        [self updateSuggestionsFromControl:notification.object];
    }
    else {
        [self.suggestionsController cancelSuggestions];
        self.skipNextSuggestion = NO;
    }
}

/* The field editor has ended editing the text. This is not the same as the action from the NSTextField. In the MainMenu.xib, the search text field is setup to only send its action on return / enter. If the user tabs to or clicks on another control, text editing will end and this method is called. We don't consider this committal of the action. Instead, we realy on the text field's action (see -takeImageFromSuggestedURL: above) to commit the suggestion. However, since the action may not occur, we need to cancel the suggestions window here.
 */
- (void)controlTextDidEndEditing:(NSNotification *)obj {
    /* If the suggestionController is already in a cancelled state, this call does nothing and is therefore always safe to call.
     */
    [self.suggestionsController cancelSuggestions];
}


/* As the delegate for the NSTextField, this class is given a chance to respond to the key binding commands interpreted by the input manager when the field editor calls -interpretKeyEvents:. This is where we forward some of the keyboard commands to the suggestion window to facilitate keyboard navigation. Also, this is where we can determine when the user deletes and where we can prevent AppKit's auto completion.
 */
- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    
    if (commandSelector == @selector(moveUp:)) {
        // Move up in the suggested selections list
        [self.suggestionsController moveUp:textView];
        return YES;
    }
    
    if (commandSelector == @selector(moveDown:)) {
        // Move down in the suggested selections list
        [self.suggestionsController moveDown:textView];
        return YES;
    }
    
    if (commandSelector == @selector(deleteForward:) || commandSelector == @selector(deleteBackward:)) {
        /* The user is deleting the highlighted portion of the suggestion or more. Return NO so that the field editor performs the deletion. The field editor will then call -controlTextDidChange:. We don't want to provide a new set of suggestions as that will put back the characters the user just deleted. Instead, set skipNextSuggestion to YES which will cause -controlTextDidChange: to cancel the suggestions window. (see -controlTextDidChange: above)
         */
        self.skipNextSuggestion = YES;
        return NO;
    }
    
    if (commandSelector == @selector(complete:)) {
        // The user has pressed the key combination for auto completion. AppKit has a built in auto completion. By overriding this command we prevent AppKit's auto completion and can respond to the user's intention by showing or cancelling our custom suggestions window.
        if ([self.suggestionsController.window isVisible]) {
            [self.suggestionsController cancelSuggestions];
        } else {
            [self updateSuggestionsFromControl:control];
        }
        
        return YES;
    }
    
    // This is a command that we don't specifically handle, let the field editor do the appropriate thing.
    return NO;
}



@end
