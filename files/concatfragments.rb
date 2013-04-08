#!/opt/puppet/bin/ruby
require 'fileutils'

outfile = false
workdir = false
sortarg =''
force = false
warnmsg = ''
test = false

ARGV.each_with_index do |arg,index|
  case arg
    when '-o': outfile = ARGV[index+1]
    when '-d': workdir = ARGV[index+1]
    when '-n': sortarg = 'N'
    when '-f': force = true
    when '-w': warnmsg = ARGV[index+1]
    when '-t': test = true
  end
end

# p "outfile: #{outfile}"
# p "workdir: #{workdir}"
# p "force: #{force}"
# p "test: #{test}"
# p "warnmsg: #{warnmsg}"

if ! outfile
  abort('Please pass the -o option to supply an output file')
end
if ! workdir
  abort('Please pass the -d option to supply an working directory')
end

unless File.directory?(workdir)
  abort('The working directory does not exist')
end

if File.exists?(outfile)
  unless File.writable?(outfile)
    abort('The output file is not writable')
  end
else
  unless File.writable?(File.dirname(outfile))
    abort('The parent directory of the output file is not writable')
  end
end

unless File.directory?("#{workdir}/fragments") and File.writable?("#{workdir}/fragments")
  abort('The fragments directory does not exist or is not writable')
end

if Dir.entries("#{workdir}/fragments").reject { |x| x =~ /^\.+$/ }.empty? and ! force
  abort('Cowardly refusing to create empty configuration files')
end

concatfile = File.open("#{workdir}/fragments/fragment.concat",'w')
concatfile.write "#{warnmsg}\n" if warnmsg

Dir.entries("#{workdir}/fragments").reject { |x| x =~ /^\.+$/ }.reject{ |x| x == 'fragments.concat' }.sort.each do |file|
  concatfile.write File.read("#{workdir}/fragments/#{file}")
end
concatfile.flush
if test
  begin
    exit FileUtils.compare_file(concatfile.path,outfile)
  rescue Errno::ENOENT
    exit 1
  end
else
  FileUtils.copy(concatfile.path,outfile)
end
