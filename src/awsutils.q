\d .awsutils
append_header:{[Tag; Val; Headers]
  if[10h = type Tag; Tag:`$Tag];
  Headers,enlist[Tag]!enlist Val
  };

append_header_old:{[Tag; Val; Headers]
  if[10h = type Tag; Tag:`$Tag];
  @[Headers;Tag;:;Val]
 };

to_json:{[Data]
  if[()~Data; :"{}"];
  .j.j Data
 };

/ TODO
is_dns_compliant_name:{[Bucket]
   1b
 };

/ XML Parser shortcuts;
/ TODO implement real parser (mini version)

/ Get value for tag from XML
xmlvalue:{[XML;Tag]
  (1+count Tag)_first t where (t:"<" vs XML) like\: Tag,">*"
 };

convert_to_xml:{[Data]
  if[1>=count Data;:Data]; / string case. no child
  children:raze convert_to_xml each Data 2;
  (raze/)"<",Data[0]," ",Data[1],">",children,"</",Data[0],">"
 }

\d .
