require 'optparse'
require 'tempfile'

# separate out for debugging
#
def issue_command(str)
  puts str
end


# function to get the simulation time from the vtk header
# - this is ugly...
def get_vtk_time(file)
  # read the first 256 chars and split into lines
  a = IO.read(file, 256)
  a.split

  # parse out time= using a regex
  a = a.map{|l| l.sub!(/.*time= ([0-9e+\-\.]+).*/, '\1')}

  # return first non-empty line
  a = a.delete_if{|l| l==nil}
  a.first.to_f
end


# parse command-line options
options = {}
OptionParser.new do |opts|
  opts.banner = "usage: cleanup-vtk.rb [options]"

  opts.on('-d', '--dir dir', 'source directory') { |v| options[:dir] = v }
  opts.on('-t', '--time dt',  Float, 'dt between vtk dumps') { |v| options[:dt]  = v }
end.parse!

raise OptionParser::MissingArgument if options[:dir].nil?
raise OptionParser::MissingArgument if options[:dt].nil?
# "merged" directory
@dir = options[:dir].chomp('/')
unless @dir.match(/\/merged$/)
  @dir = @dir + '/merged'
end

@dt = options[:dt]



# vtk file names and identifiers (eg, "0015")
#
vtk_files = Dir.glob(@dir + '/*.vtk')
vtk_nums  = vtk_files.map{|f| f.sub(/.*\.([0-9]+)\.vtk$/, '\1')}


# calculate what the identifiers *should* be, based on the time and
# dt.  assume (somewhat arbitrarily) that times should match to two
# decimal places.
#
vtk_alt_nums = vtk_files.map{|f| (get_vtk_time(f)/@dt)}
vtk_alt_nums = vtk_alt_nums.map{|f| (f*100).round.to_f/100}

vtk_alt_nums = vtk_alt_nums.map do |f|
  tmp = f.to_s.chomp('.0')
  unless tmp.match(/\./)
    tmp = tmp.rjust(4,'0')
  end
  tmp
end


vtk_files.each_index do |i|
  old_file = vtk_files[i]

  # build new file name.  this is ugly
  pre  = old_file.sub(/(.*\.)[0-9]+\.vtk/, '\1')
  post = '.vtk'
  new_file = pre + vtk_alt_nums[i] + post

  if (old_file != new_file)
    if File.exist?(new_file)
      puts "WARNING: name conflict for #{new_file}"
      new_file = new_file + '_1'
    end
    issue_command("mv #{old_file} #{new_file}")
  end
end
