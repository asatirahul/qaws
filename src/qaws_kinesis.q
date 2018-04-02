/ ==============================================
/ Kinesis API. Supports AWS Kinesis Functions
/ ==============================================
\d .qaws_kinesis

/ ---------------------------------
/    APPLICATION CONSTANTS
/ ---------------------------------
Decode :1 ; / Decode return from functions (json to Q dict). Set it to 0 to get Json Return

/ ---------------------------------
/    KINESIS API
/ ---------------------------------

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_AddTagsToStream.html
/ @param Stream (String) Kinesis stream name
/ @param Tags (dict) Tags dictionary (String!string)
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
add_tags_to_stream:{[Stream;Tags; Region]
  body: `StreamName`Tags!(Stream;Tags);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.AddTagsToStream";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_CreateStream.html
/ @param Stream (String) Kinesis stream name
/ @param ShardCount (int) Number of shards to create (between 1 and 100000)
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
create_stream:{[Stream;ShardCount;Region]
  if[not ShardCount within (1,100000); 'Wrong_Shard_Count];
  body:`StreamName`ShardCount!(Stream;ShardCount);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.CreateStream";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DecreaseStreamRetentionPeriod.html
/ @param Stream (String) Kinesis stream name
/ @param Retention (int) Retention priod in hours. Min is 24
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
decrease_stream_retention_period:{[Stream;Retention;Region]
  body:`StreamName`RetentionPeriodHours!(Stream;Retention);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DecreaseStreamRetentionPeriod";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DeleteStream.html
/ @param Stream (String) Kinesis stream name
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
delete_stream:{[Stream;Region]
 body: enlist[`StreamName]!enlist Stream;
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DeleteStream";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeLimits.html
/ @return (dict) as per aws doc (currently it returns OpenShardCount and  ShardLimit)
describe_limits:{[Region]
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeLimits";()!();Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStream.html
/ @param Stream (String) Kinesis stream name
/ @Opts (dict) Optional params (`limit`exclusivestartshardid !(int;string)). Default is empty dict ()!()
/ @param Region (String) Aws region
/ @return (dict) Stream information as per aws documentation converted to Q dict
describe_stream:{[Stream;Opts;Region]
  body: enlist[`StreamName]!enlist Stream;
  k:$[not `limit in key Opts;();Opts[`limit] within (1;10000);(`Limit`limit);()];
  k:2 cut k,(();(`ExclusiveStartShardId`exclusivestartshardid))`exclusivestartshardid in key Opts;
  body:body,k[;0]!Opts k[;1];
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeStream";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStreamSummary.html
/ @param Stream (String) Kinesis stream name
/ @param Region (String) Aws region
/ @return (dict)
describe_stream_summary:{[Stream;Region]
  body: enlist[`StreamName]!enlist Stream;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeStreamSummary";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DisableEnhancedMonitoring.html
/ @param Stream (String) Kinesis stream name
/ @param Monitors (list of Strings or Symbols) Supported Monitors tag. Check aws page for valid tags
/ @param Region (String) Aws region
/ @return (dict) Check aws page for retrn data
disable_enhanced_monitoring:{[Stream; Monitors; Region]
  body:`StreamName`ShardLevelMetrics!(Stream;Monitors);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DisableEnhancedMonitoring";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_EnableEnhancedMonitoring.html
/ @param Stream (String) Kinesis stream name
/ @param Monitors (list of Strings or Symbols)  - Supported Monitors tag. Check aws page for valid tags
/ @param Region (String) Aws region
/ @return (dict) Check aws page for retrn data
enable_enhanced_monitoring:{[Stream; Monitors; Region]
 body:`StreamName`ShardLevelMetrics!(Stream;Monitors);
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.EnableEnhancedMonitoring";body;Decode]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_IncreaseStreamRetentionPeriod.html
/ @param Stream (String) Kinesis stream name
/ @param Retention (int) Retention priod in hours. Min is 24
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
increase_stream_retention_period:{[Stream;Retention;Region]
  body:`StreamName`RetentionPeriodHours!(Stream;Retention);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.IncreaseStreamRetentionPeriod";body;Decode]
 };

list_streams:{[Region;Opts]
   body: ()!(); / enlist[`StreamName]!enlist StreamName;
   /k:$[not `limit in key Opts;();Opts[`limit] within (1;10000);(`Limit`limit);()];
   /k:2 cut k,(();(`ExclusiveStartShardId`exclusivestartshardid))`exclusivestartshardid in key Opts;
   /body:body,k[;0]!Opts k[;1];
   .qaws_kinesis_impl.request[Region;"Kinesis_20131202.ListStreams";body;Decode]
 };

\d .
