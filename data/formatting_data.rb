#!/usr/bin/ruby -w

require 'json'

HD_data = "PTC3_words_HD_E"
HF_data = "PTC3_words_HF_E"
LD_data = "PTC3_words_LD_E"
LF_data = "PTC3_words_LF_E"

#FILE_NAME = HD_data
#FILE_NAME = HF_data
#FILE_NAME = LD_data
FILE_NAME = LF_data

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

  output = File.open("F_" + FILE_NAME + ".csv", "w+")

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

