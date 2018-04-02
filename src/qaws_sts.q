\d .qaws_sts
/ ---------------------------------
/    APPLICATION CONSTANTS
/ ---------------------------------
API_VERSION: "2011-06-15";

/ ---------------------------------
/    FUNCTIONS
/ ---------------------------------

/ See http://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html
/ assumes aws role
/ @param AwsConfig (dict) aws config dictionary (Symbol!String)
/ @param RoleArn (String) Role arn
/ @param RoleSessionName (String) RoleSessionName
/ @param DurationSeconds (int) DurationSeconds
/ @param ExternalId (String) ExternalId (can be "")
/ @return (dict) New config with updated credentials
/ @throws ROLE_ARN_LENGTH|ROLE_SESSION_NAME_LENGTH|DUATION_SECONDS_VALUE
assume_role:{[AwsConfig; RoleArn; RoleSessionName; DurationSeconds; ExternalId]
  if[20>count RoleArn;'ROLE_ARN_LENGTH];
  if[not count[RoleSessionName] within (2,64);'ROLE_SESSION_NAME_LENGTH];
  if[not DurationSeconds within (900;3600);'DUATION_SECONDS_VALUE];
  params: ("RoleArn";"RoleSessionName";"DurationSeconds")!(RoleArn;RoleSessionName;string DurationSeconds);
  if[count[ExternalId] within (2,96); params:parms,enlist["ExternalId"]!enlist ExternalId];
  xml:sts_query[AwsConfig;"AssumeRole";params;API_VERSION];
  creds:.qaws_ini.parse_xml xml;
  config:@[AwsConfig;`aws_access_key_id`aws_secret_access_key`aws_security_token`expiration;:;creds("AccessKeyId";"SecretAccessKey";"SessionToken";"Expiration")];
  config[`assume_role;`assume_role_id]:creds "AssumedRoleId";
  config[`expiration]:"Z"$-1_config `expiration;
  config
 };


/ Format the sts query and runs it
/ @param AwsConfig (dict) aws config dictionary (Symbol!String)
/ @param Action (String) Sts action as per aws for ex: "AssumeRole" for assuming role
/ @param Params (dict) parameters (String!String)
/ @param ApiVersion (String) Api Version for Action as per aws
/ @return (String) http return of request
sts_query:{[AwsConfig; Action; Params; ApiVersion]
  addr:`protocol`host`port!("";AwsConfig`sts_host;0Ni);
  params:Params,("Action";"Version")!(Action;ApiVersion);
  AwsConfig[`region]:"us-east-1"; // IAM related requests works in us east only
  .qaws_aws.aws_request[`post;addr;enlist "/";params;"sts";()!();AwsConfig]
 };

\d .
