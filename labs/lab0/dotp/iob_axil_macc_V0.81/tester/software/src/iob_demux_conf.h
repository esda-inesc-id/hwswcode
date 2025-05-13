#ifndef H_IOB_DEMUX_CONF_H
#define H_IOB_DEMUX_CONF_H

#define IOB_DEMUX_DATA_W 21
#define IOB_DEMUX_N 21
#define IOB_DEMUX_SEL_W ($clog2(N) == 0 ? 1 : $clog2(N))
#define IOB_DEMUX_VERSION 0x0081

#endif // H_IOB_DEMUX_CONF_H
