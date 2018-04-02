\d .qaws_aws
/ ---------------------------------
/    APPLICATION CONSTANTS
/ ---------------------------------
AWS_REGION:"";
DEFAULT_CONTENT_TYPE: "application/x-www-form-urlencoded; charset=utf-8";
USER_CONFIG:()!(); / stores user aws configs per region
/ ---------------------------------
/    OS CONSTANTS
/ ---------------------------------
AWS_REGION_OS:`AWS_REGION;
/ ---------------------------------

/ ---------------------------------
/    FUNCTIONS
/ ---------------------------------
/ dict;dict;str;str;str
/ http://docs.aws.amazon.com/general/latest/gr/signature-version-4.html
sign_v4_headers:{[Config; Headers; Payload; Region; Service]
    sign_v4[`post; enlist "/";Headers; Payload; Region; Service; (); Config]
  };

sign_v4:{[Method; Uri; Headers; Payload; Region; Service; QueryParams; Config]
   Dttime: iso_8601_datetime[];
   res: sign_v4_content_sha256_header[Payload;.awsutils.append_header["x-amz-date";Dttime;Headers]];
   PayloadHash: res 0; Headers1 : res 1;
   Headers2:$[not ""~Config `aws_security_token;.awsutils.append_header["x-amz-security-token";Config `aws_security_token;Headers1];Headers1];
   res: canonical_request[Method;Uri;QueryParams;Headers2;PayloadHash];
   Request:res 0; SignedHeaders: res 1;
   CredentialScope: credential_scope[Dttime;Region;Service];
   ToSign: to_sign[Dttime;CredentialScope;Request];
   SigningKey: signing_key[Dttime; Region; Service; Config];
   Signature: hex_encode .cryptoq.hmac_sha256[SigningKey; ToSign];
   Authorization: authorization[Config; CredentialScope; SignedHeaders; Signature];
   .awsutils.append_header[`Authorization; Authorization;Headers2]
 };

canonical_request:{[Method; Uri; QParams; Headers; PayloadHash]
  res:canonical_headers Headers;
  canonicalhdr: res 0; signedhdr:res 1;
  canonical_qstring: canonical_query_string QParams; / check canonical_query_string QParams;
  canonicalrequest:"\n" sv (upper string Method;Uri;canonical_qstring;canonicalhdr;signedhdr;PayloadHash);
  (canonicalrequest;signedhdr)
 };

canonical_query_string:{[QParams]
  if[()~QParams;:""];
  qp: (.qaws_http.uri_encode@/: key QParams; .qaws_http.uri_encode@/: value QParams) ;
  sorted_qp: qp @\:iasc qp 0;
  "&" sv {x,"=",y} ./: flip sorted_qp
 };

sign_v4_content_sha256_header:{[Payload; Headers]
  k:`$"x-amz-content-sha256";
  if[k in key Headers; :(Payload;Headers)];
  payload_hash: hash Payload;
  (payload_hash; .awsutils.append_header[k;payload_hash;Headers])
  };

canonical_headers:{[Headers]
  normalized: (lower(string key Headers);trimall@'value Headers);
  sorted: normalized@\:iasc normalized 0;  / sort by header names
  canonical: raze {x,":",y,"\n"}'[sorted 0;sorted 1];  / join header name value pairs
  signed: ";" sv sorted 0; / join header names
  (canonical;signed)
 };

/ all string
credential_scope:{[DateTime;Region;Service]
   "/" sv (8#DateTime;Region;Service;"aws4_request")
  };

to_sign:{[DateTime;CredentialScope;Request]
  "\n" sv ("AWS4-HMAC-SHA256";DateTime;CredentialScope;hash Request)
 };

/all string. config dict with value string
signing_key:{[DateTime; Region; Service; Config]
  Date:8#DateTime;
  (.cryptoq.hmac_sha256/)("AWS4",Config`aws_secret_access_key;Date;Region;Service;"aws4_request")
 };

authorization:{[Config;CredentialScope;SignedHeaders;Signature]
  "AWS4-HMAC-SHA256 Credential=",Config[`aws_access_key_id],"/",CredentialScope,", SignedHeaders=",SignedHeaders,", Signature=",Signature
 };

iso_8601_datetime:{
  a:.z.z;
  ssr[?[b  in ".:";" ";b:-4_string a];" ";""],"Z"
 };

hash:{[Data]
  hex_encode .cryptoq.sha256 Data
  };

hex_encode:{[Data]
  hex:("0123456789abcdef");
  raze ?[1=count@'h;"0",'h;h:hex 16 vs/: `int$Data]
  };

trimall:{[Data]
  a::Data;
  (" "sv"  "vs)/[trim(Data)]
 };

/ fetches host from region URL
/ aws endpoint changes according to region. For ex:
/ us-west-2 : s3.us-west-2.amazonaws.com
/ cn-north-1: s3.cn-north-1.amazonaws.com.cn
/ normally first element is aws service(ec2,s3 etc) and second is region name, rest of the string is ignored
/ Exception: dynamodb streams and marketplace which has different format and handled in Function
/ @param Host (String) Host name/URL
/ @return (String) region
aws_region_from_host:{[Host]
  Tokens : "." vs Host;
  if[any Host like/: ("streams.dynamodb.*";"metering.marketplace.*";"entitlement.marketplace.*"); : Tokens 2];
  if[4<=count Tokens;:Tokens 1];
  default_config_get[AWS_REGION_OS;AWS_REGION;"us-east-1"]
 };

/ first try to read operating system variable - if set then return its value else
/ reads application var and if its set then return its value else return default
/ @param Osvar (symbol) operating system variable name
/ @param Appvar (symbol) application variable name
/ @param Default (string) default value
/ @return (String)
default_config_get:{[Osvar;Appvar;Default]
  $[0<count v:getenv Osvar; v; not ""~ Appvar; Appvar; Default]
 };

/ Lower case for  key and adds content-type header if not present
/ @param Header (dict) Header dict - key is symbol and value is string
encode_header:{[Header]
  header: lower[key Header]!value Header;
  if[not (k:`$"content-type") in key Header; header[k]:DEFAULT_CONTENT_TYPE];
  :header
 };

/ prepares aws request
/ @param Method (symbol) - rest methods like post|get|delete|head
/ @param Addr (dict) - `host`port`protocol!(string;number;string) ex:("sts.com";80;"https")
/ @param Path (string) - if any path required in url for ex GET request path
/ @param Params (dict) - Query params - (String!String))
/ @param Service (String) Aws Service tag ex: "kinesis"
/ @param Headers (dict) Headers - (symbol!String)
/ @param Config (dict) aws config dict (Symbol!String)
/ @return TODO
aws_request:{[Method; Addr; Path; Params; Service; Headers; Config]
  reqheaders: encode_header Headers;
  query: .qaws_http.make_query_string[Params;1];
  region:(r;aws_region_from_host Addr`host) ""~r:Config `region;
  uri: .qaws_http.url_encode_loose Path;
  $[Method in (`get`head`delete);[payload:"";qparams:Params];[payload:query;qparams:()]];
  sign_headers: sign_v4[Method; uri; enlist[`host]!enlist Addr`host; payload; region; Service; qparams; Config];
  aws_request_form[Method;Addr;Path;query;sign_headers,reqheaders]
 };

/ TODO Handle post return
/ Sends aws http request and handle return
/ @param Method (symbol) - rest methods like post|get|delete|head
/ @param Addr (dict) - `host`port`protocol!(string;number;string) ex:("sts.com";80;"https")
/ @param Path (string) - if any path required in url for ex GET request path
/ @param Query (String) - Query String
/ @param Headers (dict) Headers - (symbol!String)
/ @return (string) http return body
aws_request_form:{[Method;Addr;Path;Query;Headers]
  ct:`$"content-type";
  headers:enlist[ct]_Headers;
  ret:.qhttp.hpost[Addr`host;Path;headers;Headers ct;Query];
  ret `body
 };

/ Get aws config for specified region from cache. If not present in cache then genrates one and updates the cache.
/ Also checks out for assumed role expiration
/ @param Region (String) Region name . "us-west-2"
/ @return (dic) aws config (Symbol!String) see .qaws_aws_config.aws for format
get_aws_config:{[Region]
  if[(r:`$Region) in key USER_CONFIG; update_aws_config r; : USER_CONFIG r];
  config:aws_config Region;
  USER_CONFIG[r]:config;
  config
 };

/ Checks for assume role expiration for config in cache. If its expired then genrates new creds and update the cache.
/ @param Region (String) Region name . "us-west-2"
update_aws_config:{[Region]
  if[USER_CONFIG[Region][`expiration]<.z.z; USER_CONFIG[`Region]:USER_CONFIG[`Region],get_credentials ()!()];  / token exoired, update credentials
 };

/ Get aws config for specified region
/ @param Region (String) Region name . "us-west-2"
/ @return (dic) aws config (Symbol!String) see .qaws_aws_config.aws for format
aws_config:{[Region]
  config:auto_config[];
  services:default_config_region_services[]; / supported aws services
  @[config;`$services,\:"_host";:;service_host[;Region]@'services]
 };

/ Generates aws default config with credentials
/ @return (dic) aws config (Symbol!String) see .qaws_aws_config.aws for format
auto_config:{ update_credentials[.aws_config.aws;get_credentials ()!() ]};

/ get the credentials
/ @param Opts (dict) Any options including role assume options for ex session name, duration
/ @return (dict) Credentials dict (String!String) (ex keys "aws_access_key_id"; "aws_secret_access_key";"aws_security_token")
get_credentials:{[Opts]
  creds:profile_credentials["default"];
  profile_assume[.aws_config.aws;creds;.aws_config.assume_role,Opts]
 };

/ read credentials of profile from credentials file
/ @param Name (String) Profile Name
/ @return (dict) Credentials dict (String!String) (ex keys "aws_access_key_id"; "aws_secret_access_key";"aws_security_token")
profile_credentials:{[Name]
  profiles: .qaws_ini.read_profile_file[];
  profile_resolve[profiles; Name;()!()]
 };

/ Get credntails for profile from dict of all Profiles
/ @param Profiles (dict) All Profile dict (String!(String!String))
/ @param ProfileName (String) Profile name to get cred details
/ @param Creds (dict) Credentils (String!String) - used for role_arn in case source_profile is mentioned in profilename dict
/ @return (dict) Credentials dict (String!String) (ex keys "aws_access_key_id"; "aws_secret_access_key";"aws_security_token")
profile_resolve:{[Profiles; ProfileName;Creds]
  profile:Profiles ProfileName;
  k1:("role_arn";"external_id");
  if["source_profile" in key profile;:profile_resolve[Profiles;profile "source_profile";Creds,k1#profile]];
  k2:("aws_access_key_id"; "aws_secret_access_key";"aws_security_token");
  if[not a~key[profile] inter a:2#k2;'Access_Key_Missing_In_Profile];
  Creds,#[k2 inter key profile;profile]
 };

/ Updates config with new credentials. Assumes credentials if mentioned
/ @param Config (dict) aws config dict (Symbol!String)
/ @param Creds (dict) new credentials dictionary (String ! String)
/ @param Opts (dict) option for role assume - `role_arn`session`duration`external_id`assume_role_id!("";"qaws";900;"";"");
/ @return (dict) new credentials (Symbol!String)
profile_assume:{[Config;Creds;Opts]
  if[""~Creds "role_arn";:Creds];
  nconfig:update_credentials[Config;Creds];
  new_creds: .qaws_sts.assume_role[nconfig;Creds "role_arn";Opts`session;Opts`duration;Creds"external_id"];
  new_creds
 };

/ update config with new credentials
/ @param Config (dict) aws config dict (Symbol!String)
/ @param Creds (dict) new credentials dictionary (Symbol|String ! String)
/ @return (dict) new config (Symbol!String)
update_credentials:{[Config;Creds]
  $[11h=type key Creds;Config,Creds; Config,(`$key Creds)!value Creds]
 };

/ Keys with _host suffix in aws config are services
/ handles special case for s3
default_config_region_services:{
  {first "_" vs x} each except[k where (k:string key .aws_config.aws) like "*_host";enlist "s3_bucket_after_host"]
 };

/ TODO handle special cases
/ Creates host name from Service and Region
/ @param Service (String) Service name
/ @param Region (String) Region Name
/ @return (String) host name
service_host:{[Service;Region]  "." sv (Service;Region;"amazonaws.com") };

\d .
