#ifndef H_IOB_ACC_CONF_H
#define H_IOB_ACC_CONF_H

#define IOB_ACC_DATA_W 21
#define IOB_ACC_INCR_W DATA_W
#define IOB_ACC_RST_VAL                                                        \
  {                                                                            \
    DATA_W { 1'b0 }                                                            \
  }
#define IOB_ACC_VERSION 0x0081

#endif // H_IOB_ACC_CONF_H
