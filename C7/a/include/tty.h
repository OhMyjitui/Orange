
#define TTY_IN_BYTES 256

struct s_console ;

typedef struct s_tty{
    u32 in_buf[TTY_IN_BYTES] ; //TTY输入缓冲区
    u32* p_inbuf_head;     //下一个空闲位置
    u32* p_inbuf_tail;    //指向键盘中应处理的键值
    int inbuf_count ;

    struct s_console* p_console ;  // 指向console
}TTY ;
