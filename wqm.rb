#!/usr/bin/env ruby
# encoding: utf-8

# Author: Michael Vessia
# Town of Hempstead Department of Conservation and Waterways

# Using the csv library for csv handling
require 'csv'
# Using fileutils for deleting files
require 'fileutils'

# Define lookup table for valid column names with some common changes
# Add any desired changes here
@header_hash = {
  'CHLa(Counts)' => 'RawCHL(cts)',
  'CHLa(ug/l)' => 'CHL(ug/l)',
  'Turbidity(Counts)' => 'RawTurbidity(cts)',
  'SV(m/s)' => 'SoundVelocity(m/s)',
  'Turbidity(NTU)' => 'NTU'
}

# Define lookup table for valid column positions
# Changes here **should** change the output header+data appropriately
@col_num_hash = {
  'Timestamp' => 0,
  'WQM' => 1,
  'SN' => 2,
  'Status' => 3,
  'Date(mmddyy)' => 4,
  'Time(hhmmss)' => 5,
  'Cond(S/m)' => 6,
  'Temp(C)' => 7,
  'Pres(dbar)' => 8,
  'Sal(PSU)' => 9,
  'RawDO(Hz)' => 10,
  'DO(ml/l)' => 11,
  'DO(mg/l)' => 12,
  'PercentOxSat(%)' => 13,
  'RawCHL(cts)' => 14,
  'CHL(ug/l)' => 15,
  'RawTurbidity(cts)' => 16,
  'NTU' => 17,
  'SoundVelocity(m/s)' => 18,
  'Volts' => 19
}

# List of WQM numbers. Add any new WQMs here
@wqms = [147, 148, 149, 150]

# Prompt user for file name
puts 'Please enter a file name for the data. Example: data.txt'
@file_name = gets.chomp

@headers = {}


# Fix the data given the current row
# Inserts NA's where the wqm had no data for that column
def fix_data(data_row)
  return if data_row.nil?

  # Coerce into arrays for manipulation
  orig_head_arr = data_row.headers.compact
  data_row_arr = data_row.fields.compact
  
  # Insert N/A if original header did not contain key
  @col_num_hash.keys.each do |key|
    next if key == 'Timestamp' # Special case

    unless orig_head_arr.include?(key) || orig_head_arr.include?(@header_hash.key(key))
      data_row_arr.insert(@col_num_hash[key], 'NA')
    end
  end

  data_row_arr.join(',')
end

# Accepts an array of filenames produced by fix_txt
# Merges these temporary csv's into a single csv
# The single csv will have appropriate headers
# with NA anywhere there was no data
def fix_csv(csv_filenames)
  # Read line from file, modify, and write back out
  first_line = true
  new_file_name = "#{@file_name[0...-3]}csv"
  # Open final csv for output
  File.open(new_file_name, 'w') do |fo|
    # Iterate over tmp csv files
    csv_filenames.each do |csv|
      # Go through each line of tmp csv
      CSV.foreach(csv, headers: true) do |row|
        if first_line
          headers = @col_num_hash.keys
          fo.puts headers.join(',')
          first_line = false
        else
          fo.puts fix_data(row)
        end
      end
    end
  end
end

# Turns the original text file into n temporary csv files
# where n is the number of WQMs that were logged in the txt
# Returns an array of file names for fix_csv
# Naively Runs through the entire file @wqms.length times
# Additional information on data formatting needed,
# could potentially reduce this to a single pass
def fix_txt
  tmp_file_arr = []

  # Pull the headers out of input file, store in array
  headers = extract_headers

  # For each wqm number
  @wqms.each do |wqm|
    # Open tmp csv for writing
    File.open("tmp_#{wqm}.csv", 'w') do |fo|
      # Open input file for reading
      fi = File.open(@file_name, 'r')
      tmp_file_arr << "tmp_#{wqm}.csv"
      header_written = false
      # For each line in input file
      fi.each_line do |line|
        line = line.scrub
        if line.include?("WQM,#{wqm}")
          line.gsub!(/\\"/, '')
          line.gsub!(/\"/, '')
          line.strip!

          # If we haven't written the header yet, write it now
          unless header_written
            @headers[wqm] = headers.first
            fo.puts headers.shift
            header_written = true
          end
          fo.puts line
        end
      end
    end
  end
  tmp_file_arr
end

# Makes a single linear pass through the txt file
# Pulls out all of the headers and returns an array
# Containing the unique headers
def extract_headers
  header_set = []
  fi = File.open(@file_name, 'r')
  fi.each_line do |line|
    if line.include?('Temp(C)')

      line = line.scrub
      line.gsub!(/\\"/, '')
      line.gsub!(/\"/, '')
      line.strip!
      line = line.split(',')
      line[0] = "Timestamp"
      header_set << line.join(',')
    end
  end
  header_set.uniq
end

# Remove temporary files that were used
def clean_up
  Dir.foreach(Dir.pwd) do |f|
    if !f.start_with?('tmp_') then next
    elsif File.directory?(f) then FileUtils.rm_rf(f)
    else FileUtils.rm(f)
    end
  end
end

fix_csv(fix_txt)
clean_up
