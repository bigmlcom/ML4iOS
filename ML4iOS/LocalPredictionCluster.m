//
//  LocalPredictionCluster.m
//  BigMLX
//
//  Created by sergio on 23/09/14.
//  Copyright (c) 2014 sergio. All rights reserved.
//

#import "LocalPredictionCluster.h"
#import "LocalPredictionCentroid.h"

#define TM_TOKENS @"tokens_only"
#define TM_FULL_TERM @"full_terms_only"

@interface LocalPredictionCluster ()

@property (nonatomic, strong) NSDictionary* fields;
@property (nonatomic, strong) NSMutableDictionary* termForms;
@property (nonatomic, strong) NSMutableDictionary* tagClouds;
@property (nonatomic, strong) NSMutableDictionary* termAnalysis;
@property (nonatomic, strong) NSMutableArray* centroids;
@property (nonatomic, strong) NSDictionary* scales;

//@property (nonatomic, strong) NSDictionary* invertedFields;
@property (nonatomic, strong) NSString* description;
@property (nonatomic, strong) NSString* locale;
@property (nonatomic) BOOL ready;

@end

/** A lightweight wrapper around a cluster model.

Uses a BigML remote cluster model to build a local version that can be used
to generate centroid predictions locally.

**/
@implementation LocalPredictionCluster

- (void)fillStructureForResource:(NSDictionary*)resourceDict {
    
    self.termForms = [NSMutableDictionary dictionary];
    self.tagClouds = [NSMutableDictionary dictionary];
    self.termAnalysis = [NSMutableDictionary dictionary];
    
    NSDictionary* clusters = resourceDict[@"clusters"][@"clusters"];
    self.centroids = [NSMutableArray array];
    for (id cluster in clusters) {
        [_centroids addObject:[[LocalPredictionCentroid alloc] initWithCluster:cluster]];
    }
    self.scales = resourceDict[@"scales"];
    NSDictionary* fields = resourceDict[@"clusters"][@"fields"];
    for (NSString* fieldId in [fields allKeys]) {
        
        NSDictionary* field = fields[fieldId];
        if ([field[@"optype"] isEqualToString:@"text"]) {
            self.termForms[fieldId] = field[@"summary"][@"term_forms"];
            self.tagClouds[fieldId] = field[@"summary"][@"tag_cloud"];
            self.termAnalysis[fieldId] = field[@"term_analysis"];
        }
    }
    self.fields = fields;
//    self.invertedFields = utils.invertObject(fields);
    self.description = resourceDict.description;
    self.locale = resourceDict[@"locale"] ?: @"";
    self.ready = true;
}

- (instancetype)initWithCluster:(NSDictionary*)resourceDict {
    
    if (self = [super init]) {
        
//        if ([resourceDict isIncomplete]) {
        
//        } else {
        [self fillStructureForResource:resourceDict];
//        }
    }
    return self;
}

- (NSMutableArray*)parsePhrase:(NSString*)phrase isCaseSensitive:(BOOL)isCaseSensitive {
 
    NSMutableArray* words = [[phrase componentsSeparatedByCharactersInSet:[NSCharacterSet  whitespaceCharacterSet]] mutableCopy];
    
    if (!isCaseSensitive) {
        for (short i = 0; i < words.count; ++i) {
            words[i] = [words[i] lowercaseString];
        }
    }
    return words;
}

- (NSMutableArray*)uniqueTermsInArray1:(NSArray*)array1
                                array2:(NSArray*)array2
                                filter:(NSArray*)filter {
 
    NSMutableDictionary* extendForms = [NSMutableDictionary dictionary];
    NSMutableArray* termSet = [NSMutableArray array];
    NSMutableArray* tagTerms = [NSMutableArray array];
    
    for (id term in filter)
        [tagTerms addObject:term];
    
    for (id term in array2) {

    }
    
    return termSet;
}

//function getUniqueTerms(terms, termForms, tagCloud) {
//    ...
//    for (term in termForms) {
//        if (termForms.hasOwnProperty(term)) {
//            termFormsLength = termForms[term].length;
//            for (i = 0; i < termFormsLength; i++) {
//                termForm = termForms[term][i];
//                extendForms[termForm] = term;
//            }
//            extendForms[termForm] = term;
//        }
//    }
//    for (i = 0; i < termsLength; i++) {
//        term = terms[i];
//        if ((termsSet.indexOf(term) < 0) && tagTerms.indexOf(term) > -1) {
//            termsSet.push(term);
//        } else if ((termsSet.indexOf(term) < 0) &&
//                   extendForms.hasOwnProperty(term)) {
//            termsSet.push(extendForms[term]);
//        }
//    }
//    return termsSet;
//}




- (NSDictionary*)computeNearest:(NSDictionary*)inputData {
    
    NSMutableArray* terms = nil;
    NSMutableDictionary* uniqueTerms = [NSMutableDictionary dictionary];
    
    for (NSString* fieldId in [self.tagClouds allKeys]) {
        
        BOOL isCaseSensitive = [self.termAnalysis[fieldId][@"case_sensitive"] boolValue];
        NSString* tokenMode = self.termAnalysis[fieldId][@"tokenMode"];
        NSString* inputDataField = inputData[fieldId];
        if (![tokenMode isEqualToString:TM_FULL_TERM]) {
            terms = [self parsePhrase:inputDataField isCaseSensitive:isCaseSensitive];
        } else {
            terms = [NSMutableArray array];
        }
        if (![tokenMode isEqualToString:TM_TOKENS]) {
            [terms addObject:(isCaseSensitive ? inputDataField : [inputDataField lowercaseString])];
        }
        uniqueTerms[fieldId] = [self uniqueTermsInArray1:terms
                                                  array2:self.termForms[fieldId]
                                                  filter: self.tagClouds[fieldId]];
    }
    
    NSMutableDictionary* nearest = [@{ @"centroidId":@"",
                                      @"centroidName":@"",
                                      @"distance":@"" } mutableCopy];
    
    for (LocalPredictionCentroid* centroid in self.centroids) {
        
        float distance2 = [centroid distance2WithInputData:inputData
                                               uniqueTerms:uniqueTerms
                                                    scales:self.scales
                                           nearestDistance:[nearest[@"distance"] floatValue]];
        
        if (distance2 < [nearest[@"distance"] floatValue]) {
            
            nearest = [@{ @"centroidId":@(centroid.centroidId),
                         @"centroidName":centroid.name,
                         @"distance":@(distance2) } mutableCopy];
        }
    }
    
    nearest[@"distance"] = @( sqrt([nearest[@"distance"] floatValue]) );
    return nearest;
}


//LocalCluster.prototype.centroid = function (inputData, cb) {
//    /**
//     * Makes a centroid prediction based on a number of field values.
//     *
//     * The input fields must be keyed by field name or field id.
//     * @param {object} inputData Input data to predict
//     * @param {function} cb Callback
//     */
//    var newInputData = {}, field, centroid, clustersLength, self = this;
//    
//    function createLocalCentroid(error, inputData) {
//        /**
//         * Creates a local centroid using the cluster info.
//         *
//         * @param {object} error Error message
//         * @param {object} data Input data to predict from
//         */
//        if (error) {
//            return cb(error, null);
//        }
//        return cb(null, self.computeNearest(inputData));
//    }
//    
//    if (this.ready) {
//        if (cb) {
//            this.validateInput(inputData, createLocalCentroid);
//        } else {
//            centroid = this.computeNearest(this.validateInput(inputData));
//            return centroid;
//        }
//    } else {
//        this.on('ready', function (self) {return self.centroid(inputData, cb); });
//        return;
//    }
//};
//
//LocalCluster.prototype.validateInput = function (inputData, cb) {
//    /**
//     * Validates the syntax of input data.
//     *
//     * The input fields must be keyed by field name or field id.
//     * @param {object} inputData Input data to predict
//     * @param {function} cb Callback
//     */
//    var newInputData = {}, field, fieldId, inputDataKey;
//    for (fieldId in this.fields) {
//        if (this.fields.hasOwnProperty(fieldId)) {
//            field = this.fields[fieldId];
//            if (field.optype !== "categorical" && field.optype !== "text" &&
//                !inputData.hasOwnProperty(fieldId) &&
//                !inputData.hasOwnProperty(field.name)) {
//                throw new Error("The input data lacks some numeric fields values." +
//                                " To find the related centroid, input data must " +
//                                "contain all numeric fields values.");
//            }
//        }
//    }
//    if (this.ready) {
//        for (field in inputData) {
//            if (inputData.hasOwnProperty(field)) {
//                if (inputData[field] === null ||
//                    (typeof this.fields[field] === 'undefined' &&
//                     typeof this.invertedFields[field] === 'undefined')) {
//                        delete inputData[field];
//                    } else {
//                        // input data keyed by field id
//                        if (typeof this.fields[field] !== 'undefined') {
//                            inputDataKey = field;
//                        } else { // input data keyed by field name
//                            inputDataKey = String(this.invertedFields[field]);
//                        }
//                        newInputData[inputDataKey] = inputData[field];
//                    }
//            }
//        }
//        try {
//            inputData = utils.cast(newInputData, this.fields);
//        } catch (err) {
//            if (cb) {
//                return cb(err, null);
//            }
//            throw err;
//        }
//        if (cb) {
//            return cb(null, inputData);
//        }
//        return inputData;
//    }
//    this.on('ready', function (self) {
//        return self.validateInput(inputData, cb);
//    });
//    return;
//};


@end
