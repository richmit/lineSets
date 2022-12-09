#!/usr/bin/env -S ruby
# -*- Mode:Ruby; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      uniq.rb
# @author    Mitch Richling <https://www.mitchr.me>
# @brief     Remove duplicate lines from a file.@EOL
# @keywords  sort uniq
# @std       Ruby1.8
# @see       
# @copyright 
#  @parblock
#  Copyright (c) 2010, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
#
#  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
#
#  1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
#
#  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#
#  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
#     specific prior written permission.
#
#  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
#  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#  @endparblock
# @filedetails
#
#  This is a super-duper version of uniq that doesn't require sorted files to work, and outputs the resulting lines in the order they were given.
#  
#  Output is always to STDOUT. If given an argument, it s the name of the file to process.  Any args after the first are ignored.  A name of '-' may be given
#  to indicate STDIN.  Without an argument, STDIN is processed.
#
################################################################################################################################################################

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
begin
  if (ARGV.length > 1) then
    raise
  end

  infile = STDIN
  if ((ARGV.length >= 1) && (ARGV[0] != '-')) then
    infile = open(ARGV[0], 'r')
  end
  
  lineHash = Hash.new
  infile.each_line do |line|
    if ( !(lineHash.member?(line))) then
      lineHash[line] = 1
      puts(line)
    else
      # Line was seen before
    end
  end
rescue String
  puts("Yikes.")
rescue 
  if (ARGV.length > 1) then
    puts("ERROR: Too many arguments provided!")
  elsif (ARGV[0]) then
    puts("ERROR: I/O problem reading data from file: #{ARGV[0]}!")
  else
    puts("ERROR: I/O problem reading data from STDIN!")
  end
  puts("USE: uniq.rb [file_name|-]")
  puts("     If no file provided, STDIN is used.")
end
