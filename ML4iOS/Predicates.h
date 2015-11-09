/**
 *
 * Predicate.h
 * ML4iOS
 *
 * Created by Sergio De Simone on November, 5 2015
 * Copyright 2015 BigML, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import <Foundation/Foundation.h>

typedef enum PredicateLanguage {
    
    PredicateLanguagePseudoCode,
    
} PredicateLanguage;

@interface RegExHelper : NSObject

+ (NSString*)firstRegexMatch:(NSString*)regex in:(NSString*)string;
+ (BOOL)isRegex:(NSString*)regex matching:(NSString*)string;

@end


/**
 * A predicate to be evaluated in a tree's node.
 */
@interface Predicate : NSObject

@property (nonatomic, strong) NSString* op;
//@property (nonatomic, strong) NSString* predicateOperator;
@property (nonatomic, strong) NSString* field;
@property (nonatomic, strong) NSString* value;
@property (nonatomic) BOOL missing;

- (BOOL)apply:(NSDictionary*)input fields:(NSDictionary*)fields;
- (NSString*)ruleWithFields:(NSDictionary*)fields label:(NSString*)label;

@end


@interface Predicates : NSObject
@end