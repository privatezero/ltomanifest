#!/usr/bin/env ruby

require 'bagit'
require 'yaml'
require 'optparse'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: ltomanifest.rb [option] [inputfile]"

  opts.on("-m", "--make", "Make manifest") do |e|
    options[:make] = 'make'
  end
  opts.on("-c", "--confirm", "Confirm manifest") do |d|
    options[:create] = 'create'
  end
  opts.on("-h", "--help", "Help") do
    puts opts
    exit
  end
  if ARGV.empty?
    puts opts
  end
end.parse!

input=ARGV
TargetBags = Array.new

def Create_manifest(input)
#Check and limit input
  if input.length > 1
    puts "Please only use one directory as input. Exiting."
    exit
  else
    input = input[0]
  end

  if ! File.directory?(input)
    puts "Input is not a valid directory. Exiting"
    exit
  end
  #Get list of directories
  Dir.chdir(input)
  bag_list = Dir.glob('*')
  #Check if supposed bags are actually directories
  bag_list.each do |isdirectory|
    if ! File.directory?(isdirectory)
      puts "Warning! Files not contained in bags found at -- #{isdirectory} -- Exiting."
      exit
    end
  end

  #Check if directories are bags (contains metadata files)
  bag_list.each do |isbag|
    if ! File.exist?("#{isbag}/bag-info.txt") || ! File.exist?("#{isbag}/bagit.txt")
      puts "Warning! Unbagged directory found at -- #{isbag} Exiting."
    end
  end

  #Verify all bags are valid bags
  bag_list.each do |isvalidbag|
    bag = BagIt::Bag.new isvalidbag
    if bag.valid?
      TargetBags << isvalidbag
    else
      puts "Warning! Invalid Bag Detected at -- #{isvalidbag} -- Dumping List of Validated Bags and Exiting!"
        data = {"ConfirmedBags" => TargetBags}
        File.write('BagListDump.txt',data.to_yaml)
      exit
    end
  end
  targetBagsSorted = TargetBags.sort
  bagcontents = Array.new
  #Gather checksums from individual bags
  targetBagsSorted.each do |bagparse|
    metafile = "#{bagparse}/manifest-md5.txt"
    contents = File.readlines(metafile)
    bagcontents << bagparse
    bagcontents << contents
  end
  puts bagcontents

  #Write manifest of bags and checksums
  data = {"Bag List" => targetBagsSorted, "Contents" => bagcontents}
  File.write('manifest.txt',data.to_yaml)
end

def auditmanifest(input)
  manifestlocation = File.dirname(input)
  manifestinfo = YAML::load_file(input)
  bags = package['Bag List']
  Dir.chdir(manifestlocation)
  bags.each do |isvalidbag|
    bag = BagIt::Bag.new isvalidbag
    if bag.valid?
      puts "Contents Confirmed: #{isvalidbag}"
    end
  end
end

Create_manifest(input)