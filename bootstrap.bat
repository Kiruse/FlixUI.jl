@echo off
set JULIA_NUM_THREADS=8
if [%2]==[] (
    julia %1
) else (
    julia %1 -- %2
)
