.utl.load "qaws";
.utl.load "crypto";

.tst.desc["Trim_all"]{
  should["Reduce spaces to 1"]{
    .qaws_aws.trimall["2  spaces"] musteq "2 spaces";
    .qaws_aws.trimall[" many   spaces test "] musteq "many spaces test";
  };
 };

.tst.desc["Iso_8601_datetime"]{
  should["Return String"]{
    type[.qaws_aws.iso_8601_datetime[]] musteq 10h;
  };
  should["Return Correct Format"]{
    result:.qaws_aws.iso_8601_datetime[];
    null["D"$8#result] musteq 0b;
    result[8] musteq "T";
    null["T"$9_-1_result] musteq 0b;
    last[result] musteq "Z";
  };
 };

.tst.desc["Credential Scope"]{
  should["Return Correct Format"]{
    .qaws_aws.credential_scope["20180312T152213Z";"us-west-2";"kinesis"] musteq "20180312/us-west-2/kinesis/aws4_request";
  };
 };

.tst.desc["Signing_key"]{
  should["Return Correct Signing Key"]{
    `.crypto.hmac_sha256 mock {raze x,y,"sha256"};
    Config:`access_key_id`secret_access_key!("access_key";"secret_access_key");
    signing_key: "AWS4secret_access_key20180312sha256us-west-2sha256kinesissha256aws4_requestsha256";
    .qaws_aws.signing_key["20180312T152213Z";"us-west-2";"kinesis";Config] musteq signing_key;
  };
 };

.tst.desc["Authorization"]{
   should["Return Correct Authorization String"]{
     Config:`access_key_id`secret_access_key!("access_key";"secret_access_key");
     CredentialScope: "20180312/us-west-2/kinesis/aws4_request";
     Authorization: "AWS4-HMAC-SHA256 Credential=access_key/20180312/us-west-2/kinesis/aws4_request, SignedHeaders=host;x-amz-date, Signature=signature";
     .qaws_aws.authorization[Config; CredentialScope;"host;x-amz-date";"signature"] musteq Authorization;
   };
  };

.tst.desc["Sign_v4_content_sha256_header"]{
  before{
    `.qaws_aws.hash mock {x,"hash"};
    `Payload mock "payload";
    `PayloadHash mock "payloadhash";
    `Header1 mock `host`service!("aws";"kinesis");
    `Header2 mock (`host;`service;`$"x-amz-content-sha256")!("aws";"kinesis";PayloadHash);
    };
    should["Not Hash Payload"]{
      res: .qaws_aws.sign_v4_content_sha256_header[Payload; Header1];
      PayloadHash musteq res 0;
      Header2 mustmatch res 1;
    };
    should["Hash Payload"]{
      res: .qaws_aws.sign_v4_content_sha256_header[PayloadHash; Header2];
      PayloadHash musteq res 0;
      Header2 mustmatch res 1;
    };
  };

.tst.desc["Sign_v4"]{
        before{
          `.qaws_aws.iso_8601_datetime mock {"20180312T152213Z"};
          `.qaws_aws.hash mock {x,"hash"};
          `.crypto.hmac_sha256 mock {x;y;0x0a0b};
          `Config mock `access_key_id`secret_access_key!("access_key";"secret_access_key");
          `Payload mock "payload";
          `Header mock `host`service!("aws";"kinesis");
          `Region mock "us-west-2";
          `Service mock "kinesis";
          `Uri mock enlist "/";
          `Method mock `post;
          `QueryParams mock ();
          };
          should["Return Authorization in Header"]{
            res: .qaws_aws.sign_v4[Method; Uri; Header; Payload; Region; Service; QueryParams; Config];
            expect: (`host;`service;`$"x-amz-date";`$"x-amz-content-sha256";`Authorization)!("aws";"kinesis";"20180312T152213Z";"payloadhash";"AWS4-HMAC-SHA256 Credential=access_key/20180312/us-west-2/kinesis/aws4_request, SignedHeaders=host;service;x-amz-content-sha256;x-amz-date, Signature=0a0b");
            res mustmatch expect;
          };
    };

.tst.desc["Region_From_Host"]{
        should["Return Correct Region"]{
          "us-west-2" mustmatch .qaws_aws.aws_region_from_host "s3.us-west-2.amazonaws.com";
          "us-west-2" mustmatch .qaws_aws.aws_region_from_host "metering.marketplace.us-west-2.amazonaws.com";
          "us-west-2" mustmatch .qaws_aws.aws_region_from_host "streams.dynamodb.us-west-2.amazonaws.com";
          "us-east-1" mustnmatch .qaws_aws.aws_region_from_host "s3.us-east-1.amazonaws";
        };
        should["Use Application Var"]{
          .qaws_aws.AWS_REGION: "us-east-1";
          "us-east-1" mustmatch .qaws_aws.aws_region_from_host "s3.us-west-2.amazonaws";
          "us-west-2" mustmatch .qaws_aws.aws_region_from_host "s3.us-west-2.amazonaws.com";
        };
        should["Use OS Var"]{
          .qaws_aws.AWS_REGION_OS setenv "us-east-1";
          .qaws_aws.AWS_REGION : "us-east-2";
          "us-east-1" mustmatch .qaws_aws.aws_region_from_host "s3.us-west-2.amazonaws";
          "us-west-2" mustmatch .qaws_aws.aws_region_from_host "s3.us-west-2.amazonaws.com";
        };
    };

.tst.desc["Canonical Query String"]{
        should["Return Correct Canonical query string"]{
          qp:(!) . (`$("Action";"Version";"RoleArn";"RoleSessionName";"DurationSeconds");("AssumeRole";"2011-06-15";"arn:aws:iam::948063967832:role/centralized-users";"erlcloud";"900"));
          res: "Action=AssumeRole&DurationSeconds=900&RoleArn=arn%3Aaws%3Aiam%3A%3A948063967832%3Arole%2Fcentralized-users&RoleSessionName=erlcloud&Version=2011-06-15";
          res mustmatch .qaws_aws.canonical_query_string qp;
        };
    };
