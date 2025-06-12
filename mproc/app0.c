#include "xil_cache.h" alternative implmentation
#include "xil_mmu.h"

#define COMMAND_ADDR 0x10000000
#define COMMAND_DATA 0x10000004

#define WAIT 0
#define GO 1

int main ( ) {

Xil_SetTlbAttributes(0x10000000, 0x14de2);  // Strongly Ordered, Shareable, Non-cacheable

xil_printf("CPU0: Hello!\n\n");

int * command_ptr = COMMAND_ADDR;
int * data_ptr = COMMAND_DATA;

//setup first CPU1 command and data
*command_ptr = WAIT; //tells CPU 1 to wait for data
*data_ptr = 0;

//send CPU1 the GO command
*command_ptr = GO;
//Xil_DCacheFlushRange( command_ptr, 32);

//wait for CPU 1 to finish; use count to timeout
int count = 0;

while (1) {
    //Xil_DCacheInvalidateRange (command_ptr, 32);    
    if ( (*command_ptr) == GO) {
        count++;
        if(count == 1000000000) {
            break;
        }      
    }
    else 
        { 
            count = 0;
            break;
        }
}

if (count != 0)
    xil_printf("CPU0: CPU1 did not update command\n\n");
else
    xil_printf("CPU0: CPU1 computed %d\n\n", *data_ptr);

xil_printf("Bye!\n\n");
while(1);

}
