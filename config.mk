VERSION=0.1.0

# Customize below to fit your system

# paths
PREFIX=/usr/local

# program customisation

# -D_PERF prints performance information and -D_DEBUG details
# what's going on as the program looks for a solution.
#
# -D_HEURISTICS_JWOS enables the Joroslow-Wang heuristic for
# branch selection.
#
# -D_RECURSION_THRESHOLD=x sets the maximum number of recursive
# calls to `solve` to the value x.
ADDCFLAGS=-D_RECURSION_THRESHOLD=1000000 -D_PERF -D_HEURISTICS_JWOS # -D_DEBUG

# flags
CFLAGS = -ansi -Wall -Wextra -Wwrite-strings \
         -Wno-unused-variable -Wno-unused-function -Wno-variadic-macros \
         -Iinclude/ -g -O2
LDFLAGS =


# compiler and linker
CC=gcc
LD=$(CC)
