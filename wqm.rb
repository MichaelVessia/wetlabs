#!/usr/bin/env ruby
# encoding: utf-8

# Author: Michael Vessia
# Town of Hempstead Department of Conservation and Waterways

# Using the csv library
require 'csv'

# Define lookup table for valid column names with some common changes
@header_hash = {
  'CHLa(Counts)' => 'RawCHL(CTS)',
  'CHLa(ug/l)' => 'CHL(ug/l)',
  'Turbidity(Counts)' => 'RawTurbidity(CTS)',
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
  'RawCHL(CTS)' => 14,
  'CHL(ug/l)' => 15,
  'RawTurbidity(CTS)' => 16,
  'NTU' => 17,
  'SoundVelocity(m/s)' => 18,
  'Volts' => 19
}

# Add any potentially missing columns here.
# ex. WQM150 does not have DO(ml/l)
@missing_columns = ['Status', 'SoundVelocity(m/s)', 'DO(ml/l)']

# Prompt user for file name
puts 'Please enter csv file name'
@file_name = gets.chomp

@orig_head = []

# Rename headers, given a header row as input
def rename_headers(header)
  # First element of header will be timestamp
  new_headers_arr = ['Timestamp']

  # For each current header, replace value with lookup table value if it exists
  header.drop(1).each do |col_name|
    col_name = @header_hash[col_name] if @header_hash.key?(col_name)
    new_headers_arr.insert(@col_num_hash[col_name], col_name)
  end
  @missing_columns.each do |miss|
    unless new_headers_arr.include?(miss)
      new_headers_arr[@col_num_hash[miss]] = miss
    end
  end
  new_headers_arr.join(',')
end

# Fix the data given the original header and the current row
def fix_data(data_row)
  # Coerce into arrays for manipulation
  orig_head_arr = @orig_head.to_a
  data_row_arr = data_row.fields

  # Insert N/A if original header did not contain key
  @col_num_hash.keys.each do |key|
    next if key == 'Timestamp' # Special case
    unless  orig_head_arr.include?(key) || orig_head_arr.include?(@header_hash.key(key))
      data_row_arr.insert(@col_num_hash[key], 'N/A')
    end
  end
  data_row_arr.join(',')
end


# Read line from file, modify, and write back out
lc = 1
File.open("edited_#{@file_name}", 'w') do |fo|
  CSV.foreach(@file_name, headers: true) do |row|
    if lc == 1
      lc += 1
      @orig_head = row.headers
      fo.puts rename_headers(row.headers)
    else
      fo.puts fix_data(row)
    end
  end
end
