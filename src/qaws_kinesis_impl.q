\d .qaws_kinesis_impl

request:{[Region;Operation;Body;Decode]
  Config:.qaws_aws.get_aws_config Region;
  JBody: .awsutils.to_json Body;
  Headers: headers[Config;Operation;JBody];
  ret:request_retry[Config;Headers;JBody;Decode;1];
  `status`result!(ret`status;$[""~ret`body;"";.j.k ret`body])
 };

request_retry:{[Config;Headers;Body;Decode;Attempt]
  /Host: url Config;
  Host: raze Config[`kinesis_host],((":",p);"")p:string 80=Config[`kinesis_port];
  .qhttp.hpost[1b;Host;"";Headers;"application/x-amz-json-1.1";Body]
 };

/dict;str;str
headers:{[Config;Operation;Body]
  Headers: (`host;`$"x-amz-target")!(Config[`kinesis_host];Operation);
  .qaws_aws.sign_v4_headers[Config; Headers; Body; .qaws_aws.aws_region_from_host Config`kinesis_host; "kinesis"]
 };

url:{[Config]
  raze Config[`kinesis_scheme],Config[`kinesis_host],((":",p);"")p:string 80=Config[`kinesis_port]
 };

\d .
