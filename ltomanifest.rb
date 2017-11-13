#!/usr/bin/env ruby

require 'bagit'
require 'yaml'
require 'optparse'

option = {}

OptionParser.new do |opts|
  opts.banner = "Usage: ltomanifest.rb [option] [inputfile]"

  opts.on("-m", "--make", "Make manifest") do |e|
    option = 'make'
  end
  opts.on("-c", "--confirm", "Confirm manifest") do |d|
    option = 'confirm'
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

# Methods for colored text output
def red(input)
  puts "\e[31m#{input}\e[0m"
end

def green(input)
  puts "\e[36m#{input}\e[0m"
end

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

  #Write manifest of bags and checksums
  data = {"Bag List" => targetBagsSorted, "Contents" => bagcontents}
  File.write('manifest.txt',data.to_yaml)
  puts "Manifest written at #{input}/manifest.txt"
end

def Auditmanifest(input)
  if input.length > 1
    puts "Please only use one maifest file as input. Exiting."
    exit
  else
    input = input[0]
  end
  manifestlocation = File.dirname(input)
  manifestinfo = YAML::load_file(input)
  bags = manifestinfo['Bag List']
  Dir.chdir(manifestlocation)
  #Confirm validity of all bags listed in manifest file
  confirmedBags = Array.new
  problemBags = Array.new
  bags.each do |isvalidbag|
    bag = BagIt::Bag.new isvalidbag
    if bag.valid?
      green("Contents Confirmed: #{isvalidbag}")
      confirmedBags << isvalidbag
    else
      puts "Warning: Invalid bag found at -- #{isvalidbag}"
      problemBags << isvalidbag
    end
  end
  #List warning of problem bags
  if problemBags.length > 0
    red("These Bags Failed Verification")
    red(problemBags)
  else
    green("All Bags Verified Successfully")
  end
end

if option == 'make'
  Create_manifest(input)
end
if option == 'confirm'
  Auditmanifest(input)
end
