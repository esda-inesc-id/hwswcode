#build the hwsw platform and application using the provided xsa and source files
set xsa [lindex $argv 0]
set srcs [lrange $argv 1 end]

setws .

platform create -name platform -hw $xsa -out .
domain create -name standalone_domain -os standalone -proc ps7_cortexa9_0
platform generate
platform active platform

app create -name app -platform platform -domain standalone_domain
app config -name app -add libraries {m}
app config -name app -set compiler-optimization {Optimize more (-O2)}


#copy source files to $appname/src
foreach src $srcs {
    file copy -force $src app/src
}

file delete -force app/src/helloworld.c

app build -name app
