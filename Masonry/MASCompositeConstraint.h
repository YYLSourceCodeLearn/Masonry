//
//  MASCompositeConstraint.h
//  Masonry
//
//  Created by Jonas Budelmann on 21/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//  表示系列view组合的约束结构体

#import "MASConstraint.h"
#import "MASUtilities.h"

/**
 *	A group of MASConstraint objects
 */
// 代表一组 MASViewConstraint
// 比如源代码中的 make.top 会转化为 MASViewConstraint 约束
// 而 make.top.bottom.left.right.xxxx 这种写法会定义多种 MASViewConstraint 约束， 而为了存储这种写法， 则创建了 MASCompositeConstraint

@interface MASCompositeConstraint : MASConstraint

/**
 *	Creates a composite with a predefined array of children
 *
 *	@param	children	child MASConstraints
 *
 *	@return	a composite constraint
 */
- (id)initWithChildren:(NSArray *)children;

@end
