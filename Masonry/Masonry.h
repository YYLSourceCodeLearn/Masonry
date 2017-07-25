//
//  Masonry.h
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//


/*
 AutoLayout 是 Apple 在 iOS6 中新增的 UI 布局适配的方法， 用来替代 iOS6 之前的 AutoResizeing。 AutoLayout 对应的代码约束是 NSLayoutConstaint
 NSLayoutConstraint 的 API虽说十分简单， 但约束的代码量较大， 所以出现了很多对 NSLayoutConstraint的封装， Masonry 就其框架之一。
 
 添加 NSLayoutConstrainty约束的三种方式：
 1. storyboard/xib 添加
 2. vfl 语言添加
 3. NSLayoutConstraint 纯代码添加
 
 */

#import <Foundation/Foundation.h>

//! Project version number for Masonry.
FOUNDATION_EXPORT double MasonryVersionNumber;

//! Project version string for Masonry.
FOUNDATION_EXPORT const unsigned char MasonryVersionString[];

#import "MASUtilities.h"
#import "View+MASAdditions.h"
#import "View+MASShorthandAdditions.h"
#import "ViewController+MASAdditions.h"
#import "NSArray+MASAdditions.h"
#import "NSArray+MASShorthandAdditions.h"
#import "MASConstraint.h"
#import "MASCompositeConstraint.h"
#import "MASViewAttribute.h"
#import "MASViewConstraint.h"
#import "MASConstraintMaker.h"
#import "MASLayoutConstraint.h"
#import "NSLayoutConstraint+MASDebugAdditions.h"
