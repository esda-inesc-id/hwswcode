
set XSA "src/project_1/design_1_wrapper.xsa"
set SRC "src/APP/iir.c"

setws .

platform create -name platform -hw ./src/project_1/design_1_wrapper.xsa -out .
domain create -name standalone_domain -os standalone -proc ps7_cortexa9_0

#platform write
#platform read platform/platform.spr

platform generate

platform active platform

app create -name app -domain standalone_domain
app config -name app -add libraries {m}
app config -name app -set compiler-optimization {Optimize more (-O2)}

file copy -force ./src/APP/iir.c app/src
file copy -force ./src/APP/lscript.ld app/src
file delete -force app/src/helloworld.c

app build -name app
