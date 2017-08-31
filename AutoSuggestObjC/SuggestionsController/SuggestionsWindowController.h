//
//  SuggestionsWindowController.h
//  AutoSuggestObjC
//
//  Created by Bharatraj Rai on 29/08/17.
//  Copyright © 2017 Bharatraj Rai. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SuggestionsWindowController : NSWindowController

@property(nonatomic, strong)NSArray *suggestions;
@property(nonatomic, strong)NSMutableArray *viewControllers;
@property(nonatomic, strong)NSMutableArray *trackingAreas;
@property(nonatomic, weak)id localMouseDownEventMonitor;
@property(nonatomic, weak)id lostFocusObserver;


@property(nonatomic, weak)NSView *selectedView;
@property(nonatomic, weak)NSTextField *parentTextField;
@property(nonatomic, weak)NSWindow *suggestionsWindow;
@property (assign) BOOL needsLayoutUpdate;
@property (assign) SEL action;
@property (assign) id target;


// -beginForControl: is used to display the suggestions window just underneath the parent control.
- (void)beginForTextField:(NSTextField *)parentTextField;

/* Order out the suggestion window, disconnect the accessibility logical relationship and dismantle any observers for auto cancel.
 Note: It is safe to call this method even if the suggestions window is not currently visible.
 */
- (void)cancelSuggestions;

// Returns the dictionary of the currently selected suggestion.
- (id)selectedSuggestion;

- (void)updateSuggestions:(NSArray*)suggestions;

@end
