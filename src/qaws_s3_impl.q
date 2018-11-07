\d .qaws_s3_impl

s3_simple_request:{[Method;Host;Path;SubResource;Params;Postdata;Headers;Region]
  s3_request[Method;Host;Path;SubResource;Params;Postdata;Headers;Region]
 };

s3_request:{[Method;Bucket;Path;Subresource;Params;Postdata;Headers;Region]
  config:.qaws_aws.get_aws_config Region;
  result:s3_request_no_update[config;Bucket;Method;Path;Subresource;Params;Postdata;Headers];
  / Check redirect url and follow it if present
  if[("I"$result`status_code) within (301;399);
    :s3_follow_redirect[result;Bucket;config`s3_follow_redirect_count;config;(Method;Path;Subresource;Params;Postdata;Headers)]]
  result
 };

/ http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingBucket.html#create-bucket-intro
/ AccessMethod can be either 'vhost' - virtual-hosted–style or
/ 'path' - older path-style URLs to access a bucket.
s3_request_no_update:{[Config;Bucket;Method;Path;Subresource;Params;Body;Headers]
  content_type:$[(c:`$"content-type") in key Headers;Headers c;""];
  / TODO check line 1743-44
  query_params:$[""~Subresource;Params;.awsutils.append_header[Subresource;"";Params]];
  s3host:Config `s3_host;
  access_method:get_access_method[Bucket;Config];
  host_path:$[`vhost=access_method;get_virtual_style_host_path;get_path_style_host_path] . (Bucket;s3host;Path);
  headers:.awsutils.append_header["host";host_path 0;Headers];
  region:.qaws_aws.aws_s3_region_from_host s3host;
  request_headers:.qaws_aws.sign_v4[Method;host_path 1;headers;Body;region;"s3";query_params;Config];
  request_uri:host_path[1],$[sr:""~Subresource;"";"?",Subresource];
  request_uri:request_uri,$[0=count Params;"";("&?" sr),.qaws_http.make_query_string[Params;0]];
  request_body:(Body;"") m:Method in (`get`head`delete);
  request_headers2:$[m; request_headers;
                      $[(`$"content-type") in key request_headers;request_headers;
                        .awsutils.append_header["content-type";content_type;request_headers]]];
  request_retry[Config;Method;request_uri;request_headers2;request_body;0;1]
 };

get_access_method:{[Bucket;Config]
  m:Config`s3_bucket_access_method;
  if[not `auto=m;:m];
  / method=auto case
  $[(Bucket~"") or .awsutils.is_dns_compliant_name Bucket;`vhost;`path]
 };

/ Add bucket name to the front of hostname,
/ i.e. https://bucket.name.s3.amazonaws.com/<path>
get_virtual_style_host_path:{[Bucket;Host;Path]
  host:$[""~Bucket;"";Bucket,"."],Host;
  (host;.qaws_http.url_encode_loose Path)
 };

/ Add bucket name into a URL path
/ i.e. https://s3.amazonaws.com/bucket/<path>
get_path_style_host_path:{[Bucket;Host;Path]
  path:.qaws_http.url_encode_loose $[""~Bucket;"";"/",Bucket],Path;
  (Host;path)
 };

port_spec:{[Config]
  ((":",p);"")p:string 80=Config[`s3_port]
 };

request_retry:{[Config;Method;Path;Headers;Body;Decode;Attempt]
   fhttp:(`get`head`post`put`delete!(.qhttp.hget;.qhttp.hhead;.qhttp.hpost;.qhttp.hput;.qhttp.hdelete)) Method;
   Host: raze Config[`s3_host],port_spec Config;
   if[any `get`head in Method;:fhttp[1b;Host;Path;Headers;()!()]];
   content_type:$[(c:`$"content-type") in key Headers;Headers c;"application/x-amz-json-1.1"];
   fhttp[1b;Host;Path;Headers;content_type;Body]
 };

s3_follow_redirect:{[Response;Bucket;Attempt;Config;Params]
  show "FOLLOW REDIRECT";
  if[Attempt =0;: Response];  / All attempts done. return last response as result
  endpoint_details:s3_endpoint_access_method_form_response[Bucket;Response;Config];
  new_config:Config,`s3_host`s3_bucket_access_method!endpoint_details`host`access_method;
  result:s3_request_no_update[new_config;Bucket] . Params;
  if[("I"$result`status_code) within (301;399); : s3_follow_redirect[Response;Attempt-1;Config;Bucket;Params]];
  result
 };

/ Get s3 endpoint and access_method from HTTP response of last request
/ @param Bucket (String) Bucket name
/ @param Response (dict) http response. see qhttp library for return dict fields(requires headers and body)
/ @param Config (dict) aws config
/ @return (dict) `host`access_method!(endpoint;s3 access method)
s3_endpoint_access_method_form_response:{[Bucket; Response; Config]
  if["x-amz-bucket-region" in key Response`headers; endpoint:s3_endpoint_from_region Response[`headers;"x-amz-bucket-region"];
     :`host`access_method!(endpoint;Config`s3_bucket_access_method)];
  if["Location" in key Response`headers; host: ("/" vs Response[`headers;"Location"])2;
    :s3_endpoint_access_method_form_hostname[host; Bucket] ];
  host: .awsutils.xmlval[Response`body; "Endpoint"];
  if[0<>count host; :s3_endpoint_access_method_form_hostname[host; Bucket] ];
  :`host`access_method!Config `s3_host`s3_bucket_access_method;
 };

/ Ther are 2 cases: 1. If bucket name is part of hostname => virtual hosted stlye access should be used.
/ For this remove bucket name from hostname
/ 2. Use path styly with same hostname
/ Example: 1. s3_endpoint_access_method_from_hostname("test.bucket.s3.eu-central-1.amazonaws.com")
/ Output: `host`access_method!("s3.eu-central-1.amazonaws.com";`vhost)
/ Example: 2. s3_endpoint_access_method_from_hostname("s3.amazonaws.com")
/ Output: `host`access_method!("s3.amazonaws.com";`path)
/ @param Host (String) hostname
/ @param Bucket (String) Bucket name
/ @return (dict) `host`access_method!(endpoint;s3 access method)
s3_endpoint_access_method_form_hostname:{[Host; Bucket]
  `host`access_method!$[Host like Bucket,"*"; ((1+count Bucket)_Host;`vhost);(Host;`path)]
 };

/ creates s3 endpoint from region name
/ Example: "us-west-2" -> s3-us-west-2.amazonaws.com
/ @param Region (String) region name
/ @return (string) Endpoint
s3_endpoint_from_region:{[Region]
  if["us-east-1"~Region;:"s3-external-1.amazonaws.com"];
  "s3-",Region,".amazonaws.com"
 };

\d .
