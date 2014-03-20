#!/usr/bin/ruby -w

require 'json'

HD_data = "PTC3-words-HD-E"
HF_data = "PTC3-words-HF-E"
LD_data = "PTC3-words-LD-E"
LF_data = "PTC3-words-LF-E"

HD95data = "PTC3-words95-HD-E"
HF95data = "PTC3-words95-HF-E"
LD95data = "PTC3-words95-LD-E"
LF95data = "PTC3-words95-LF-E"
HD99data = "PTC3-words99-HD-E"
HF99data = "PTC3-words99-HF-E"
LD99data = "PTC3-words99-LD-E"
LF99data = "PTC3-words99-LF-E"
HDnulldata = "PTC3-wordsnull-HD-E"
HFnulldata = "PTC3-wordsnull-HF-E"
LDnulldata = "PTC3-wordsnull-LD-E"
LFnulldata = "PTC3-wordsnull-LF-E"

FILE_NAME = LFnulldata

def formatting_data
  flow_data = File.open(FILE_NAME + ".csv", "r")
  timetable = Hash[(0..600).map{|v| [v,[]]}]

  flow_data.each_with_index do |line, index|
    next if index == 0

    arr = line.split(',')
    source = arr[0].to_i
    target = arr[1].to_i 
    arr[5..-1].each_with_index do |v, i| 
      next if v.to_i == 0

      timetable[i] << [source, target]
      #puts "#{i}: #{source}, #{target}"
    end
  end

  output = File.open("F-" + FILE_NAME + ".csv", "w+")

  timetable.keys.each_with_index do |time_slot, index|
    timetable[time_slot].each do |packet|
      output << "t#{index.to_s.rjust(3,'0')}, #{packet[0]}, #{packet[1]}\n"
    end
  end

  output.close
end

if $0 == __FILE__
  formatting_data
end

