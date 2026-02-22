#ifndef H_IOB_MUX_CONF_H
#define H_IOB_MUX_CONF_H

#define IOB_MUX_DATA_W 21
#define IOB_MUX_N 21
#define IOB_MUX_SEL_W ($clog2(N) == 0 ? 1 : $clog2(N))
#define IOB_MUX_VERSION 0x0081

#endif // H_IOB_MUX_CONF_H
