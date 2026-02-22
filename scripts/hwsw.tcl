#build the hwsw platform application using the provided xsa and source files

set xsa [lindex $argv 0]
set srcs [lrange $argv 1 end]

setws .

platform create -name platform -hw $xsa -out .
domain create -name standalone_domain -os standalone -proc ps7_cortexa9_0
platform generate
platform active platform

app create -name hwsw -domain standalone_domain
app config -name hwsw -add libraries {m}
app config -name hwsw -set compiler-optimization {Optimize more (-O2)}


#copy source files to hwsw/src
foreach src $srcs {
    file copy -force $src hwsw/src
}

file delete -force hwsw/src/helloworld.c

app build -name hwsw
