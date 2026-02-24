#build the hwsw platform application using the provided xsa and source files

set appname [lindex $argv 0]
set xsa [lindex $argv 1]
set srcs [lrange $argv 2 end]

setws .

platform create -name platform -hw $xsa -out .
domain create -name standalone_domain -os standalone -proc ps7_cortexa9_0
platform generate
platform active platform

app create -name $appname -domain standalone_domain
app config -name $appname -add libraries {m}
app config -name $appname -set compiler-optimization {Optimize more (-O2)}


#copy source files to $appname/src
foreach src $srcs {
    file copy -force $src $appname/src
}

file delete -force $appname/src/helloworld.c

app build -name $appname
