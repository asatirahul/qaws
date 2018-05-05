\d .aws_config


assume_role: `role_arn`session`duration`external_id`assume_role_id!("";"qaws";900;"";"");

aws: (!) . flip ( (`region;"us-east-1"); (`kinesis_scheme;"https://");(`kinesis_host;"kinesis.us-west-2.amazonaws.com");
             (`kinesis_port;80); (`sts_host;"sts.amazonaws.com");
             (`assume_role;assume_role); / if role to assumed then will use this
             (`retry_num;6);
             (`aws_access_key_id;"");(`aws_secret_access_key;""); (`aws_security_token;"");(`expiration;0Nz)
             );

\d .

