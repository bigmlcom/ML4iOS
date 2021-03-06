// Copyright 2014-2015 BigML
//
// Licensed under the Apache License, Version 2.0 (the "License"); you may
// not use this file except in compliance with the License. You may obtain
// a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

#import <Foundation/Foundation.h>
#import "ML4iOS.h"
#import "ML4iOSDelegate.h"

@interface ML4iOSTester : ML4iOS <ML4iOSDelegate>

@property (nonatomic, strong) NSString* datasetId;
@property (nonatomic, strong) NSString* csvFileName;

- (NSString*)createAndWaitSourceFromCSV:(NSString*)path;
- (NSString*)createAndWaitDatasetFromSourceId:(NSString*)srcId;
- (NSString*)createAndWaitModelFromDatasetId:(NSString*)dataSetId;
- (NSString*)createAndWaitClusterFromDatasetId:(NSString*)dataSetId;
- (NSString*)createAndWaitEnsembleFromDatasetId:(NSString*)dataSetId;
- (NSString*)createAndWaitAnomalyFromDatasetId:(NSString*)dataSetId;
- (NSString*)createAndWaitPredictionFromId:(NSString*)modelId
                              resourceType:(NSString*)resourceTyp
                                 inputData:(NSDictionary*)inputData;

- (NSDictionary*)remotePredictionForId:(NSString*)resourceId
                          resourceType:(NSString*)resourceType
                                  data:(NSDictionary*)inputData
                               options:(NSDictionary*)options;

- (NSDictionary*)localPredictionForModelId:(NSString*)modelId
                                      data:(NSDictionary*)inputData
                                   options:(NSDictionary*)options;

- (NSDictionary*)localPredictionForEnsembleId:(NSString*)ensembleId
                                         data:(NSDictionary*)inputData
                                      options:(NSDictionary*)options;

- (NSDictionary*)localPredictionForClusterId:(NSString*)clusterId
                                        data:(NSDictionary*)inputData
                                     options:(NSDictionary*)options;

- (double)localAnomalyScoreForAnomalyId:(NSString*)anomalyId
                                   data:(NSDictionary*)inputData
                                options:(NSDictionary*)options;

- (BOOL)compareFloat:(double)f1 float:(float)f2;
- (BOOL)comparePrediction:(NSDictionary*)prediction1 andPrediction:(NSDictionary*)prediction2;
- (BOOL)compareConfidence:(NSDictionary*)prediction1 andConfidence:(NSDictionary*)prediction2;

@end
