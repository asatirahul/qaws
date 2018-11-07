\d .qaws_http
/ TODO : use encode slash. Same as .h.hu?
/ AWS Link: https://docs.aws.amazon.com/AmazonS3/latest/API/sigv4-query-string-auth.html
uri_encode_p:{[input; encodeSlash]
  char_set: .Q.a,.Q.A,.Q.n,"_-.~";
  if[11=abs type input;input:string input];
  raze ?[input in char_set;enlist each input;"%",/:upper string "x"$input]
 };

uri_encode:uri_encode_p[;0];

/ convert query dict to string "key1=value1&key2=value2"
/ S3 requires that empty assignments should not have '=' (/?tag)
/ SQS requires that empty assignments should have '=' (/?tag=)
/ @param (dict) QParams: Query parameters dict. Key and value both should be String
/ @param (boolean) EmptyAssign: 0 for no EmptyAssignment(S3 case) and 1 for SQS like case
/ @return (String) query in rest api string format
make_query_string:{[QParams; EmptyAssign]
  a:("";"=") EmptyAssign;
  v:?[""~/:vq;a,/:vq;"=",/:uri_encode each vq:value QParams];
  "&" sv ?[11=abs type k;string k;k:key QParams] ,'v
 };

/ FIX ME
url_encode_loose:{x}; / [Path] .h.hu Path};

\d .
