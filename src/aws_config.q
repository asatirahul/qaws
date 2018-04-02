\d .aws_config

/aws: (!) . flip ( (`region;"us-west-2"); (`kinesis_scheme;"https://");(`kinesis_host;"kinesis.us-west-2.amazonaws.com");
/             (`kinesis_port;80);(`access_key_id;"AKIAI26TSB3YVIKTFWDQ");(`secret_access_key;"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") );

assume_role: `role_arn`session`duration`external_id`assume_role_id!("";"qaws";900;"";"");

aws: (!) . flip ( (`region;"us-east-1"); (`kinesis_scheme;"https://");(`kinesis_host;"kinesis.us-west-2.amazonaws.com");
             (`kinesis_port;80); (`sts_host;"sts.amazonaws.com");
             (`assume_role;assume_role); / if role to assumed then will use this
             (`retry_num;6);
             (`aws_access_key_id;"");(`aws_secret_access_key;""); (`aws_security_token;"");(`expiration;0Nz)
             );

\d .

/aws: (!) . flip ( (`region;"us-west-2"); (`kinesis_scheme;"https://");(`kinesis_host;"kinesis.us-west-2.amazonaws.com");
             /(`kinesis_port;80);(`access_key_id;"ASIAJLXZAEJVXHHIPCVQ");(`secret_access_key;"4n7TR87OCJkCMW/f2VM2ltZD7IBWC028MIzE1le2") ;
             /(`security_token;"FQoDYXdzEMD//////////wEaDMBaEXhe4UssDCxwFCLsAQ5d4EJJltnWa1W2iOU9Oiftw5uQ0dSZSMd/vqpF5H6RTQOzVF3dhHq9QuUfjAxnA/h6sCTNyLmDuQ22GyJOe9mP51JGPtJ2Vd2WoastzonocBG2bAzM5/fvlZmWvVr0agkwbbb3QxUd/7YlKjVe900BuSLOYKenyA0pfaYOoUXP2+gmScUPC1ycdcPU8UjX+SxHyw72ss24hZo35v7ozAjhUcB7KEw3woRY0nTu0V7J4rA3xCaqRcM1g00ywUhuah1oEaVOl+qArD4TsAGvA+ueJgYO4fwwrcBFpYOB/afnBFdnMrE/yPUrvzHKKMPx89UF"));
