(* read-vtk.m ---  slurp an athena VTK file into a mathematica array *)

(* Copyright (c) 2013 Mike McCourt *)


(* readVTK: returns a named data block from a vtk file as a
     mathematica array.  stores `time', `origin', and `spacing' as
     global variables.

   example usage: 
     ListContourPlot[readVTK["merged/out.0020.vtk", "pressure", "scalar"][[1,All,All]]]
     ListStreamPlot[readVTK["merged/out.0020.vtk",  "velocity", "vector"][[1,All,All,{1,2}]]] 
*)
readVTK[file_String, label_String, type_String] :=
    Module[{str, n, data, dim,
            processLine, readTime}, 

           (* helper functions: *)
           (* - parse lines in the vtk header. *)
           (*   e.g. "DIMENSIONS 321 161 161" -> {321, 161, 161} *)
           processLine[line_String] :=
           Map[Read[StringToStream[#], Number] &,
               Drop[StringSplit[line, " "], 1]];

           (* - parse the time out of the comment field *)
           (*   eg "PRIMITIVE vars at time= 2.000000e+01, level= 0, domain= 0" -> 20 *)
           readTime[line_String] := 
           Block[{regex, timestring},
                 regex = RegularExpression["time=\\s*([0-9e\\.+\\-]+)"];
                 timestring = First[StringCases[line, regex -> "$1"]];
                 Read[StringToStream[timestring], Number]];


           (* open the file for reading: *)
           str = OpenRead[file, BinaryFormat -> True];


           (* read the header: *)
           time = readTime[Find[str, "time"]];

           dim = Map[If[# > 1, # - 1, #] &, 
                     processLine[Find[str, "DIMENSION"]]];
           n = Apply[Times, dim];

           origin  = processLine[Find[str, "ORIGIN"]];
           spacing = processLine[Find[str, "SPACING"]];


           (* find the data: *)
           Find[str, label];
           BinaryRead[str, "Character8"];
           If[type == "scalar", (* LOOKUP_TABLE *)
              Block[{}, Read[str, Record]; BinaryRead[str, "Character8"]]];


           (* read the data and close the file: *)
           If[type == "vector", n = 3*n];
           data = BinaryReadList[str, "Real32", n, 
                                 ByteOrdering -> +1];(* vtk is big-endian *)
           Close[str];


           (* store vectors in a 3D array so that data[[k,j,i]]={vx,xy,vz} *)
           If[type == "vector", data = Partition[data, 3]];

           (* Partition along the x, then y axes *)
           (* Output will always be a 3D array, but Nz and Ny may=1 *)
           data = Partition[data, dim[[1]]];
           data = Partition[data, dim[[2]]];
           data];
