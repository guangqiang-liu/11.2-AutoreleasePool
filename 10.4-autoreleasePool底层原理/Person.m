//
//  Person.m
//  10.4-autoreleasePool底层原理
//
//  Created by 刘光强 on 2020/2/15.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import "Person.h"

@implementation Person

- (void)setDog:(Dog *)dog {
    if (dog != _dog) {
        [_dog release];
        dog = [dog retain];
        _dog = dog;
    }
}

- (Dog *)dog {
    return _dog;
}

- (void)dealloc {
    
    NSLog(@"%s", __func__);
    self.dog = nil;
    
    [super dealloc];
}
@end
