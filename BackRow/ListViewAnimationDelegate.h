/**
 * This header is generated by class-dump-z 0.2a.
 * class-dump-z is Copyright (C) 2009 by KennyTM~, licensed under GPLv3.
 *
 * Source: /System/Library/PrivateFrameworks/BackRow.framework/BackRow
 */


@class BRListView;

__attribute__((visibility("hidden")))
@interface ListViewAnimationDelegate : NSObject {
@private
	BRListView *_list;	// 4 = 0x4
	long _animationBalance;	// 8 = 0x8
}
- (id)initWithList:(id)list;	// 0x3166c521
- (void)animationDidStart:(id)animation;	// 0x3166de19
- (void)animationDidStop:(id)animation finished:(BOOL)finished;	// 0x3166de05
- (void)clearScroll;	// 0x3166c475
- (void)decrementBalance;	// 0x3166de2d
- (void)incrementBalance;	// 0x3166de61
- (BOOL)scrolling;	// 0x3166c485
@end

