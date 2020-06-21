//
//  Person.h
//  10.4-autoreleasePool底层原理
//
//  Created by 刘光强 on 2020/2/15.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Dog.h"

NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject
{
    Dog *_dog;
}

- (void)setDog:(Dog *)dog;

- (Dog *)dog;
@end

NS_ASSUME_NONNULL_END
