//
//  main.m
//  TmuxSendKeys
//
//  Created by Lonny Wong on 2022/1/18.
//

#import <Foundation/Foundation.h>
#import "TmuxGateway.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        NSLog(@"Hello, World!");
        TmuxGateway *tg = [[TmuxGateway alloc] init];
        [tg testSendKeys];
    }
    return 0;
}
