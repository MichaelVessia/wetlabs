#!/usr/bin/env ruby
# encoding: utf-8

# Author: Michael Vessia
# Town of Hempstead Department of Conservation and Waterways

# Using the csv library for csv handling
require 'csv'
# Using fileutils for deleting files
require 'fileutils'

# Define lookup table for valid column names with some common changes
@header_hash = {
  'CHLa(Counts)' => 'RawCHL(cts)',
  'CHLa(ug/l)' => 'CHL(ug/l)',
  'Turbidity(Counts)' => 'RawTurbidity(cts)',
  'SV(m/s)' => 'SoundVelocity(m/s)',
  'Turbidity(NTU)' => 'NTU'
}

# Define lookup table for valid column positions
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

# List of WQM numbers
@wqms = [147, 148, 149, 150]

# Prompt user for file name
puts 'Please enter txt file name'
@file_name = gets.chomp

# Rename headers, given a header row as input
def rename_headers(header)
  header[0] = 'Timestamp'
  # For each current header, replace value with lookup table value if it exists
  header.drop(1).each do |col|
    if @header_hash.key?(col)
      header.delete(col)
      col = @header_hash[col]
      header.insert(@col_num_hash[col], col)
    end
  end

  header
end

def add_missing_cols(header)
  missing_columns = []
  @col_num_hash.keys.each do |col|
    missing_columns << col unless header.include?(col)
  end

  missing_columns.each do |miss|
    next if header.include?(miss)
    header.insert(@col_num_hash[miss], miss)
  end
  header
end

def fix_header_format(header)
  return @col_num_hash.keys if header.nil?
  header = header.map { |s| s.split(',') }.flatten
  header = rename_headers(header)
  header = add_missing_cols(header)
  header
end

# Fix the data given the original header and the current row
def fix_data(data_row)
  return if data_row.nil?

  # Coerce into arrays for manipulation
  orig_head_arr = data_row.headers
  data_row_arr = data_row.fields

  # Insert N/A if original header did not contain key
  @col_num_hash.keys.each do |key|
    next if key == 'Timestamp' # Special case

    unless orig_head_arr.include?(key) || orig_head_arr.include?(@header_hash.key(key))
      data_row_arr.insert(@col_num_hash[key], 'N/A')
    end
  end
  data_row_arr.join(',')
end

def fix_csv(csv_filenames)
  # Read line from file, modify, and write back out
  first_line = true
  new_file_name = "#{@file_name[0...-3]}csv"
  File.open(new_file_name, 'w') do |fo|
    csv_filenames.each do |csv|
      CSV.foreach(csv, headers: true) do |row|
        if first_line
          headers = fix_header_format(row.headers)
          fo.puts headers.join(',')
          first_line = false
        else
          fo.puts fix_data(row)
        end
      end
    end
  end
end

def fix_txt
  tmp_file_arr = []
  headers = extract_headers

  @wqms.each do |wqm|
    File.open("tmp_#{wqm}.csv", 'w') do |fo|
      fi = File.open(@file_name, 'r')
      tmp_file_arr << "tmp_#{wqm}.csv"
      header_written = false
      fi.each_line do |line|
        line = line.scrub
        if line.include?("WQM,#{wqm}")
          line.gsub!(/\\"/, '')
          line.gsub!(/\"/, '')
          line.strip!

          unless header_written
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

def extract_headers
  header_set = []
  fi = File.open(@file_name, 'r')
  fi.each_line do |line|
    if line.include?('Temp(C)')
      line = line.scrub
      line.gsub!(/\\"/, '')
      line.gsub!(/\"/, '')
      line.strip!
      header_set << line
    end
  end
  header_set.uniq
end

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
