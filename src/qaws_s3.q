\d .qaws_s3

XMLNS_S3: "http://s3.amazonaws.com/doc/2006-03-01/";
XMLNS_SCHEMA_INSTANCE: "http://www.w3.org/2001/XMLSchema-instance";
S3REGION:.aws_config.aws`region;

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUT.html
/ For supported ACL details https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html
/ @param BucketName (String) s3 bucket name
/ @param Opts (dict Symbol!String) Currently `LocationConstaint is required. Can contain other optional params mentioned on aws wiki. For ex `ACL`LocationConstraint or permission headers.
/ @param Region (String) Aws region
/ @return (dict) http output
/ @example: create_bucket["test-bucket";enlist[`LocationConstaint]!enlist["us-west-2"];"us-west-2"]
create_bucket:{[BucketName;LocationConstraint;Opts]
  acl:$[`ACL in key Opts;Opts `ACL;"private"];
  headers:$[any key[Opts] like "x-*"; Opts;.awsutils.append_header["x-amz-acl";acl;Opts]]; / add acl if no permisions are persent (x-* format)
  /location:$[(l:`LocationConstraint) in key Opts;Opts l;""];
  xml:"<?xml version=\"1.0\"?><CreateBucketConfiguration xmlns=\"",XMLNS_S3,"\"><LocationConstraint>",LocationConstraint,"</LocationConstraint></CreateBucketConfiguration>";
  postdata:$[""~LocationConstraint;"";xml];
  region:$[LocationConstraint~"";.aws_config.aws `region;LocationConstraint];
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/"; ""; ()!(); postdata; headers;region]
 };


/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketDELETE.html
/ @param BucketName (String) s3 bucket name
/ @param Region (String) Aws region for S3 bucket
/ @return (dict) http output
/ @example delete_bucket["test-bucket"]
/ TODO handle redirect and region =""
delete_bucket:{[BucketName]
  .qaws_s3_impl.s3_simple_request[`delete; BucketName; 1#"/";"";()!();"";()!();.aws_config.aws`region]
 };

delete_bucket_attribute:{[BucketName;Attr]
  .qaws_s3_impl.s3_simple_request[`delete; BucketName; 1#"/";Attr;()!();"";()!();.aws_config.aws`region]
 };

delete_bucket_cors:{[BucketName] delete_bucket_attribute[BucketName;"cors"] };
/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketDELETEencryption.html
delete_bucket_encryption:{[BucketName] delete_bucket_attribute[BucketName;"encryption"] };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketDELETEInventoryConfiguration.html
/ @param BucketName (String) s3 bucket name
/ @param InventoryId (String) Inventory id
delete_bucket_inventory:{[BucketName;InventoryId]
  params:enlist["id"]!enlist `$InventoryId;
  .qaws_s3_impl.s3_simple_request[`delete; BucketName; 1#"/";"inventory";params;"";()!();.aws_config.aws`region]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketDELETElifecycle.html
delete_bucket_lifecycle:{[BucketName] delete_bucket_attribute[BucketName;"lifecycle"] };
delete_bucket_policy:{[BucketName] delete_bucket_attribute[BucketName;"policy"] };
delete_bucket_replication:{[BucketName] delete_bucket_attribute[BucketName;"replication"] };
delete_bucket_tagging:{[BucketName] delete_bucket_attribute[BucketName;"tagging"] };
delete_bucket_website:{[BucketName] delete_bucket_attribute[BucketName;"website"] };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/v2-RESTBucketGET.html
/ @param BucketName (String) s3 bucket name
/ @param Params (dict) request parameters. Check wiki for tags. Dict should be=> Symbol list ! string list.
/ example: get_bucket["my_bucket"; enlist[`$"max-keys"]!enlist "2"]
get_bucket:{[BucketName;Params]
  qparams:(enlist[`$"list-type"]! enlist "2"), Params;
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"";qparams;"";()!();S3REGION]
 };

get_bucket_attribute:{[BucketName;Attr]
 .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";Attr;()!();"";()!();S3REGION]
 };

get_bucket_accelerate:{[BucketName] get_bucket_attribute[BucketName;"accelerate"]};
get_bucket_acl:{[BucketName] get_bucket_attribute[BucketName;"acl"]};
get_bucket_cors:{[BucketName] get_bucket_attribute[BucketName;"cors"]};
get_bucket_encryption:{[BucketName] get_bucket_attribute[BucketName;"encryption"]};

get_bucket_inventory:{[BucketName;InventoryId]
  qparams:enlist[`id]!enlist string InventoryId;
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"inventory";qparams;"";()!();S3REGION]
 };

get_bucket_lifecycle:{[BucketName] get_bucket_attribute[BucketName;"lifecycle"]};
get_bucket_logging:{[BucketName] get_bucket_attribute[BucketName;"logging"]};
get_bucket_location:{[BucketName] get_bucket_attribute[BucketName;"location"]};

get_bucket_metrics:{[BucketName;MetricId]
  qparams:enlist[`id]!enlist string MetricId;
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"metrics";qparams;"";()!();S3REGION]
 };

get_bucket_notification:{[BucketName] get_bucket_attribute[BucketName;"notification"]};

get_bucket_object_versions:{[BucketName;Params]
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"versions";Params;"";()!();S3REGION]
 };

get_bucket_policy:{[BucketName] get_bucket_attribute[BucketName;"policy"]};
get_bucket_replication:{[BucketName] get_bucket_attribute[BucketName;"replication"]};
get_bucket_request_payment:{[BucketName] get_bucket_attribute[BucketName;"requestPayment"]};
get_bucket_request_tagging:{[BucketName] get_bucket_attribute[BucketName;"tagging"]};
get_bucket_request_versioning:{[BucketName] get_bucket_attribute[BucketName;"versioning"]};
get_bucket_request_website:{[BucketName] get_bucket_attribute[BucketName;"website"]};

/ get bucket meta
/ TODO fix: use head instead of get http
head_bucket:{[BucketName]
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"";()!();"";()!();S3REGION]
 };

/ list all buckets
list_buckets:{.qaws_s3_impl.s3_simple_request[`get; ""; 1#"/";"";()!();"";()!();S3REGION]};

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketListAnalyticsConfigs.html
/ helper function
/ @params Token (String) continuation token. Use "" for none
/ @params SubResource(String) subresource to run query against
list_buckets_configurations:{[BucketName;Token;Subresource]
 qparams:enlist[`$"continuation-token"]!enlist Token;
 .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";Subresource;qparams;"";()!();.aws_config.aws`region]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketListAnalyticsConfigs.html
/ @params Token (String) continuation token. Use "" for none
list_bucket_analytics:{[BucketName;Token] list_buckets_configurations[BucketName;Token;"analytics"] };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketListInventoryConfigs.html
/ @params Token (String) continuation token. Use "" for none
list_bucket_inventory:{[BucketName;Token] list_buckets_configurations[BucketName;Token;"inventory"] };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTListBucketMetricsConfiguration.html
/ @params Token (String) continuation token. Use "" for none
list_bucket_metrics:{[BucketName;Token] list_buckets_configurations[BucketName;Token;"metrics"] };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadListMPUpload.html
/ @params Options (dict) Request parameters-check above link. Keys should be symbol and values should be string
/ @params HttpHeaders (dict) Request Headers-check above link. Keys should be symbol and values should be string
list_multipart_uploads:{[BucketName;Options;HttpHeaders]
  .qaws_s3_impl.s3_simple_request[`get; BucketName; 1#"/";"uploads";Options;"";HttpHeaders;.aws_config.aws`region]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTaccelerate.html
/ @params Status (String) S3 currently supports 2 options - "Enabled" and "Suspended"
/ @params HttpHeaders (dict) Request headers - check wiki. Keys should be symbol and values should be string
put_bucket_accelerate:{[BucketName;Status;HttpHeaders]
  xml_header:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  xml_data:("AccelerateConfiguration"; "xmlns=\"",XMLNS_S3,"\""; enlist[("Status";"";Status)]);
  body: xml_header,.awsutils.convert_to_xml xml_data;
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/";"accelerate";()!();body;HttpHeaders;.aws_config.aws`region]
 };

/put_bucket_acl:
/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTencryption.html
/ ex1: .qaws_s3.put_bucket_encryption["rahultest2";"AES256";""]
/ ex2: .qaws_s3.put_bucket_encryption["mybukcet";"aws:kms";"arn:aws:kms:us-west-2:1234/5678example"]
put_bucket_encryption:{[BucketName;SSEAlgorithm;KMSMasterKeyId]
  xml_header:"<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
  sse_opts:build_apply_sse_opts[SSEAlgorithm;KMSMasterKeyId];
  xml_data:("ServerSideEncryptionConfiguration"; "xmlns=\"",XMLNS_S3,"\"";
          enlist[("Rule";"";enlist[("ApplyServerSideEncryptionByDefault";"";sse_opts)])]
          );
  body: xml_header,.awsutils.convert_to_xml xml_data;
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/";"encryption";()!();body;()!();.aws_config.aws`region]
 };

build_apply_sse_opts:{[SSEAlgorithm;KMSMasterKeyId]
  kid:$[0<count KMSMasterKeyId;enlist ("KMSMasterKeyId";"";enlist enlist KMSMasterKeyId);()];
  enlist[("SSEAlgorithm";"";enlist enlist SSEAlgorithm)],kid
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTInventoryConfig.html
/ @param BucketName (String) s3 bucket name
/ @param InventoryId (String) Inventory id
/ @param Inventory (String) XML string as  per wiki
put_bucket_inventory:{[BucketName;InventoryId;Inventory]
  policy_md5:.cryptoq.b64_encode md5 Inventory;
  params:enlist["id"]!enlist `$InventoryId;
  header: ("Content-MD5";"content-type")!`$(policy_md5;"application/xml");
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/";"inventory";params;Inventory;header;.aws_config.aws`region]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTlifecycle.html
/ @param BucketName (String) s3 bucket name
/ @param Policy (String) XML string as per S3 wiki
put_bucket_lifecycle:{[BucketName;Policy]:
  policy_md5:.cryptoq.b64_encode md5 Policy;
  header: enlist["Content-MD5"]!enlist `$policy_md5;
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/";"lifecycle";()!();Policy;header;.aws_config.aws`region]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTBucketPUTtagging.html
/ @params Tags (dict) key value pairs of tags; key and value both should be string
put_bucket_tagging:{[BucketName; Tags]
  tag_xml:create_tags_xml Tags;
  tag_xml_md5:.cryptoq.b64_encode md5 tag_xml;
  header: enlist[`$"Content-MD5"]! enlist tag_xml_md5;
  .qaws_s3_impl.s3_simple_request[`put; BucketName; 1#"/";"tagging";()!();tag_xml;header;.aws_config.aws`region]
 };

/ @params Tags (dict) key value pairs of tags; key and value both should be string
create_tags_xml:{[Tags]
  tags_xml:raze{"<Tag><Key>",x,"</Key><Value>",y,"</Value></Tag>"}'[key Tags;value Tags];
  "<Tagging><TagSet>",tags_xml,"</TagSet></Tagging>"
 };
\d .
