# dosrt
My DOS graphics experiments. Maybe one day it'll become a raytracer.
# Architecture
The core raytracer is split into modules that abstract functionality (e. g. display output). The MODULES.DEF file contains the list of modules that are currently in use (this is used during assembler execution) by including the respective module sources.
# Build
In a FreeDOS shell with the fasm package:
`fasm CORE.ASM OUTPUT.EXE`

# 

Written entirely in FreeDOS EDIT 0.9.
