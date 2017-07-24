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

 
 Masonry的代码流程简单来讲就是: 提供给用户一个构造者MASConstraintMark, 让用户根据 Masonry 提供的语法,添加约束结构体 MASConstraint. 最后Masonry解析约束结构体 MASContraint 将真正的约束关系 NSLayoutConstraint 添加到相应的view上
 
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
