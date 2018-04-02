\d .kinesis
describe_stream:{[StreamName;Region]
  Json: enlist[`StreamName]!enlist StreamName;
  .qaws_kinesis_impl.request[Region;"Kinesis_20131202.DescribeStream";Json;1]
 };

\d .
