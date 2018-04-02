\d .awsutils
append_header:{[Tag; Val; Headers]
  if[10h = type Tag; Tag:`$Tag];
  @[Headers;Tag;:;Val]
  };

to_json:{[Data]
  if[()~Data; :"{}"];
  .j.j Data
 };
\d .
