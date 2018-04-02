/ Simple parser to parse aws credentals ini files

\d .qaws_ini

/ get name of all profiles in file
get_all_profiles:{ key read_profile_file[] };

/ read profile file and return dictionary of format:
/ `profile1`profile2!(key_value dic of profile1; key_value dic of profile2)
read_profile_file:{
  f:read0 hsym `$"/Users/rahul.asati/.aws/credentials";
  f:trim each f except enlist "";
  gen_profile_dict cut[where "[" = first each f;f]
 };

/ generate profile dictionary for all profiles
gen_profile_dict:{[profiles]
     (1_/:-1_/:profiles[;0]) ! {(!) . flip trim@/: "=" vs/: x} each 1_'profiles
  };

/ get key values dict for input profile
/ @param profile (String) profile name to read from file
/ @return (Dict | Error) profile key values
get_profile:{[profile]
  all_profiles: read_profile_file[];
  if[not profile in key all_profiles; 'PROFILE_NOT_FOUND];
  all_profiles profile
 };

/ parse xml data
/ @param data (String) XML data string
/ @return (dict) XML tag-value dict
parse_xml:{[data]
  xml: raze each "\n" vs last "\r\n" vs data;
  t!xml_value[;xml] each t:("AccessKeyId";"SecretAccessKey";"SessionToken";"Expiration";"AssumedRoleId";"Arn")
 };

/ get value for tag from xml string
/ @param tag (string) xml tag 
/ @param xml (String) XML string
xml_value:{[tag;xml]
  d:first xml where xml like "*",tag,"*";
  first cut[(1 0)+(first;last)@'where @' "><" =\: d;d]
 };
\d .
