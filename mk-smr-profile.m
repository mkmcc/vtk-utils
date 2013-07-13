(* mk-smr-profile.m --- produce radial profiles from athena VTK outputs *)
(*   works with static mesh refinemnt (SMR), but assumes spherical symmetry. *)

(* Copyright (c) 2013 Mike McCourt *)

(* Code: *)
merged   = "merged";
basename = "output";

(* faster *)
mk1dprofile[data_] :=
    Module[{pro, x},
           pro = (data[[First[dim]/2, First[dim]/2,     All]] +
                  data[[First[dim]/2, First[dim]/2 + 1, All]])/2;
           x = Table[First[origin] + First[spacing]*(i - 0.5), {i, First[dim]}];
           Select[Transpose[{x, pro}], #[[1]] > 0 &]]

(* slower but more complete *)
mk3dprofile[data_] :=
    Module[{rdata, bdata},
           rdata = Table[{Norm[{i - First[dim]/2 - 0.5, 
                                j - First[dim]/2 - 0.5,
                                k - First[dim]/2 - 0.5}],
                          data[[i, j, k]]},
                         {i, First[dim]}, {j, First[dim]}, {k, First[dim]}];
           rdata = Partition[Flatten[rdata], 2];
           bdata = GatherBy[rdata, Floor[#[[1]]] &];
           bdata = Sort[Map[{First[spacing]*(Floor[#[[1, 1]]] + 0.5),
                             Mean[#[[All, 2]]]} &, bdata]];
           bdata]

mkprofile[data_] := mk1dprofile[data]

truncatelo[{hi_, lo_}] := Select[lo, #[[1]] > hi[[-1, 1]] &]

joinall[lst_] := Apply[Join,
                       Prepend[Map[truncatelo, Partition[Reverse[lst], 2, 1]],
                               Last[lst]]]


mksmrpprofile[num_] := 
    Module[{files, data},
           files = Map[# <> "/" <> basename <> "." <> num <> ".vtk" &,
                       Prepend[FileNames[merged <> "/lev*"], merged]];
           data = Map[mkprofile[readVTK[#, "pressure", "scalar"]] &, files];

           joinall[data]]

mksmrdprofile[num_] := 
    Module[{files, data},
           files = Map[# <> "/" <> basename <> "." <> num <> ".vtk" &,
                       Prepend[FileNames[merged <> "/lev*"], merged]];
           data = Map[mkprofile[readVTK[#, "density", "scalar"]] &, files];

           joinall[data]]

mksmrtprofile[num_] := 
    Module[{files, data},
           files = Map[# <> "/" <> basename <> "." <> num <> ".vtk" &,
                       Prepend[FileNames[merged <> "/lev*"], merged]];
           data = Map[
               mkprofile[(readVTK[#, "pressure", "scalar"]/
                          readVTK[#, "density", "scalar"])] &, files];

           joinall[data]]

mksmrkprofile[num_] := 
    Module[{files, data},
           files = Map[# <> "/" <> basename <> "." <> num <> ".vtk" &,
                       Prepend[FileNames[merged <> "/lev*"], merged]];
           data = Map[
               mkprofile[(readVTK[#, "pressure", "scalar"]/
                          readVTK[#, "density", "scalar"]^(5/3))] &, files];

           joinall[data]]
