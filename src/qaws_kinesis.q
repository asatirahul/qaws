/ ==============================================
/ Q AWS Kinesis API. Supports AWS Kinesis Functions

/ NOTE 1: This api does not run checks on function parameters validation. Thats done by aws so make sure you pass correct values to functions.
/ In case of worng input function will return error message as recieved from aws.
/ Refer to AWS wiki mentioned in each function doc to get details about function parameters.

/ Note 2: AWS Funtions which have optional fields uses Opts dictionary as a parameter. Put key-values in this if you want to use optional fields.
/ Refere to Aws wiki for that function to see optional fields.
/ ==============================================
\d .qaws_kinesis

/ ---------------------------------
/    APPLICATION CONSTANTS
/ ---------------------------------
DECODE :1 ; / DECODE return from functions (json to Q dict). Set it to 0 to get Json Return

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
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.AddTagsToStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_CreateStream.html
/ @param Stream (String) Kinesis stream name
/ @param ShardCount (int) Number of shards to create (between 1 and 100000)
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
create_stream:{[Stream;ShardCount;Region]
  if[not ShardCount within (1,100000); 'Wrong_Shard_Count];
  body:`StreamName`ShardCount!(Stream;ShardCount);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.CreateStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DecreaseStreamRetentionPeriod.html
/ @param Stream (String) Kinesis stream name
/ @param Retention (int) Retention priod in hours. Min is 24
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
decrease_stream_retention_period:{[Stream;Retention;Region]
  body:`StreamName`RetentionPeriodHours!(Stream;Retention);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DecreaseStreamRetentionPeriod";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DeleteStream.html
/ @param Stream (String) Kinesis stream name
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
delete_stream:{[Stream;Region]
 body: enlist[`StreamName]!enlist Stream;
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DeleteStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeLimits.html
/ @return (dict) as per aws doc (currently it returns OpenShardCount and  ShardLimit)
describe_limits:{[Region]
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeLimits";()!();DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStream.html
/ @param Stream (String) Kinesis stream name
/ @Opts (dict) Optional params. Check aws page for details. (`Limit`ExclusiveStartShardId !(int;string)). Default is empty dict ()!()
/ @param Region (String) Aws region
/ @return (dict) Stream information as per aws documentation converted to Q dict
describe_stream:{[Stream;Opts;Region]
  body: (enlist[`StreamName]!enlist Stream), Opts;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DescribeStreamSummary.html
/ @param Stream (String) Kinesis stream name
/ @param Region (String) Aws region
/ @return (dict)
describe_stream_summary:{[Stream;Region]
  body: enlist[`StreamName]!enlist Stream;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeStreamSummary";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_DisableEnhancedMonitoring.html
/ @param Stream (String) Kinesis stream name
/ @param Monitors (list of Strings or Symbols) Supported Monitors tag. Check aws page for valid tags
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
disable_enhanced_monitoring:{[Stream; Monitors; Region]
  body:`StreamName`ShardLevelMetrics!(Stream;Monitors);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DisableEnhancedMonitoring";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_EnableEnhancedMonitoring.html
/ @param Stream (String) Kinesis stream name
/ @param Monitors (list of Strings or Symbols)  - Supported Monitors tag. Check aws page for valid tags
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
enable_enhanced_monitoring:{[Stream; Monitors; Region]
 body:`StreamName`ShardLevelMetrics!(Stream;Monitors);
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.EnableEnhancedMonitoring";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetRecords.html
/ @param Iterator (String) Shard iterator
/ @param Opts (dict) aws options - enlist[`Limit]!enlist int
/ @param Region (Strings) Aws Region
/ @ return (dict) check aws page
get_records:{[Iterator;Opts;Region]
  body: Opts,enlist[`ShardIterator]!enlist Iterator;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.GetRecords";body;DECODE]
 };

/ return b64 decoded data
get_records_decode:{[Iterator;Opts;Region]  get_decoded_records[Iterator;Opts;Region;0] };

/ if encoded data is Json then first b64 decode data and parse json data in Q dict
get_records_decode_json:{[Iterator;Opts;Region]  get_decoded_records[Iterator;Opts;Region;1] };

get_decoded_records:{[Iterator;Opts;Region;Json]
  r:get_records[Iterator;Opts;Region];
  if[0<count d:r[`result;`Records];r[`result;`Records]: ((.cryptoq.b64_decode;.cryptoq.b64_json_decode)Json) @'d `Data];
  r
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_GetShardIterator.html
/ @param Stream (String) Kinesis stream name
/ @param ShardId (String) Kinesis shard id
/ @param IteratorType (String) IteratorType - check aws page for supported types
/ @param Opts (dict) check aws for other fields; - (`StartingSequenceNumber`Timestamp!(String;Int))
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
get_shard_iterator:{[Stream; ShardId; IteratorType; Opts; Region]
  body:Opts,`StreamName`ShardId`ShardIteratorType!(Stream;ShardId;IteratorType);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.GetShardIterator";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_IncreaseStreamRetentionPeriod.html
/ @param Stream (String) Kinesis stream name
/ @param Retention (int) Retention priod in hours. Min is 24
/ @param Region (String) Aws region
/ @return (Empty String) empty string for successfull Operation
increase_stream_retention_period:{[Stream;Retention;Region]
  body:`StreamName`RetentionPeriodHours!(Stream;Retention);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.IncreaseStreamRetentionPeriod";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_ListShards.html
/ @param Stream (String) Kinesis stream name
/ @param Opts (dict) Other supported params - (`ExclusiveStartShardId`MaxResults`NextToken`StreamCreationTimestamp!(String;Int;String;Int))
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
list_shards:{[Stream; Opts; Region]
  body:$[""~Stream;()!();enlist[`StreamName]!enlist Stream],Opts;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.ListShards";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_ListStreams.html
/ @param Opts (dict) Other supported params - (`ExclusiveStartStreamName`Limit!(String;Int))
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
list_streams:{[Opts;Region]
   .qaws_kinesis_impl.request[Region;"Kinesis_20131202.ListStreams";Opts;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_ListTagsForStream.html
/ @param Stream (String) Kinesis stream name
/ @param Opts (dict) Other supported params. Check aws page for details. (`ExclusiveStartTagKey`Limit!(String;Int))
/ @param Region (String) Aws region
/ @return (dict) Check aws page for return data
list_tags_for_stream:{[Stream;Opts;Region]
  body:(enlist[`StreamName]!enlist Stream),Opts;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.ListTagsForStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_MergeShards.html
/ @param Stream (String) Kinesis stream name
/ @param Shard (String) Shard id to merge
/ @param AdjacentShard (String) Adjacent Shard id to merge
/ @param Region (String) Aws region
/ @return (empty string) ""
merge_shards:{[Stream; Shard; AdjacentShard; Region]
  body:`StreamName`ShardToMerge`AdjacentShardToMerge!(Stream;Shard;AdjacentShard);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.MergeShards";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecord.html
/ @param Stream (String) Kinesis stream name
/ @param PartKey (String) Partition key for stream
/ @param Data (Blob) Data to send
/ @param Encode (boolean) whether to encode data or not. In case yes it will be converted to json first and then base64 encoded
/ @param Opts (dict) asws params `ExplicitHashKey`SequenceNumberForOrdering(String;String)
/ @param Region (String) Aws region
/ @return (dict) check  aws page
put_record:{[Stream;PartKey;Data;Encode;Opts;Region]
  body: `StreamName`PartitionKey`Data!(Stream;PartKey;$[Encode;.cryptoq.b64_json_encode Data;Data]);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.PutRecord";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_PutRecords.html
/ @param Stream (String) Kinesis stream name
/ @param Records (list of dict) dict keys as per aws `Data`PartitionKey`ExplicitHashKey!(String;String;String). `ExplicitHashKey is optional
/ @param Encode (boolean) whether to encode data or not. In case yes it will be converted to json first and then base64 encoded
/ @param Region (String) Aws region
/ @return (dict) check aws page
put_records:{[Stream;Records;Encode;Region]
  if[Encode; Records[`Data]:.cryptoq.b64_json_encode@'Records`Data];
  body:`StreamName`Records!(Stream;Records);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.PutRecords";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_RemoveTagsFromStream.html
/ @param Stream (String) Kinesis stream name
/ @param Tags (List of Strings or Symbols) Tags list
/ @param Region (String) Aws region
/ @return (empty string) ""
remove_tags_from_stream:{[Stream; Tags; Region]
  body:`StreamName`TagKeys!(Stream;Tags);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.RemoveTagsFromStream";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_SplitShard.html
/ @param Stream (String) Kinesis stream name
/ @param Shard (String) Shard id
/ @param HaskKey (String) HashKey
/ @param Region (String) Aws region
/ @return (empty string) ""
split_shard:{[Stream; Shard; HashKey; Region]
  body:`StreamName`ShardToSplit`NewStartingHashKey!(Stream;Shard;HashKey);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.SplitShard";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_StartStreamEncryption.html
/ @param Stream (String) Kinesis stream name
/ @param Encryption (String) EncryptionType
/ @param Key (String) KeyId - GUID
/ @return (dict) `status`result . status is ok or error code. Check aws page for result reponse format
start_stream_encryption:{[Stream; Encryption; Key]
  body:`StreamName`EncryptionType`KeyId!(Stream;Encryption;Key);
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.StartStreamEncryption";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_StopStreamEncryption.html
/ @param Stream (String) Kinesis stream name
/ @param Encryption (String) EncryptionType
/ @param Key (String) KeyId - GUID
/ @return (dict) `status`result . status is ok or error code. Check aws page for result reponse format
stop_stream_encryption:{[Stream; Encryption; Key]
 body:`StreamName`EncryptionType`KeyId!(Stream;Encryption;Key);
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.StopStreamEncryption";body;DECODE]
 };

/ https://docs.aws.amazon.com/kinesis/latest/APIReference/API_UpdateShardCount.html
/ @param Stream (String) Kinesis Stream name
/ @param ShardCount (int) new shard count
/ @param ScalingType (String) Aws supported scaling type. check aws page
/ @return (dict) `status`result . status is ok or error code. Check aws page for result reponse format
update_shard_count:{[Stream; ShardCount; ScalingType;Region]
 body:`StreamName`TargetShardCount`ScalingType!(Stream; ShardCount; ScalingType);
 .qaws_kinesis_impl.request[Region;"Kinesis_20131202.UpdateShardCount";body;DECODE];
 };

\d .
