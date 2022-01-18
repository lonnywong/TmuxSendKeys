//
//  TmuxGateway.m
//  TmuxSendKeys
//
//  Created by Lonny Wong on 2022/1/18.
//

#import "TmuxGateway.h"

@implementation TmuxGateway

- (void)testSendKeys {
    NSLog(@"Test SendKeys!");
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:0x100];
    for (int i = 0; i < 0x100; i++) {
        [arr addObject:[NSNumber numberWithInt:i]];
    }
    [self sendCodePoints:arr toWindowPane:10];
}

- (void)sendCodePoints:(NSArray<NSNumber *> *)codePoints toWindowPane:(int)windowPane {
    if (!codePoints.count) {
        return;
    }

    // Send multiple small send-keys commands because commands longer than 1024 bytes crash tmux 1.8.
    NSMutableArray *commands = [NSMutableArray array];
    const NSUInteger stride = 80;
    for (NSUInteger start = 0; start < codePoints.count; start += stride) {
        NSUInteger length = MIN(stride, codePoints.count - start);
        NSRange range = NSMakeRange(start, length);
        NSArray *subarray = [codePoints subarrayWithRange:range];
        [commands addObject:[self dictionaryForSendKeysCommandWithCodePoints:subarray windowPane:windowPane]];
    }

    [self sendCommandList:commands];
}

- (NSString *)dictionaryForSendKeysCommandWithCodePoints:(NSArray<NSNumber *> *)codePoints
                                                  windowPane:(int)windowPane {
    NSString *value;
    if ([codePoints isEqual:@[ @0 ]]) {
        value = @"C-Space";
    } else {
        value = [self numbersAsHexStrings:codePoints];
    }
    NSString *command = [NSString stringWithFormat:@"send-keys -t \"%%%d\" %@",
                         windowPane, value];
    return command;
}

- (void)sendCommandList:(NSArray *)commandDicts {
    for (NSString * str in commandDicts) {
        NSLog(@"%@", str);
    }
}

- (NSString *)numbersAsHexStrings:(NSArray<NSNumber *> *)codePoints {
    NSMutableString *result = [NSMutableString string];
    NSString *separator = @"";
    for (NSNumber *number in codePoints) {
        if (![number isKindOfClass:[NSNumber class]]) {
            continue;
        }
        if (number.intValue == 0) {
            [result appendFormat:@"%@C-Space", separator];
        } else {
            [result appendFormat:@"%@0x%x", separator, number.intValue];
        }
        separator = @" ";
    }
    return result;
}

@end
