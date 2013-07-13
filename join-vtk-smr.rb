# join-vtk-smr.rb -- automatically splice together athena VTK outputs
#
# Copyright (c) 2013 Mike McCourt (mkmcc@berkeley.edu)
#
# Commentary:
#
#  This script attempts to "semi-intelligently" splice together the
#  vtk files output by an athena simulation.  It verifies that all
#  files are present and only processes un-merged files, so you can
#  safely run this as a simulation progresses.
#
#  Reads in files from the various id* directories produced by athena
#  and saves processed files in the new directory merged/
#
#  While this script attempts to be "semi-"intelligent, it is stupid
#  in at least one important way: it simultaneously opens all files
#  before processing them.  On most operating systems, this will cause
#  an error for simulations run on more than 1024 processors.
#
#  I use this script extensively in my own research, but I don't claim
#  to have thoroughly tested it.  Use at your own risk!

# Code:
require 'fileutils'

# isolate the call to system() for debugging.
#
def issue_cmd(cmd)
  system cmd
end


# need to know the # of processors
numprocs = Dir.glob("id*").nitems


# root files and refined files have different naming conventions --
# keep separate
#
rootfiles = Dir.glob("id*/*.vtk")
restfiles = Dir.glob("id*/lev*/*.vtk")


# base name and list of output numbers as string (e.g. "0012")
#
base = Dir.glob('id0/*.0000.vtk').first.gsub('.0000.vtk', '').gsub('id0/', '')
filenums = Dir.glob("id0/*.vtk").map{|f| f.gsub(/.*\.([0-9]{4})\.vtk/, '\1')}


# list of smr levels as strings
#
levels = restfiles.map{ |test| test.gsub(/id[0-9]+\/lev([0-9]+)\/.*/, '\1')}
levels.uniq!.sort!


# make directories to hold the merged files.
#
issue_cmd 'mkdir -p merged'

levels.each do |level|
  issue_cmd "mkdir -p merged/lev#{level}"
end


# loop over output numbers
#
filenums.each do |num|

  # root files first.  identify processors running the root grid and
  # build a list of file names to merge.
  #
  procs = rootfiles.map{|f| f.sub(/id([0-9]+).*/, '\1')}.uniq.sort

  infiles = procs.map{|d| "id#{d}/#{base}-id#{d}.#{num}.vtk"}
  infiles.map!{|file| file.gsub(/-id0/,"")}

  outfile = "merged/#{base}.#{num}.vtk"

  if (infiles.nitems < numprocs and not FileUtils.uptodate?(outfile, infiles))
    str = infiles.join(" ")
    cmd = "./join_vtk.x -o " + outfile + " " + str + " >& /dev/null"
    issue_cmd cmd
  end


  # next loop over the smr levels.  basically the same procedure as
  # before.
  #
  levels.each do |l|
    levfiles = restfiles.select{|file| file =~ /lev#{l}/}
    procs = levfiles.map{|f| f.sub(/id([0-9]+).*/, '\1')}.uniq.sort

    infiles = procs.map{|d| "id#{d}/lev#{l}/#{base}-id#{d}-lev#{l}.#{num}.vtk"}
    outfile = "merged/lev#{l}/#{base}.#{num}.vtk"

    if (infiles.nitems < numprocs and not FileUtils.uptodate?(outfile, infiles))
      str = infiles.join(" ")
      cmd = "./join_vtk.x -o " + outfile + " " + str + " >& /dev/null"
      issue_cmd cmd
    end
  end
end


# finally, copy the history files
#
hstfiles = Dir.glob("id0/*.hst") + Dir.glob("id0/lev*/*.hst")
hstfiles.each do |file|
  newfile = file.sub("id0/", "merged/")
  newfile.sub!(/-id[0-9]+-lev[0-9]+/,"")
  issue_cmd "cp #{file} #{newfile}"
end
