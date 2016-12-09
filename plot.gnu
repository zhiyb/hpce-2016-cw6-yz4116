#!/usr/bin/gnuplot -persist
#set terminal qt 0 font "Sans,9"
set terminal pdf colour
set title filename noenhanced
set format x "%g"
set xtics rotate
set grid xtics ytics mxtics mytics lt 1 lc rgb 'gray50', lt 1 lc rgb 'gray90'
set key outside top right height -1
plot for [i = 2:cols] filename using 1:i title columnheader with lp ps 0.5
