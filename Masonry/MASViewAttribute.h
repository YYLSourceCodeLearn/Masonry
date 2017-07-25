//
//  MASAttribute.h
//  Masonry
//
//  Created by Jonas Budelmann on 21/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//
//  MASViewAttribute 其实就是一个调用 view， 交互的 item 和 NSLayoutAttribute 的结构体

#import "MASUtilities.h"

/**
 *  An immutable tuple which stores the view and the related NSLayoutAttribute.
 *  Describes part of either the left or right hand side of a constraint equation
 */
//  MASViewAttribute 是 View 与 NSLayoutAttribute 的合体
@interface MASViewAttribute : NSObject

/**
 *  The view which the reciever relates to. Can be nil if item is not a view.
 //调用view
 */

@property (nonatomic, weak, readonly) MAS_VIEW *view;

/**
 *  The item which the reciever relates to.
 */
//交互对象
// 对于 UIVIew 来说 item 就是 UIView 本身， 而对于 UIViewController,该 item 就是 topLayoutGuide, bottomLayoutGuide
@property (nonatomic, weak, readonly) id item;

/**
 *  The attribute which the reciever relates to
 */
//约束NSLayoutAttribute类型
@property (nonatomic, assign, readonly) NSLayoutAttribute layoutAttribute;

/**
 *  Convenience initializer.
 */
- (id)initWithView:(MAS_VIEW *)view layoutAttribute:(NSLayoutAttribute)layoutAttribute;

/**
 *  The designated initializer.
 */
- (id)initWithView:(MAS_VIEW *)view item:(id)item layoutAttribute:(NSLayoutAttribute)layoutAttribute;

/**
 *	Determine whether the layoutAttribute is a size attribute
 *
 *	@return	YES if layoutAttribute is equal to NSLayoutAttributeWidth or NSLayoutAttributeHeight
 */
// 用来判断 MASViewAttribute类中的 layoutAttribute 属性是否是 NSLayoutAttributeWidth 或 NSLayoutAttributeHeight， 如果是 width 或者 height 的话， 那么约束就添加到当前 view 上， 而不是添加到父视图上。
- (BOOL)isSizeAttribute;

@end
