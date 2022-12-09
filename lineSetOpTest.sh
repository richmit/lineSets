#!/bin/bash

# Functional tests for lineSetOp.rb

printf "A\n" > setA
printf "B\n" > setB
printf "C\n" > setC
printf "D\n" > setD

printf "A\nB\n" > setAB
printf "A\nC\n" > setAC

declare -A OPSX
OPSX[DROP1]=" 3: A\n 2: B\n 1: C\n"
OPSX[DROP]=" 3: A\n 2: B\n 1: C\n"
OPSX[DUP1]=" 5: A\n 4: B\n 3: C\n 2: D\n 1: D\n"
OPSX[DUP2]=" 6: A\n 5: B\n 4: C\n 3: D\n 2: C\n 1: D\n"
OPSX[DUP]=" 5: A\n 4: B\n 3: C\n 2: D\n 1: D\n"
OPSX[ROT3]=" 4: A\n 3: D\n 2: B\n 1: C\n"
OPSX[ROT4]=" 4: D\n 3: A\n 2: B\n 1: C\n"
OPSX[ROT]=" 4: A\n 3: D\n 2: B\n 1: C\n"
OPSX[SWAP]=" 4: A\n 3: B\n 2: D\n 1: C\n"

for op in "${!OPSX[@]}"; do 
  printf "%-15s : " $op
  if diff -q <(ruby lineSetOp.rb setA setB setC setD $op 2>/dev/null | dos2unix) <(printf "${OPSX[$op]}") >/dev/null; then
    echo PASS
  else
    echo FAIL
  fi
done

declare -A OPSS
OPSS[CAP]="A\n"           
OPSS[INTERSECTION]="A\n"           
OPSS[CUP]="A\nB\nC\n"     
OPSS[+]="A\nB\nC\n"     
OPSS[UNION]="A\nB\nC\n"     
OPSS[DIFF]="B\n"           
OPSS[-]="B\n"           
OPSS[DIFFRENCE]="B\n"           
OPSS[SDIFF]="B\nC\n"        
OPSS[DDIFF]=" 2: B\n 1: C\n"

for op in "${!OPSS[@]}"; do 
  printf "%-15s : " $op
  if diff -q <(ruby lineSetOp.rb setAB setAC $op 2>/dev/null | dos2unix) <(printf "${OPSS[$op]}") >/dev/null; then
    echo PASS
  else
    echo FAIL
  fi
done

rm setA
rm setB
rm setC
rm setD

rm setAB
rm setAC
