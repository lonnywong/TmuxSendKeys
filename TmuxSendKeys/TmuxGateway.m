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
    const NSUInteger maxLiteralCharacters = 1000;  // 1024 - len('send -lt %123456789 ') = 1004
    const NSUInteger maxHexCharacters = maxLiteralCharacters / 8;  // len(' C-Space') = 8

    BOOL asLiteralCharacters = NO;
    NSMutableArray *commands = [NSMutableArray array];
    NSMutableArray *subarray = [NSMutableArray arrayWithCapacity:MIN(codePoints.count, maxLiteralCharacters)];

    for (NSNumber *number in codePoints) {
        BOOL currentAsLiteralCharacter = [self canSendAsLiteralCharacter:number];
        if (asLiteralCharacters != currentAsLiteralCharacter) {
            if (subarray.count > 0) {
                [commands addObject:[self dictionaryForSendKeysCommandWithCodePoints:subarray
                                                                          windowPane:windowPane
                                                                 asLiteralCharacters:asLiteralCharacters]];
                [subarray removeAllObjects];
            }
            [subarray addObject:number];
            asLiteralCharacters = currentAsLiteralCharacter;
            continue;
        }

        [subarray addObject:number];
        if (!asLiteralCharacters && subarray.count >= maxHexCharacters) {
            [commands addObject:[self dictionaryForSendKeysCommandWithCodePoints:subarray
                                                                      windowPane:windowPane
                                                             asLiteralCharacters:asLiteralCharacters]];
            [subarray removeAllObjects];
            continue;
        }
        if (asLiteralCharacters && subarray.count >= maxLiteralCharacters) {
            [commands addObject:[self dictionaryForSendKeysCommandWithCodePoints:subarray
                                                                      windowPane:windowPane
                                                             asLiteralCharacters:asLiteralCharacters]];
            [subarray removeAllObjects];
            continue;
        }
    }

    if (subarray.count > 0) {
        [commands addObject:[self dictionaryForSendKeysCommandWithCodePoints:subarray
                                                                  windowPane:windowPane
                                                         asLiteralCharacters:asLiteralCharacters]];
    }

    [self sendCommandList:commands];
}

- (BOOL) canSendAsLiteralCharacter:(NSNumber *)codePoint {
    int number = [codePoint intValue];
    if (number < 0x21 || number >= 0x7f) {
        return NO;
    }
    for (const char *p = "\"#';\\{}"; *p != '\0'; p++) {
        if (number == *p) {
            return NO;
        }
    }
    return YES;
}

- (NSString *)numbersAsLiteralCharacters:(NSArray<NSNumber *> *)codePoints {
    NSMutableString *result = [NSMutableString stringWithCapacity:codePoints.count];
    for (NSNumber *number in codePoints) {
        [result appendFormat:@"%c", number.intValue];
    }
    return result;
}

- (NSString *)dictionaryForSendKeysCommandWithCodePoints:(NSArray<NSNumber *> *)codePoints
                                              windowPane:(int)windowPane
                                     asLiteralCharacters:(BOOL)asLiteralCharacters {
    NSString *value;
    if (asLiteralCharacters) {
        value = [self numbersAsLiteralCharacters:codePoints];
    } else {
        value = [self numbersAsHexStrings:codePoints];
    }
    NSString *command = [NSString stringWithFormat:@"send %@ %%%d %@",
                         asLiteralCharacters ? @"-lt" : @"-t", windowPane, value];
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
