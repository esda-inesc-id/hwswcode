
#include "xil_cache.h"
#include "xil_mmu.h"


#define WAIT 0
#define GO 1

#define COMMAND_ADDR 0x10000000
#define COMMAND_DATA 0x10000004

int main() {
    Xil_SetTlbAttributes(0x10000000, 0x14de2);  // Strongly Ordered, Shareable, Non-cacheable

    int *command_ptr = COMMAND_ADDR;
    int *data_ptr = COMMAND_DATA;

    //xil_printf("CPU1: I'm alive\n\n");


    while (1) {
        //Xil_DCacheInvalidateRange (command_ptr, 32);    
        if ((*command_ptr) != WAIT) {

            //update data and command 
            int tmp = *data_ptr;
            tmp += 1;
            *data_ptr = tmp;

            *command_ptr = WAIT;
            //Xil_DCacheFlushRange(command_ptr, 32);
            break;
        }
    }

    //xil_printf("CPU1: finished\n\n");
    while(1);
}