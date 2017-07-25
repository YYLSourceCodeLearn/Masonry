//
//  MASConstraint.m
//  Masonry
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "MASViewConstraint.h"
#import "MASConstraint+Private.h"
#import "MASCompositeConstraint.h"
#import "MASLayoutConstraint.h"
#import "View+MASAdditions.h"
#import <objc/runtime.h>

@interface MAS_VIEW (MASConstraints)

@property (nonatomic, readonly) NSMutableSet *mas_installedConstraints;

@end

@implementation MAS_VIEW (MASConstraints)

static char kInstalledConstraintsKey;

- (NSMutableSet *)mas_installedConstraints {
    NSMutableSet *constraints = objc_getAssociatedObject(self, &kInstalledConstraintsKey);
    if (!constraints) {
        constraints = [NSMutableSet set];
        objc_setAssociatedObject(self, &kInstalledConstraintsKey, constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return constraints;
}

@end


@interface MASViewConstraint ()

@property (nonatomic, strong, readwrite) MASViewAttribute *secondViewAttribute;
@property (nonatomic, weak) MAS_VIEW *installedView;
@property (nonatomic, weak) MASLayoutConstraint *layoutConstraint;
@property (nonatomic, assign) NSLayoutRelation layoutRelation;
@property (nonatomic, assign) MASLayoutPriority layoutPriority;
@property (nonatomic, assign) CGFloat layoutMultiplier;
@property (nonatomic, assign) CGFloat layoutConstant;
@property (nonatomic, assign) BOOL hasLayoutRelation;
@property (nonatomic, strong) id mas_key;
@property (nonatomic, assign) BOOL useAnimator;

@end

@implementation MASViewConstraint

- (id)initWithFirstViewAttribute:(MASViewAttribute *)firstViewAttribute {
    self = [super init];
    if (!self) return nil;
    
    _firstViewAttribute = firstViewAttribute;
    self.layoutPriority = MASLayoutPriorityRequired;
    self.layoutMultiplier = 1;
    
    return self;
}

#pragma mark - NSCoping

- (id)copyWithZone:(NSZone __unused *)zone {
    MASViewConstraint *constraint = [[MASViewConstraint alloc] initWithFirstViewAttribute:self.firstViewAttribute];
    constraint.layoutConstant = self.layoutConstant;
    constraint.layoutRelation = self.layoutRelation;
    constraint.layoutPriority = self.layoutPriority;
    constraint.layoutMultiplier = self.layoutMultiplier;
    constraint.delegate = self.delegate;
    return constraint;
}

#pragma mark - Public

+ (NSArray *)installedConstraintsForView:(MAS_VIEW *)view {
    return [view.mas_installedConstraints allObjects];
}

#pragma mark - Private

- (void)setLayoutConstant:(CGFloat)layoutConstant {
    _layoutConstant = layoutConstant;

#if TARGET_OS_MAC && !(TARGET_OS_IPHONE || TARGET_OS_TV)
    if (self.useAnimator) {
        [self.layoutConstraint.animator setConstant:layoutConstant];
    } else {
        self.layoutConstraint.constant = layoutConstant;
    }
#else
    self.layoutConstraint.constant = layoutConstant;
#endif
}

// 把 hasLayoutRelation 设置为 YES, layoutRelation是默认的 NSLayoutRelationEqual
- (void)setLayoutRelation:(NSLayoutRelation)layoutRelation {
    _layoutRelation = layoutRelation;
    self.hasLayoutRelation = YES;
}

- (BOOL)supportsActiveProperty {
    return [self.layoutConstraint respondsToSelector:@selector(isActive)];
}

- (BOOL)isActive {
    BOOL active = YES;
    if ([self supportsActiveProperty]) {
        active = [self.layoutConstraint isActive];
    }

    return active;
}

- (BOOL)hasBeenInstalled {
    return (self.layoutConstraint != nil) && [self isActive];
}

- (void)setSecondViewAttribute:(id)secondViewAttribute {
    if ([secondViewAttribute isKindOfClass:NSValue.class]) {
        [self setLayoutConstantWithValue:secondViewAttribute];
    } else if ([secondViewAttribute isKindOfClass:MAS_VIEW.class]) {
        _secondViewAttribute = [[MASViewAttribute alloc] initWithView:secondViewAttribute layoutAttribute:self.firstViewAttribute.layoutAttribute];
    } else if ([secondViewAttribute isKindOfClass:MASViewAttribute.class]) {
        _secondViewAttribute = secondViewAttribute;
    } else {
        NSAssert(NO, @"attempting to add unsupported attribute: %@", secondViewAttribute);
    }
}

#pragma mark - NSLayoutConstraint multiplier proxies

- (MASConstraint * (^)(CGFloat))multipliedBy {
    return ^id(CGFloat multiplier) {
        NSAssert(!self.hasBeenInstalled,
                 @"Cannot modify constraint multiplier after it has been installed");
        
        self.layoutMultiplier = multiplier;
        return self;
    };
}


- (MASConstraint * (^)(CGFloat))dividedBy {
    return ^id(CGFloat divider) {
        NSAssert(!self.hasBeenInstalled,
                 @"Cannot modify constraint multiplier after it has been installed");

        self.layoutMultiplier = 1.0/divider;
        return self;
    };
}

#pragma mark - MASLayoutPriority proxy

- (MASConstraint * (^)(MASLayoutPriority))priority {
    return ^id(MASLayoutPriority priority) {
        NSAssert(!self.hasBeenInstalled,
                 @"Cannot modify constraint priority after it has been installed");
        
        self.layoutPriority = priority;
        return self;
    };
}

#pragma mark - NSLayoutRelation proxy

- (MASConstraint * (^)(id, NSLayoutRelation))equalToWithRelation {
    return ^id(id attribute, NSLayoutRelation relation) {
        
        // 如果是 array， 则代表是多个对象的组合
        if ([attribute isKindOfClass:NSArray.class]) {
            // 如果已经有 relation 则报错
            NSAssert(!self.hasLayoutRelation, @"Redefinition of constraint relation");
            // 组合约束存储
            NSMutableArray *children = NSMutableArray.new;
            // 遍历每一个组合约束
            for (id attr in attribute) {
                //复制自己， 这里有个逻辑， 因为在 copy 的时候会设置一下 layoutRelation，
                MASViewConstraint *viewConstraint = [self copy];
                viewConstraint.layoutRelation = relation;
                // 设置 second attribute
                viewConstraint.secondViewAttribute = attr;
                [children addObject:viewConstraint];
            }
            // 初始化 MASCompositeConstaint
            MASCompositeConstraint *compositeConstraint = [[MASCompositeConstraint alloc] initWithChildren:children];
            compositeConstraint.delegate = self.delegate;
            //替换原来位置
            [self.delegate constraint:self shouldBeReplacedWithConstraint:compositeConstraint];
            return compositeConstraint;
        } else {
            //判断是否已经有过 relation， 有的话则报错
            NSAssert(!self.hasLayoutRelation || self.layoutRelation == relation && [attribute isKindOfClass:NSValue.class], @"Redefinition of constraint relation");
            //存储 realtion
            self.layoutRelation = relation;
            //设置 second attribute
            self.secondViewAttribute = attribute;
            return self;
        }
    };
}

#pragma mark - Semantic properties

- (MASConstraint *)with {
    return self;
}

- (MASConstraint *)and {
    return self;
}

#pragma mark - attribute chaining

- (MASConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    NSAssert(!self.hasLayoutRelation, @"Attributes should be chained before defining the constraint relation");

    return [self.delegate constraint:self addConstraintWithLayoutAttribute:layoutAttribute];
}

#pragma mark - Animator proxy

#if TARGET_OS_MAC && !(TARGET_OS_IPHONE || TARGET_OS_TV)

- (MASConstraint *)animator {
    self.useAnimator = YES;
    return self;
}

#endif

#pragma mark - debug helpers

- (MASConstraint * (^)(id))key {
    return ^id(id key) {
        self.mas_key = key;
        return self;
    };
}

#pragma mark - NSLayoutConstraint constant setters

- (void)setInsets:(MASEdgeInsets)insets {
    NSLayoutAttribute layoutAttribute = self.firstViewAttribute.layoutAttribute;
    switch (layoutAttribute) {
        case NSLayoutAttributeLeft:
        case NSLayoutAttributeLeading:
            self.layoutConstant = insets.left;
            break;
        case NSLayoutAttributeTop:
            self.layoutConstant = insets.top;
            break;
        case NSLayoutAttributeBottom:
            self.layoutConstant = -insets.bottom;
            break;
        case NSLayoutAttributeRight:
        case NSLayoutAttributeTrailing:
            self.layoutConstant = -insets.right;
            break;
        default:
            break;
    }
}

- (void)setInset:(CGFloat)inset {
    [self setInsets:(MASEdgeInsets){.top = inset, .left = inset, .bottom = inset, .right = inset}];
}

- (void)setOffset:(CGFloat)offset {
    self.layoutConstant = offset;
}

- (void)setSizeOffset:(CGSize)sizeOffset {
    NSLayoutAttribute layoutAttribute = self.firstViewAttribute.layoutAttribute;
    switch (layoutAttribute) {
        case NSLayoutAttributeWidth:
            self.layoutConstant = sizeOffset.width;
            break;
        case NSLayoutAttributeHeight:
            self.layoutConstant = sizeOffset.height;
            break;
        default:
            break;
    }
}

- (void)setCenterOffset:(CGPoint)centerOffset {
    NSLayoutAttribute layoutAttribute = self.firstViewAttribute.layoutAttribute;
    switch (layoutAttribute) {
        case NSLayoutAttributeCenterX:
            self.layoutConstant = centerOffset.x;
            break;
        case NSLayoutAttributeCenterY:
            self.layoutConstant = centerOffset.y;
            break;
        default:
            break;
    }
}

#pragma mark - MASConstraint

- (void)activate {
    [self install];
}

- (void)deactivate {
    [self uninstall];
}

- (void)install {
    // 已经有约束
    if (self.hasBeenInstalled) {
        return;
    }
    
    // 支持 active 且已经有了约束
    if ([self supportsActiveProperty] && self.layoutConstraint) {
        // 激活约束
        self.layoutConstraint.active = YES;
        // 添加约束缓存
        [self.firstViewAttribute.view.mas_installedConstraints addObject:self];
        return;
    }
    
    // 获得 item1, attribute1, item2, attribute2
    MAS_VIEW *firstLayoutItem = self.firstViewAttribute.item;
    NSLayoutAttribute firstLayoutAttribute = self.firstViewAttribute.layoutAttribute;
    MAS_VIEW *secondLayoutItem = self.secondViewAttribute.item;
    NSLayoutAttribute secondLayoutAttribute = self.secondViewAttribute.layoutAttribute;

    // alignment attributes must have a secondViewAttribute
    // therefore we assume that is refering to superview
    // eg make.left.equalTo(@10)
    // 如果attribute 是 sizeattribute 并且没有第二个 attribute
    if (!self.firstViewAttribute.isSizeAttribute && !self.secondViewAttribute) {
        // 默认设置 item2 为 superview
        secondLayoutItem = self.firstViewAttribute.view.superview;
        secondLayoutAttribute = firstLayoutAttribute;
    }
    
    //生成约束
    MASLayoutConstraint *layoutConstraint
        = [MASLayoutConstraint constraintWithItem:firstLayoutItem
                                        attribute:firstLayoutAttribute
                                        relatedBy:self.layoutRelation
                                           toItem:secondLayoutItem
                                        attribute:secondLayoutAttribute
                                       multiplier:self.layoutMultiplier
                                         constant:self.layoutConstant];
    // 设置 priority 和 mas_key
    layoutConstraint.priority = self.layoutPriority;
    layoutConstraint.mas_key = self.mas_key;
    
    // 如果第二个 attribute 有 view
    if (self.secondViewAttribute.view) {
        // 获取两个 view 的最小公共 view
        MAS_VIEW *closestCommonSuperview = [self.firstViewAttribute.view mas_closestCommonSuperview:self.secondViewAttribute.view];
        NSAssert(closestCommonSuperview,
                 @"couldn't find a common superview for %@ and %@",
                 self.firstViewAttribute.view, self.secondViewAttribute.view);
        
        // 设置约束view 为此 view
        self.installedView = closestCommonSuperview;
    } else if (self.firstViewAttribute.isSizeAttribute) {
        // 如果是 size attribute 则为本身
        self.installedView = self.firstViewAttribute.view;
    } else {
        // 其它则是 superview
        self.installedView = self.firstViewAttribute.view.superview;
    }

    // 已经存在的约束
    MASLayoutConstraint *existingConstraint = nil;
    // 需要更新
    if (self.updateExisting) {
        // 则获得此生成的约束，返回和 installedview 的约束是同类约束
        existingConstraint = [self layoutConstraintSimilarTo:layoutConstraint];
    }
    
    //如果过存在则 替换约束
    if (existingConstraint) {
        // just update the constant
        existingConstraint.constant = layoutConstraint.constant;
        //缓存约束类型
        self.layoutConstraint = existingConstraint;
    } else {
        //其它情况则直接添加约束
        [self.installedView addConstraint:layoutConstraint];
        //缓存约束类型
        self.layoutConstraint = layoutConstraint;
        //缓存已经安装的约束
        [firstLayoutItem.mas_installedConstraints addObject:self];
    }
}

- (MASLayoutConstraint *)layoutConstraintSimilarTo:(MASLayoutConstraint *)layoutConstraint {
    // check if any constraints are the same apart from the only mutable property constant

    // go through constraints in reverse as we do not want to match auto-resizing or interface builder constraints
    // and they are likely to be added first.
    for (NSLayoutConstraint *existingConstraint in self.installedView.constraints.reverseObjectEnumerator) {
        if (![existingConstraint isKindOfClass:MASLayoutConstraint.class]) continue;
        if (existingConstraint.firstItem != layoutConstraint.firstItem) continue;
        if (existingConstraint.secondItem != layoutConstraint.secondItem) continue;
        if (existingConstraint.firstAttribute != layoutConstraint.firstAttribute) continue;
        if (existingConstraint.secondAttribute != layoutConstraint.secondAttribute) continue;
        if (existingConstraint.relation != layoutConstraint.relation) continue;
        if (existingConstraint.multiplier != layoutConstraint.multiplier) continue;
        if (existingConstraint.priority != layoutConstraint.priority) continue;

        return (id)existingConstraint;
    }
    return nil;
}

//删除约束
- (void)uninstall {
    //判断是否支持 active 去设置 NSLayoutConstraint
    if ([self supportsActiveProperty]) {
        // 设置 active 为 no
        self.layoutConstraint.active = NO;
        // 删除 installed 缓存
        [self.firstViewAttribute.view.mas_installedConstraints removeObject:self];
        return;
    }
    
    //删除此约束
    [self.installedView removeConstraint:self.layoutConstraint];
    self.layoutConstraint = nil;
    self.installedView = nil;
    // 删除 installed 缓存
    [self.firstViewAttribute.view.mas_installedConstraints removeObject:self];
}

@end
