(* read-vtk.m ---  slurp an athena VTK file into a mathematica array *)

(* Copyright (c) 2013 Mike McCourt *)

(* examples: 
     ListContourPlot[readVTK["merged/out.0020.vtk", "pressure", "scalar"][[1,All,All]]]
     ListStreamPlot[readVTK["merged/out.0020.vtk",  "velocity", "vector"][[1,All,All,{1,2}]]] *)

processLine[line_String] :=
    Map[Read[StringToStream[#], Number] &,
        Drop[StringSplit[line, " "], 1]];

readVTK[file_String, label_String, type_String] :=
    Module[{str, n, data}, 
           str = OpenRead[file, BinaryFormat -> True];

           (* Read the time *)
           t = Block[{headerline, timestring},
                     (* eg "PRIMITIVE vars at time= 2.000000e+01, level= 0, domain= 0" *)
                     headerline = Find[str, "time"];

                     (* eg "2.000000e+01" *)
                     timestring = First[StringCases[headerline, 
                                                    RegularExpression["time=\\s*([0-9e\\.+\\-]+)"] -> "$1"]];

                     (* convert from string to number *)
                     Read[StringToStream[timestring], Number]];

           (*Read the header*)
           dim = Map[If[# > 1, # - 1, #] &, 
                     processLine[Find[str, "DIMENSION"]]];
           n = Apply[Times, dim];
           origin  = processLine[Find[str, "ORIGIN"]];
           spacing = processLine[Find[str, "SPACING"]];

           (*Find the data*)
           Find[str, label];
           BinaryRead[str, "Character8"];
           If[type == "scalar", (*LOOKUP_TABLE*)
              Block[{}, Read[str, Record]; BinaryRead[str, "Character8"]]];

           (*Read the data and close the file*)
           If[type == "vector", n = 3*n];
           data = BinaryReadList[str, "Real32", n, ByteOrdering -> +1];(*vtk is big-endian*)
           Close[str];
           (*store in a 3D array so that data[[k,j,i]]={vx,xy,vz}*)

           If[type == "vector", data = Partition[data, 3]];
           (*Partition along the x, then y axes*)
           (*Output will always be a 3D array, but Nz and Ny may=1*)
           data = Partition[data, dim[[1]]];
           data = Partition[data, dim[[2]]];
           data];
