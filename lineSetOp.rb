#!/usr/bin/env -S ruby
# -*- Mode:Ruby; Coding:us-ascii-unix; fill-column:158 -*-
################################################################################################################################################################
##
# @file      lineSetOp.rb
# @author    Mitch Richling <https://www.mitchr.me>
# @brief     Set theory operations with sets defined by files -- each line is a member.@EOL
# @keywords  expression cap intersection cup + union union ddiff diff - diffrence rpl rpn stack element stack element symmetric
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
#  Based on a very old perl script -- simply translated into modern ruby.  Most of this can be done with standard UNIX commands; however, this script
#  makes things less complicated -- especially when doing more than one set operation in sequence.
#
################################################################################################################################################################

require 'set'

calcStack = Array.new
operators = [
  [ ['CAP',       'INTERSECTION' ], Proc.new { |s1, s2|         calcStack.push(s2.intersection(s1))                                                        }, ['Set itersection              | A B     => $A \cap B$              Stuff in both A and B        '] ],
  [ ['CUP',  '+', 'UNION'        ], Proc.new { |s1, s2|         calcStack.push(s2.union(s1))                                                               }, ['Set union                    | A B     => $A \cup B$              Stuff in A and/or in B       '] ],
  [ ['DIFF', '-', 'DIFFRENCE'    ], Proc.new { |s1, s2|         calcStack.push(s2.difference(s1))                                                          }, ['Set difference               | A B     => $A - B$                 Stuff only in A              '] ],
  [ ['SDIFF'                     ], Proc.new { |s1, s2|         calcStack.push(s2.difference(s1).union(s1.difference(s2)))                                 }, ['Set symmetric difference     | A B     => $(A - B) \cup (B - A)$  Stuff only in A or only in B '] ],
  [ ['DDIFF', '2DDIFF'           ], Proc.new { |s1, s2|         calcStack.push(s2.difference(s1)); calcStack.push(s1.difference(s2))                       }, ['Set "double" difference      | A B     => $A - B$                 Stuff only in A              ',
                                                                                                                                                               '                             |         => $B - A$                 Stuff only in B              '] ],
  [ ['3DIFF'                     ], Proc.new { |s1, s2|         calcStack.push(s3.difference(s2.union(s1)));
                                                                calcStack.push(s2.difference(s3.union(s1)));
                                                                calcStack.push(s1.difference(s3.union(s2)));
                                                                calcStack.push(s2.union(s1).difference(s3));
                                                                calcStack.push(s3.union(s1).difference(s2));
                                                                calcStack.push(s3.union(s2).difference(s1));                                               }, ['Set "double" difference      | A B C   => $A - (B \cup C)$        Stuff only in A              ',
                                                                                                                                                               '                             |         => $B - (A \cup C)$        Stuff only in B              ',
                                                                                                                                                               '                             |         => $C - (A \cup B)$        Stuff only in C              ',
                                                                                                                                                               '                             |         => $( B \cup C ) - A$      Stuff missing from A         ',
                                                                                                                                                               '                             |         => $( A \cup C ) - B$      Stuff missing from B         ',
                                                                                                                                                               '                             |         => $( A \cup B ) - C$      Stuff missing from C         '] ],
  [ ['DROP',      'DROP1'        ], Proc.new { |s1|                                                                                                        }, ['Drop stack element           | A       => (empty stack)                                        '] ],
  [ ['DUP',       'DUP1'         ], Proc.new { |s1|             calcStack.push(s1); calcStack.push(s1.clone)                                               }, ['Duplicate stack element      | A       => A A                                                  '] ],
  [ ['DUP2'                      ], Proc.new { |s1, s2|         calcStack.push(s2); calcStack.push(s1); calcStack.push(s2.clone); calcStack.push(s1.clone) }, ['Duplicate two stack elements | A B     => A A B B                                              '] ],
  [ ['ROT',       'ROT3'         ], Proc.new { |s1, s2, s3|     calcStack.push(s1); calcStack.push(s3); calcStack.push(s2)                                 }, ['Rotate three stack elements  | A B C   => B C A                                                '] ],
  [ ['ROT4'                      ], Proc.new { |s1, s2, s3, s4| calcStack.push(s1); calcStack.push(s4); calcStack.push(s3); calcStack.push(s2)             }, ['Rotate four stack elements   | A B C D => B C D A                                              '] ],
  [ ['SWAP',      'ROT2'         ], Proc.new { |s1, s2|         calcStack.push(s1); calcStack.push(s2)                                                     }, ['Swap two stack elements      | A B     => B A                                                  '] ],
]
opNames   = Set.new(operators.map { |n, p, d| n }.reduce(:+))

fieldNumberToUse = 0
fieldSeporator   = nil
ARGV.each do |arg|
  if(['-HELP', '--HELP', '-H'].member?(arg.upcase)) then
    puts('                                                                                                                                          ');
    puts('                                                                                                                                          ');
    puts('  lineSetOp.rb: Set-Operations on lines of files                                                                                          ');
    puts('  Special arguments: --f[ield]=INTEGER     Default: 1     Applies to files appearing on command line after argument. May be repeated.     ');
    puts('                                                          Ignored if separator is the empty string                                        ');
    puts('                     --s[eparator]=REGEX   Default: ""    Applies to files appearing on command line after argument. May be repeated.     ');
    puts('                                                          The empty string means: use the whole line.  Anything else is a regex used      ');
    puts('                                                          to split each line up into fields.  The field used is specified by --field      ');
    puts('                                                                                                                                          ');
    puts('  Arguments are sets (files containing one set element/line) and operations interpreted as an RPL expression.                             ');
    puts('                                                                                                                                          ');
    puts('  Operations:                                                                                                                             ');
    puts('     | OP                   | Desc                         | Stack Diagram                                                    |           ');
    operators.each do |n, p, d|
      printf("     | %-20s | %s |\n", n.join(', '), d[0])
      d.slice(1..-1).each do |dn|
        printf("     | %-20s | %s |\n", '', dn)
      end
    end
    puts('                                                                                                                                          ');
    puts('  Example 1:                                                                                                                              ');
    puts('    We have a list of packages we need to have on a system in "wantPKGs".  We have the set of PKGs originally on the system in            ');
    puts('    "oldPKGs", and a set of packages we just installed in "newPKGs".  We wish to know if any PKGs in "wantPKGs" are not installed.        ');
    puts('                                                                                                                                          ');
    puts('      lineSetOp.rb wantPKGs oldPKGs newPKGs CUP DIFF                                                                                      ');
    puts('                                                                                                                                          ');
    puts('  Example 2:                                                                                                                              ');
    puts('    We have a list of packages from two systems("host1PKGs" & "host2PKGs"), and we wish to know if they are identical.  So we             ');
    puts('    compute the symmetric difference,and check that we get the empty set:                                                                 ');
    puts('                                                                                                                                          ');
    puts('      lineSetOp.rb host1PKGs host2PKGs SDIFF                                                                                              ');
    puts('                                                                                                                                          ');
    puts('  Example 3:                                                                                                                              ');
    puts('    We have a list of packages from two systems("host1PKGs" & "host2PKGs"), and we wish to know what is installed on host1                ');
    puts('    that is NOT in installed on host2, so we compute the set difference:                                                                  ');
    puts('                                                                                                                                          ');
    puts('      lineSetOp.rb host1PKGs host2PKGs DIFF                                                                                               ');
    puts('                                                                                                                                          ');
    exit;
  elsif(tmp=arg.match(/^-+f[^=]*=([0-9]+)/)) then
    fieldNumberToUse=tmp[1].to_i - 1
  elsif(tmp=arg.match(/^-+s[^=]*=(.+)/)) then
    fieldSeporator = (tmp[1].length == 0 ? nil : Regexp.new(tmp[1]))
  elsif(opNames.member?(arg))
    if(FileTest.exist?(arg)) then
      STDERR.puts("lineSetOp(WARNING): Ambigous argument (#{arg} is both a set operation and the name of a file).  Assuming it is an operation!")
    end
    operators.each do |n, p, d|
      if(n.member?(arg)) then
        opArgs = Array.new
        p.arity.times do
          tmp = calcStack.pop
          if(tmp.nil?) then
            STDERR.puts("lineSetOp(ERROR): Too few arguments for operation #{arg}!")
            exit
          else
            opArgs.push(tmp)
          end
        end
        p.call(*opArgs)
      end
    end
  else
    if(FileTest.exist?(arg)) then
      open(arg, 'rb') do |file|
        newSet = Set.new
        file.each_line do |line|
          newMember = (fieldSeporator.nil? ? line.chomp : line.chomp.split(fieldSeporator)[fieldNumberToUse])
          if(newSet.member?(newMember))
            STDERR.puts("WARNING: Duplicate element (#{newMember}) in file #{arg}.\n")            
          end
          newSet.add(newMember)
        end
        calcStack.push(newSet)
      end
    else
      STDERR.puts("lineSetOp(ERROR): Set file not found: #{arg}!")
      if(opNames.member?(arg.upcase)) then
        STDERR.puts("lineSetOp(HINT): Did you mean #{arg.upcase}?")
      end
      exit
    end
  end
end

calcStackLength = calcStack.length
if(calcStackLength < 1)
  STDERR.puts("lineSetOp(ERROR): No result to print!")
else
  if(calcStackLength > 1)
    STDERR.puts("lineSetOp(WARNING): Result stack has more than one value!")
    calcStack.each_with_index do |resultSet, resultIndex|
      stackLevel=calcStackLength-resultIndex
      if(resultSet.length == 0)
        STDERR.puts("lineSetOp(INFO): Result at stack level #{stackLevel} set is empty!")
      end
      resultSet.sort.each do |element|
        printf("%2d: %s\n", stackLevel, element)
      end
    end
  else
    result = calcStack.pop
    if(result.length == 0)
      STDERR.puts("lineSetOp(INFO): Result set is empty!")
    end
    result.sort.each do |element|
      puts(element)
    end
  end
end
