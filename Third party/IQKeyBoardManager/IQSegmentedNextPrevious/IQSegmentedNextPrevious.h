//
//  IQSegmentedNextPrevious.h
// https://github.com/hackiftekhar/IQKeyboardManager
// Copyright (c) 2013-14 Iftekhar Qurashi.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "IQKeyboardManagerConstants.h"

#import <Foundation/NSObjCRuntime.h>

#import <UIKit/UISegmentedControl.h>

/*!
    @class IQSegmentedNextPrevious
 
    @deprecated Deprecated in iOS 7
 
    @abstract Custom SegmentedControl for Previous/Next button.
 */

NS_CLASS_DEPRECATED_IOS(2_0, 7_0, "Deprecated for iOS 7")
@interface IQSegmentedNextPrevious : UISegmentedControl

/*!
    @method initWithTarget:previousAction:nextAction:
 
    @abstract initialization function for IQSegmentedNextPrevious.
 
    @param target: Target object for selector. Usually 'self'.
 
    @param previousAction: Previous button action name. Usually 'previousAction:(IQSegmentedNextPrevious*)segmentedControl'.
 
    @param nextAction: Next button action name. Usually 'nextAction:(IQSegmentedNextPrevious*)segmentedControl'.
 */
- (instancetype)initWithTarget:(id)target previousAction:(SEL)previousAction nextAction:(SEL)nextAction NS_DESIGNATED_INITIALIZER;

/*!
    @method init
 
    @abstract initWithTarget:previousAction:nextAction should be used.
 */
- (instancetype)init	__attribute__((unavailable("init is not available, should use initWithTarget:previousAction:nextAction instead")));

/*!
    @method init
 
    @abstract initWithTarget:previousAction:nextAction should be used.
 */
+ (instancetype)new	__attribute__((unavailable("new is not available, should use initWithTarget:previousAction:nextAction instead")));

@end

