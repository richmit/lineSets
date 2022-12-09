#!/usr/bin/env -S ruby
# -*- Mode:Ruby; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      lineMapDiff.rb
# @author    Mitch Richling <https://www.mitchr.me>
# @brief     Compute the difference between two maps defined by files -- each line has a key & value.@EOL
# @keywords  associative array hash dictionary delta difference
# @std       Ruby 2.5
# @see       
# @copyright 
#  @parblock
#  Copyright (c) 1992,1995,2006,2018, Mitchell Jay Richling <https://www.mitchr.me> All rights reserved.
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
#  Based on a very old perl script -- simply translated into modern ruby.  
#
################################################################################################################################################################

$stdout.sync = true
$stderr.sync = true
outSections  = "LRDS"
outPrefix    = true
outDeltaDiff = false
outFieldSep  = ' '
keyField     = 0
valField     = 1
fieldSep     = Regexp.new('\s+')
calcStack    = Array.new
reportDone   = false
ARGV.each do |arg|
  if(reportDone) then
    STDERR.puts("\n\n\n\nERROR: Extra arguments starting with '#{arg}' were ignored.\n\n")
    exit
  elsif(['-HELP', '--HELP', '-H'].member?(arg.upcase)) then
    puts('                                                                                          ');
    puts('                                                                                          ');
    puts('  lineSetOp.rb: <[options] file>...                                                       ');
    puts('                                                                                          ');
    puts('    Prints a difference report for two maps/dictionaries.                                 ');
    puts('    The report has four parts:                                                            ');
    puts('       1) Lines prefixed by "L: ": KEYS found only in the first (left) map.               ');
    puts('       2) Lines prefixed by "R: ": KEYS found only in the second (right) map.             ');
    puts('       3) Lines prefixed by "D: ": KEYS found in both files but with different values.    ');
    puts('       4) Lines prefixed by "S: ": KEYS found in both files with the same valus.          ');
    puts('                                                                                          ');
    puts('  File Processing Options: (May be report. Apply to files following on the command line.) ');
    puts('       --k[eyField]=INTEGER     Default: 1                                                ');
    puts('       --v[alueField]=INTEGER   Default: 2                                                ');
    puts('       --s[eparator]=REGEX      Default: \s+                                              ');
    puts('                                                                                          ');
    puts('  Report Options: (Must appear before input files)                                        ');
    puts('       --r[eport]=SECTIONS      Default: LRDS                                             ');
    puts('         Which sections, in the order given, are to be printed in the report              ');
    puts('       --p[refix]=BOOLEAN       Default: true                                             ');
    puts('         Print, or not, the prefix on each line of the report                             ');
    puts('       --o[utSeparator]=STRING  Default: " "                                              ');
    puts('         Used to separate values when the --diffDelta command line option is true         ');
    puts('       --d[iffDelta]=BOOLEAN    Default: true                                             ');
    puts('         In this mode the D section outputs the key, left value, and right value          ');
    puts('         separated by the separator specified by the --outSeparator option.               ');
    puts('                                                                                          ');
    puts('  Not-option arguments are files defining the maps (key/value pairs).                     ');
    puts('  These "map files" have one key/value per line.                                          ');
    puts('                                                                                          ');
    puts('  Example 1:                                                                              ');
    puts('    We which to know which packages are installed only on one system, and which packages  ');
    puts('    are installed on both but differ in version number.  So we create files for each      ');
    puts('    system with the package & version info.  For example, if we were using pacman as the  ');
    puts('    package manager, we might run `pacman -Q > hostNpackages.txt` on each system. Then    ');
    puts('    we get a report like so:                                                              ');
    puts('                                                                                          ');
    puts('      lineMapDiff.rb host1packages.txt host2packages.txt                                  ');
    puts('                                                                                          ');
    puts('  Example 2:                                                                              ');
    puts('    Same as previous example, but INSTALL all packages on system 2 that are not already   ');
    puts('    on system 1.  If pacman is our package manager:                                       ');
    puts('      pacman -S `lineMapDiff.rb -r=L -p=F host1packages.txt host2packages.txt`            ');           
    puts('                                                                                          ');
    exit
  elsif(tmp=arg.match(/^-+r[^=]*=(.+)/)) then
    outSections=tmp[1]
  elsif(tmp=arg.match(/^-+p[^=]*=(.+)/)) then
    v=tmp[1]
    outPrefix = v.match(/^[YyTt]/)
  elsif(tmp=arg.match(/^-+d[^=]*=(.+)/)) then
    v=tmp[1]
    outDeltaDiff = v.match(/^[YyTt]/)
  elsif(tmp=arg.match(/^-+o[^=]*=(.+)/)) then
    outFieldSep=tmp[1]
  elsif(tmp=arg.match(/^-+k[^=]*=([0-9]+)/)) then
    keyField=tmp[1].to_i - 1
  elsif(tmp=arg.match(/^-+v[^=]*=([0-9]+)/)) then
    valField=tmp[1].to_i - 1
  elsif(tmp=arg.match(/^-+s[^=]*=(.+)/)) then
    fieldSep = Regexp.new(tmp[1])
  else
    if(FileTest.exist?(arg)) then
      open(arg, 'rb') do |file|
        newHash = Hash.new
        file.each_line do |line|
          fields = line.chomp.split(fieldSep)
          if(newHash.member?(fields[keyField])) then
            if(newHash[fields[keyField]] == fields[valField]) then
              STDERR.puts("WARNING: Duplicate key (#{fields[keyField]}) with identical values (#{fields[valField]}) in file #{arg}.\n")
            else
              STDERR.puts("WARNING: Duplicate key (#{fields[keyField]}) with diffrent values (#{newHash[fields[keyField]]} != #{fields[valField]}) in file #{arg}.\n")
            end
          else
            newHash[fields[keyField]] =  fields[valField]
          end
        end
        calcStack.push(newHash)
        if(calcStack.length == 2) then
          outSections.each_char do |section|
            if( !(["L", "R", "D", "S"].member?(section))) then
              STDERR.puts("ERROR: Unknown report section in --report option: #{char}.\n")
            elsif(section=="L")
              calcStack[0].sort.each do |leftKey, leftValue|
                if ( !(calcStack[1].member?(leftKey))) then
                  printf("%s%s\n", (outPrefix ? "#{section}: " : ''), leftKey)
                end
              end
            elsif(section=="R")
              calcStack[1].sort.each do |rightKey, rightPackageVersion|
                if ( !(calcStack[0].member?(rightKey))) then
                  printf("%s%s\n", (outPrefix ? "#{section}: " : ''), rightKey)
                end
              end
            elsif(section=="D")
              calcStack[1].sort.each do |rightKey, rightPackageVersion|
                if ( calcStack[0].member?(rightKey)) then
                  if (calcStack[0][rightKey] != rightPackageVersion) then
                    if(outDeltaDiff) then
                      printf("%s%s%s%s%s%s\n", (outPrefix ? "#{section}: " : ''), rightKey, outFieldSep, calcStack[0][rightKey], outFieldSep, rightPackageVersion)
                    else
                      printf("%s%s\n", (outPrefix ? "#{section}: " : ''), rightKey)
                    end
                  end
                end
              end
            elsif(section=="S")
              calcStack[1].sort.each do |rightKey, rightPackageVersion|
                if (calcStack[0].member?(rightKey)) then
                  if (calcStack[0][rightKey] == rightPackageVersion) then
                    printf("%s%s\n", (outPrefix ? "#{section}: " : ''), rightKey)
                  end
                end
              end
            end
          end
          reportDone = true
        end
      end
    else
      STDERR.puts("Unable to open file: #{arg}")
      exit
    end
  end
end
