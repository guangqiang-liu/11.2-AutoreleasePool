//
//  main.m
//  10.4-autoreleasePool底层原理
//
//  Created by 刘光强 on 2020/2/15.
//  Copyright © 2020 guangqiang.liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Person.h"


// 我们将其他模块的函数_objc_autoreleasePoolPrint()，添加`extern`后，就可以导出这个函数来使用
extern void _objc_autoreleasePoolPrint(void);
extern uintptr_t _objc_rootRetainCount(id obj);


void test1() {
    Person *person = [[[Person alloc] init] autorelease];

    // 注意：在MRC中进行内存管理，我们调用`autorelease`和`release`都可以释放对象，一般我们都选择使用`autorelease`方式来释放对象，因为`autorelease`不用去关心这个对象在什么时候不在需要使用了，系统会在合适的时机释放这个对象
    //        [person release];


    // 调用了`autorelease`的对象，到底是在什么时候释放尼？？？
    // 如果是在局部作用域，那么是在`@autoreleasepool {}`结束的大括号后释放，也就是说在它所在的自动释放池销毁的时候，池子里的对象就会销毁

    NSLog(@"111");
    @autoreleasepool {
        Person *person2 = [[[Person alloc] init] autorelease];
    }
    NSLog(@"222");
}

void test2() {
    // @autoreleasepool大括号开始的时候调用：`atautoreleasepoolobj = objc_autoreleasePoolPush()`
            
    //        atautoreleasepoolobj = objc_autoreleasePoolPush();
            
            Person *person = [[[Person alloc] init] autorelease];
            
            @autoreleasepool {
    //          atautoreleasepoolobj = objc_autoreleasePoolPush();

                // 代码xxx
                
    //          objc_autoreleasePoolPop(atautoreleasepoolobj);
            }
            
            // @autoreleasepool大括号结束的时候调用：`objc_autoreleasePoolPop(atautoreleasepoolobj)`
    //        objc_autoreleasePoolPop(atautoreleasepoolobj);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool { // 大括号开始执行 r1 = push()
        // insert code here...
        
        // 这里注意：这个是MRC的环境
        
        NSLog(@"%@", [NSThread currentThread]);
        
        _objc_autoreleasePoolPrint();
    
        
        Person *p1 = [[[Person alloc] init] autorelease];
        Person *p2 = [[[Person alloc] init] autorelease];
        
        NSObject *obj1 = [[NSObject alloc] init];
        
        _objc_autoreleasePoolPrint();
        
        // 我们发现，当对象不调用`autorelease`函数时，是不会添加到自动释放池的Page中的
        NSObject *obj2 = [[NSObject alloc] init];
        
        _objc_autoreleasePoolPrint();
        
        // 我们再来研究下，调用了autorelease的对象，然后紧接着调用release函数会发生什么？
        // 我们通过打印发现，当对象调用了autorelease方法，添加到自动释放池中后，还没有等到从自动释放池中释放，就提前调用了release函数
        
        // 这时在打印自动释放池的情况来看，发现这个释放了的对象在自动释放池中被标记为nil了，也就是说已经被释放了
//        [p2 release];
        
        _objc_autoreleasePoolPrint();
        
        @autoreleasepool { // r2 = push()
            Person *p3 = [[Person alloc] init];
            
            _objc_autoreleasePoolPrint();
            
            @autoreleasepool { // r3 = push()
                
                _objc_autoreleasePoolPrint();
                
                Person *p4 = [[[Person alloc] init] autorelease];
                Person *p5 = [[[Person alloc] init] autorelease];
                
                Dog *dog = [[[Dog alloc] init] autorelease]; // 1
                
                _objc_rootRetainCount(dog);
                NSLog(@"%zd", [dog retainCount]);
                
                [p4 setDog:dog]; // 2
                [p5 setDog:dog]; // 3
                
                // 将dog对象添加到自动释放池中，然后让dog的引用计数变为3，但是自动释放池中只会记录一个dog对象，并且当自动释放池离开结束大括号的作用域后，这个局部的自动释放池就会被销毁，自动释放池销毁它里面的所有的对象也都全部得销毁，不管这个对象的引用计数是1还是说大于1，都全部销毁了，这是因为自动释放池中的对象，销毁的过程是从池子的最后面开始逐一销毁对象，直到销毁到POOL_BOUNDARY的位置停止销毁
                
                _objc_rootRetainCount(dog);
                
                NSLog(@"%zd", [dog retainCount]);
                
                // 打印自动释放池中的情况
                _objc_autoreleasePoolPrint();
                
            } // 大括号结束执行 pop(r3)
            
            _objc_autoreleasePoolPrint();
            
        } // 大括号结束执行 pop(r2)
        
        _objc_autoreleasePoolPrint();
        
    } // 大括号结束执行 pop(r1)
    
    _objc_autoreleasePoolPrint();
    
    // 上面的示例中，当是多个@autoreleasepool嵌套的情况时，这时我们需要注意，在每一个@autoreleasepool开始的大括号后，都会将一个POOL_BOUNDARY入栈
    return 0;
}

/**
 struct __AtAutoreleasePool {
   __AtAutoreleasePool() { // 构造函数，在创建结构体的时候调用
       atautoreleasepoolobj = objc_autoreleasePoolPush();
   }
     
   ~__AtAutoreleasePool() { // 析构函数，在结构体销毁的时候调用
       objc_autoreleasePoolPop(atautoreleasepoolobj);
   }
 
   void * atautoreleasepoolobj;
 };
 */


/**
 {
     // 声明结构体变量，调用结构体的构造函数
     __AtAutoreleasePool __autoreleasepool;
     Person *person = [[[Person alloc] init] autorelease];
 }
 */


/**
 下面有关autoreleasePool，有几个很关键的问题：
    
    * autoreleasePool什么时候创建？
    * autoreleasePool什么时候销毁？
    * autoreleasePool中的对象什么时候销毁？
    * autoreleasePool的底层结构？
    * autoreleasePool的工作原理？
 
 
 
 * autoreleasePool什么时候创建？
     > 自动释放池的创建分为手动创建和系统自动创建，如果是手动创建，我们可以在任何需要的时候手动创建自动释放池，如果是系统自动创建，则是在每次runloop进入循环之前创建自动释放池
     
 * autoreleasePool什么时候销毁？
     > 自动释放池销毁我们可以调用`drain`来销毁，或者是@autoreleasepool{}出了作用域也会销毁，还有就是runloop退出时和子线程销毁时系统自动销毁自动释放池
     
 * autoreleasePool中的对象什么时候销毁？
     > 当我们调用自动释放池的`drain`或者`release`方法来销毁自动释放池时，会向自动释放池中的所有对象发送release消息，还有就是当runloop循环即将进入休眠状态时，或者是runloop退出时，也会向自动释放池中对象发送release消息
     
 * autoreleasePool的底层结构？
     > 自动释放池底层数据结构是一个结构体对象，有多个AutoreleasePoolPage类组成的双向链表，由POOL_BOUNDRY来记录要释放对象的结束地址，调用Push就将对象添加到自动释放池，调用Pop就讲对象释放
     
 * autoreleasePool的工作原理？
     > 当对象调用`autorelease`，就会执行Push操作将这个对象添加到自动释放池，在ARC环境下，被__autorelease修饰的对象，也会被添加到自动释放池，当自动释放池销毁，则池中的所有对象也会销毁。并且程序还在runloop中添加了两个处理自动释放池的Observer，一个是runloop进入Observer，当监听到runloop进入，会执行自动释放池的Push操作，第二个Observer监听了runloop的即将进入休眠和退出，当监听到即将进入休眠状态时，会调用自动释放池的Pop操作，然后调用Push操作，当监听到runloop退出时，调用自动释放池的Pop操作
     
 * 自动释放池和线程的关系？
 */
