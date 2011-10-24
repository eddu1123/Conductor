//
//  ConductorTests.m
//  ConductorTests
//
//  Created by Andrew Smith on 10/21/11.
//  Copyright (c) 2011 Andrew B. Smith. All rights reserved.
//

#import "ConductorTests.h"

#import "Conductor+Private.h"

#import "CDOperation.h"
#import "CDTestOperation.h"

@implementation ConductorTests

- (void)setUp {
    [super setUp];
    
    testOperationQueue = [[CDOperationQueue alloc] init];
    [testOperationQueue.queue setMaxConcurrentOperationCount:1];

    conductor = [[Conductor alloc] init];
}

- (void)tearDown {    
    [super tearDown];

    [testOperationQueue release], testOperationQueue = nil;
    [conductor release], conductor = nil;
}

#pragma mark - CDOperation

- (void)testCreateOperationWithIdentifier {
    CDOperation *op = [CDOperation operationWithIdentifier:@"1234"];
    STAssertEqualObjects(op.identifier, @"1234", @"Operation should have correct identifier");
}

- (void)testCreateOperationWithoutIdentifier {
    CDOperation *op = [CDOperation operation];
    STAssertNotNil(op.identifier, @"Operation should have an identifier");
}

- (void)testRunTestOperation {

    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    NSOperationQueue *queue = [[[NSOperationQueue alloc] init] autorelease];
    [queue addOperation:op];

    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertTrue(hasFinished, @"Test operation should run");
}

#pragma mark - CDOperationQueue

- (void)testAddOperationToQueue {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];

    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
        
    STAssertTrue(hasFinished, @"Test operation queue should finish");
}

- (void)testAddOperationToQueueAtPriority {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op atPriority:NSOperationQueuePriorityVeryLow];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertEquals(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriority {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };     
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];
    
    [testOperationQueue updatePriorityOfOperationWithIdentifier:op.identifier 
                                                  toNewPriority:NSOperationQueuePriorityVeryLow];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    } 
    
    STAssertEquals(op.queuePriority, NSOperationQueuePriorityVeryLow, @"Operation should have correct priority");
}

- (void)testChangeOperationPriorityFinishOrder {
    
    __block BOOL hasFinished = NO;
    
    __block NSDate *last = nil;
    __block NSDate *first = nil;
    
    void (^finishLastBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;
            last = [[NSDate date] retain];
        });
    };    
    
    void (^finishFirstBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            first = [[NSDate date] retain];
        });
    };    
    
    CDTestOperation *finishLast = [CDTestOperation operationWithIdentifier:@"1"];
    finishLast.completionBlock = finishLastBlock;
    
    CDTestOperation *op = [CDTestOperation operationWithIdentifier:@"2"];
    
    CDTestOperation *finishFirst = [CDTestOperation operationWithIdentifier:@"3"];
    finishFirst.completionBlock = finishFirstBlock;
    
    [testOperationQueue addOperation:finishLast];
    [testOperationQueue addOperation:op];
    [testOperationQueue addOperation:finishFirst];
    
    [testOperationQueue updatePriorityOfOperationWithIdentifier:@"3" 
                                                  toNewPriority:NSOperationQueuePriorityVeryHigh];
    
    [testOperationQueue updatePriorityOfOperationWithIdentifier:@"1" 
                                                  toNewPriority:NSOperationQueuePriorityVeryLow];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
        
    float firstInt = [first timeIntervalSinceNow];
    float lastInt  = [last timeIntervalSinceNow];
        
    STAssertTrue((firstInt < lastInt), @"Operation should finish first");
}

- (void)testEmptyQueueShouldHaveEmptyOperationsDict {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    NSInteger count = testOperationQueue.operations.count;
    STAssertEquals(count, 0, @"Operation queue should be empty");
}

- (void)testOperationQueueShouldReportRunning {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [testOperationQueue addOperation:op];
    
    STAssertTrue(testOperationQueue.isRunning, @"Operation queue should be running");
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertFalse(testOperationQueue.isRunning, @"Operation queue should not be running");
}

#pragma mark - Conductor

- (void)testConductorAddOperation {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [conductor addOperation:op];
    
    STAssertNotNil([conductor queueForOperation:op shouldCreate:NO], @"Conductor should have queue for operation");
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
            
    STAssertTrue(hasFinished, @"Conductor should add and complete test operation");
}

- (void)testConductorAddOperationToQueueNamed {
    
    __block BOOL hasFinished = NO;
    
    void (^completionBlock)(void) = ^(void) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            hasFinished = YES;        
        });
    };         
    
    CDTestOperation *op = [CDTestOperation operation];
    op.completionBlock = completionBlock;
    
    [conductor addOperation:op toQueueNamed:@"CustomQueueName"];
            
    STAssertNotNil([conductor queueForQueueName:@"CustomQueueName" shouldCreate:NO], @"Conductor should have queue for operation");
    
    NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:5];
    while (hasFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:loopUntil];
    }    
    
    STAssertTrue(hasFinished, @"Conductor should add and complete test operation");
}

- (void)testConductorUpdateQueuePriority {
    
    
    
}

@end