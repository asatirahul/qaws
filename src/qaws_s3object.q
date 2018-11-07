\d .qaws_s3object
S3REGION:"us-west-2"; /.aws_config.aws`region;

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html
/ @param BucketName (String) Bucket name
/ @param Key (String) Object Key
delete_object:{[BucketName;Key]
  .qaws_s3_impl.s3_simple_request[`delete;BucketName; "/",Key; ""; ()!(); ""; ()!();S3REGION]
 };

 / https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html
 / @param BucketName (String) Bucket name
 / @param Key (String) Object Key
 / @param Version (String) Object version number to delete
delete_object_version:{[BucketName;Key;Version]
 sres:"versionId=",Version;
 .qaws_s3_impl.s3_simple_request[`delete;BucketName; "/",Key; sres; ()!(); ""; ()!();S3REGION]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETE.html
/ full version of delete opbject with all options supported by S3 Api.
/ @param BucketName (String) Bucket name
/ @param Key (String) Object Key
/ @param Version (String) Object version number to delete. if no version required then use ""
/ @param MFA (String) MFA
delete_object_mfa:{[BucketName;Key;Version;MFA]
 sres:$[""~Version;"";"versionId=",Version];
 header:enlist["x-amz-mfa"]!enlist `$MFA;
 .qaws_s3_impl.s3_simple_request[`delete;BucketName; "/",Key; sres; ()!(); ""; header;S3REGION]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectDELETEtagging.html
/ @param BucketName (String) Bucket name
/ @param Key (String) Object Key
/ @param Headers (Dict) Header options as mentioned on S3 Api page. Use ()!() for no options. Dict type should be String!Symbol.
delete_object_tagging:{[BucketName;Key;Headers]
  .qaws_s3_impl.s3_simple_request[`delete;BucketName; "/",Key; "tagging"; ()!(); ""; Headers;S3REGION]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/multiobjectdeleteapi.html
/ @param KVList (List) (Key, Version) Pair list
/ @param Headers (Dict) Headers Dict type should be String!Symbol.
delete_multiple_objects:{[BucketName;KVList;Headers]
  body:create_del_op_xml KVList;
  .qaws_s3_impl.s3_simple_request[`delete;BucketName; 1#"/"; "delete"; ()!(); body; Headers;S3REGION]
 };

put_object:{[BucketName;Key;Value;Options]
  .qaws_s3_impl.s3_simple_request[`put;BucketName; "/",Key; ""; ()!();Value;Options;S3REGION]
 };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/RESTObjectPUTtagging.html
/ @param BucketName (String) Bucket name
/ @param Key (String) Object Key
/ @params Tags (dict) key value pairs of tags; key and value both should be string
put_object_tagging:{[BucketName;Key;Tags]
   tag_xml:create_tags_xml Tags;
   tag_xml_md5:.cryptoq.b64_encode md5 tag_xml;
   header: enlist[`$"Content-MD5"]! enlist tag_xml_md5;
   .qaws_s3_impl.s3_simple_request[`put; BucketName;"/",Key;"tagging";()!();tag_xml;header;S3REGION]
  };

/ @params Tags (dict) key value pairs of tags; key and value both should be string
create_tags_xml:{[Tags]
   tags_xml:raze{"<Tag><Key>",x,"</Key><Value>",y,"</Value></Tag>"}'[key Tags;value Tags];
   "<Tagging><TagSet>",tags_xml,"</TagSet></Tagging>"
  };

/ https://docs.aws.amazon.com/AmazonS3/latest/API/multiobjectdeleteapi.html
/ creates xml for delete multiple delete_object_version
/ @param KVList (List) (Key, Version) Pair list
create_del_op_xml:{[KVList]
  objxml:raze {"<Object><Key>",x,"</Key>",$[""~y;"";"<VersionId>",y,"</VersionId>"],"</Object>"}./:KVList;
  "<?xml version=\"1.0\" encoding=\"UTF-8\"?> <Delete>",objxml,"</Delete>"
 };

\d .

/ Config, Method, Host, Path, Subreasource, Params, POSTData, Headers) ->
