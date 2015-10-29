/**
 *
 * ML4iOSTests.m
 * ML4iOSTests
 *
 * Created by Felix Garcia Lainez on May 26, 2012
 * Copyright 2012 Felix Garcia Lainez
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

#import "ML4iOSTests.h"
#import "ML4iOS.h"
#import "Constants.h"
#import "objc/message.h"

@implementation ML4iOSTests {
    
    NSString* sourceId;
    NSString* datasetId;
}

- (void)setUp {
    [super setUp];
    
    //apiLibrary = [[ML4iOS alloc]initWithUsername:@"YOUR_BIGML_USERNAME" key:@"YOUR_BIGML_API_KEY" developmentMode:NO];
    [apiLibrary setDelegate:self];
    
    sourceId = [self createAndWaitSourceFromCSV:[[NSBundle bundleForClass:[ML4iOSTests class]] pathForResource:@"iris" ofType:@"csv"]];
    XCTAssert(sourceId, @"Could not create source");

    datasetId = [self createAndWaitDatasetFromSourceId:sourceId];
    XCTAssert(datasetId, @"Could not create dataset");
}

- (void)tearDown {
    
    [apiLibrary cancelAllAsynchronousOperations];
    [apiLibrary deleteSourceWithIdSync:sourceId];
    [apiLibrary deleteDatasetWithIdSync:datasetId];
    
    [super tearDown];
}

- (NSString*)typeFromFullUuid:(NSString*)fullUuid {
    
    return [fullUuid componentsSeparatedByString:@"/"].firstObject;
}

- (NSInteger)resourceStatus:(NSDictionary*)resource {
    
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"get%@WithIdSync:statusCode:",
                                         [[self typeFromFullUuid:resource[@"resource"]] capitalizedString]]);
    NSInteger statusCode = 0;
    NSString* identifier = [ML4iOS getResourceIdentifierFromJSONObject:resource];
    NSDictionary* dataSource = objc_msgSend(apiLibrary, selector, identifier, &statusCode);
    
    return [dataSource[@"status"][@"code"] intValue];
}

- (NSString*)waitResource:(NSDictionary*)resource finalExpectedStatus:(NSInteger)expectedStatus sleep:(float)duration {
    
    NSInteger status = 0;
    while ((status = [self resourceStatus:resource]) != expectedStatus) {
        XCTAssert(status > 0, @"Failed creating resource!");
        sleep(duration);
    }
    return [ML4iOS getResourceIdentifierFromJSONObject:resource];
}

- (NSString*)createAndWaitSourceFromCSV:(NSString*)path {
    
    NSInteger httpStatusCode = 0;
    NSDictionary* dataSource = [apiLibrary createSourceWithNameSync:@"iris.csv" project:nil filePath:path statusCode:&httpStatusCode];
    
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating data source from iris.csv");
    if (dataSource != nil && httpStatusCode == HTTP_CREATED) {
        
        return [self waitResource:dataSource finalExpectedStatus:5 sleep:1];
    }
    return nil;
}

- (NSString*)createAndWaitDatasetFromSourceId:(NSString*)srcId {
    
    NSInteger httpStatusCode = 0;
    NSDictionary* dataSet = [apiLibrary createDatasetWithDataSourceIdSync:srcId
                                                                     name:@"iris_dataset"
                                                               statusCode:&httpStatusCode];
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating dataset from iris_source");
    
    if(dataSet != nil && httpStatusCode == HTTP_CREATED) {

        return [self waitResource:dataSet finalExpectedStatus:5 sleep:1];
    }
}

- (NSString*)createAndWaitModelFromDatasetId:(NSString*)dataSetId {
    
    NSInteger httpStatusCode = 0;
    NSDictionary* model = [apiLibrary createModelWithDataSetIdSync:dataSetId
                                                              name:@"iris_model"
                                                        statusCode:&httpStatusCode];
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating model from iris_dataset");
    
    if(model != nil && httpStatusCode == HTTP_CREATED) {
        
        return [self waitResource:model finalExpectedStatus:5 sleep:3];
    }
}

- (NSString*)createAndWaitClusterFromDatasetId:(NSString*)dataSetId {
    
    NSInteger httpStatusCode = 0;
    NSDictionary* cluster = [apiLibrary createClusterWithDataSetIdSync:dataSetId
                                                                name:@"iris_model"
                                                          statusCode:&httpStatusCode];
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating cluster from iris_dataset");
    
    if(cluster != nil && httpStatusCode == HTTP_CREATED) {

        return [self waitResource:cluster finalExpectedStatus:5 sleep:3];
    }
}

- (NSString*)createAndWaitEnsembleFromDatasetId:(NSString*)dataSetId {
    
    NSInteger httpStatusCode = 0;
    NSDictionary* ensemble = [apiLibrary createEnsembleWithDataSetIdSync:dataSetId
                                                                 name:@"iris_model"
                                                           statusCode:&httpStatusCode];
    
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating model from iris_dataset");
    
    if (ensemble != nil && httpStatusCode == HTTP_CREATED) {
        
        return [self waitResource:ensemble finalExpectedStatus:5 sleep:3];
    }
}

- (NSString*)createAndWaitPredictionFromModelId:(NSString*)modelId {
    
    NSString* inputDataForPrediction = @"{\"000001\": 2, \"000002\": 1, \"000003\": 1}";

    NSInteger httpStatusCode = 0;
    NSDictionary* prediction = [apiLibrary createPredictionWithModelIdSync:modelId
                                                                      name:@"iris_prediction"
                                                                 inputData:inputDataForPrediction
                                                                statusCode:&httpStatusCode];
    
    XCTAssertEqual(httpStatusCode, HTTP_CREATED, @"Error creating prediction from iris_model");
    NSString* predictionId = nil;
    if (prediction != nil) {

        return [self waitResource:prediction finalExpectedStatus:5 sleep:1];
    }
    return predictionId;
}

- (NSDictionary*)localPredictionForModelId:(NSString*)modelId data:(NSString*)inputData byName:(BOOL)byName {
    
    NSInteger httpStatusCode = 0;
    
    if ([modelId length] > 0) {
        
        NSDictionary* irisModel = [apiLibrary getModelWithIdSync:modelId statusCode:&httpStatusCode];
        NSDictionary* prediction = [apiLibrary createLocalPredictionWithJSONModelSync:irisModel
                                                                            arguments:inputData
                                                                           argsByName:byName];
        
        XCTAssertNotNil([prediction objectForKey:@"value"], @"Local Prediction value can't be nil");
        XCTAssertNotNil([prediction objectForKey:@"confidence"], @"Local Prediction confidence can't be nil");
        
        return prediction;
    }
    return nil;
}

- (NSDictionary*)localPredictionForClusterId:(NSString*)clusterId
                                        data:(NSDictionary*)inputData
                                      byName:(BOOL)byName {
    
    NSInteger httpStatusCode = 0;
    
    if ([clusterId length] > 0) {
        
        NSDictionary* irisModel = [apiLibrary getClusterWithIdSync:clusterId statusCode:&httpStatusCode];
        NSDictionary* prediction = [apiLibrary createLocalCentroidsWithJSONModelSync:irisModel
                                                                           arguments:inputData
                                                                          argsByName:byName];
        
        XCTAssertNotNil([prediction objectForKey:@"centroidId"], @"Local Prediction centroidId can't be nil");
        XCTAssertNotNil([prediction objectForKey:@"centroidName"], @"Local Prediction centroidName can't be nil");
        
        return prediction;
    }
    return nil;
}

- (void)testModel {
    
    NSString* modelId = [self createAndWaitModelFromDatasetId:datasetId];
    XCTAssert(modelId);
    [apiLibrary deleteModelWithIdSync:modelId];
}

- (void)testCluster {
    
    NSString* clusterId = [self createAndWaitClusterFromDatasetId:datasetId];
    XCTAssert(clusterId);
    [apiLibrary deleteClusterWithIdSync:clusterId];
}

- (void)testEnsemble {
    
    NSString* identifier = [self createAndWaitEnsembleFromDatasetId:datasetId];
    XCTAssert(identifier);
    [apiLibrary deleteEnsembleWithIdSync:identifier];
}

- (void)testPrediction {
    
    NSString* modelId = [self createAndWaitModelFromDatasetId:datasetId];
    XCTAssert(modelId);
    
    NSString* predictionId = [self createAndWaitPredictionFromModelId:modelId];
    [apiLibrary deleteModelWithIdSync:modelId];
    XCTAssert(predictionId);
    
    [apiLibrary deletePredictionWithIdSync:predictionId];
}

- (void)testLocalPrediction {
    
    NSString* modelId = [self createAndWaitModelFromDatasetId:datasetId];
    NSDictionary* prediction = [self localPredictionForModelId:modelId
                                                          data:@"{\"000001\": 2, \"000002\": 1, \"000003\": 1}"
                                                        byName:NO];
    [apiLibrary deleteModelWithIdSync:modelId];
    XCTAssert(prediction);
}

- (void)testLocalPredictionByName {
    
    NSString* modelId = [self createAndWaitModelFromDatasetId:datasetId];
    NSDictionary* prediction = [self localPredictionForModelId:modelId
                                                          data:@"{\"sepal length\": 2, \"sepal width\": 1, \"petal length\": 1}"
                                                        byName:YES];
    [apiLibrary deleteModelWithIdSync:modelId];
    XCTAssert(prediction);
}

- (void)testLocalClusterPredictionByName {
    
    NSString* clusterId = [self createAndWaitClusterFromDatasetId:datasetId];
    NSDictionary* prediction = [self localPredictionForClusterId:clusterId
                                                            data:@{@"sepal length": @2, @"sepal width": @1, @"petal length": @1}
                                                          byName:YES];
    [apiLibrary deleteClusterWithIdSync:clusterId];
    XCTAssert(prediction);
}

- (void)testLocalClusterPrediction {
    
    NSString* clusterId = [self createAndWaitClusterFromDatasetId:datasetId];
    NSDictionary* prediction = [self localPredictionForClusterId:clusterId
                                                            data:@{@"000001": @2, @"000002": @1, @"000003": @1}
                                                          byName:NO];
    [apiLibrary deleteClusterWithIdSync:clusterId];
    XCTAssert(prediction);
}

#pragma mark -
#pragma mark ML4iOSDelegate

-(void)dataSourceCreated:(NSDictionary*)dataSource statusCode:(NSInteger)code
{
    
}

-(void)dataSourceUpdated:(NSDictionary*)dataSource statusCode:(NSInteger)code
{
    
}

-(void)dataSourceDeletedWithStatusCode:(NSInteger)code
{
    
}

-(void)dataSourcesRetrieved:(NSDictionary*)dataSources statusCode:(NSInteger)code
{
    
}

-(void)dataSourceRetrieved:(NSDictionary*)dataSource statusCode:(NSInteger)code
{
    
}

-(void)dataSourceIsReady:(BOOL)ready
{
    
}

-(void)datasetCreated:(NSDictionary*)dataSet statusCode:(NSInteger)code
{
    
}

-(void)datasetUpdated:(NSDictionary*)dataSet statusCode:(NSInteger)code
{
    
}

-(void)datasetDeletedWithStatusCode:(NSInteger)code
{
    
}

-(void)datasetsRetrieved:(NSDictionary*)dataSets statusCode:(NSInteger)code
{
    
}

-(void)datasetRetrieved:(NSDictionary*)dataSet statusCode:(NSInteger)code
{
    
}

-(void)datasetIsReady:(BOOL)ready
{
    
}

-(void)modelCreated:(NSDictionary*)model statusCode:(NSInteger)code
{
    
}

-(void)modelUpdated:(NSDictionary*)model statusCode:(NSInteger)code
{
    
}

-(void)modelDeletedWithStatusCode:(NSInteger)code
{
    
}

-(void)modelsRetrieved:(NSDictionary*)models statusCode:(NSInteger)code
{
    
}

-(void)modelRetrieved:(NSDictionary*)model statusCode:(NSInteger)code
{
    
}

-(void)modelIsReady:(BOOL)ready
{
    
}

-(void)predictionCreated:(NSDictionary*)prediction statusCode:(NSInteger)code
{
    
}

-(void)predictionUpdated:(NSDictionary*)prediction statusCode:(NSInteger)code
{
    
}

-(void)predictionDeletedWithStatusCode:(NSInteger)code
{
    
}

-(void)predictionsRetrieved:(NSDictionary*)predictions statusCode:(NSInteger)code
{
    
}

-(void)predictionRetrieved:(NSDictionary*)prediction statusCode:(NSInteger)code
{
    
}

-(void)predictionIsReady:(BOOL)ready
{
}

-(void)projectCreated:(NSDictionary*)project statusCode:(NSInteger)code
{
}

-(void)projectUpdated:(NSDictionary*)project statusCode:(NSInteger)code
{
}

-(void)projectDeletedWithStatusCode:(NSInteger)code
{
}

-(void)projectsRetrieved:(NSDictionary*)projects statusCode:(NSInteger)code
{
}

-(void)projectRetrieved:(NSDictionary*)project statusCode:(NSInteger)code
{
}

-(void)projectIsReady:(BOOL)ready
{
}

-(void)clusterCreated:(NSDictionary*)cluster statusCode:(NSInteger)code
{
}

-(void)clusterUpdated:(NSDictionary*)cluster statusCode:(NSInteger)code
{
}

-(void)clusterDeletedWithStatusCode:(NSInteger)code
{
}

-(void)clustersRetrieved:(NSDictionary*)clusters statusCode:(NSInteger)code
{
}

-(void)clusterRetrieved:(NSDictionary*)cluster statusCode:(NSInteger)code {
}

-(void)clusterIsReady:(BOOL)ready {
}

-(void)ensembleCreated:(NSDictionary*)ensemble statusCode:(NSInteger)code
{
}

-(void)ensembleUpdated:(NSDictionary*)ensemble statusCode:(NSInteger)code
{
}

-(void)ensembleDeletedWithStatusCode:(NSInteger)code
{
}

-(void)ensemblesRetrieved:(NSDictionary*)ensembles statusCode:(NSInteger)code
{
}

-(void)ensembleRetrieved:(NSDictionary*)ensemble statusCode:(NSInteger)code {
}

-(void)ensembleIsReady:(BOOL)ready {
}

@end