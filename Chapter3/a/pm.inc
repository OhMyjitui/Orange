;描述符的数据结构
;base : dd
;Limit: dd
;Attr: dw

%macro Descriptor 3
       dw %2 & 0FFFFh
       dw %1 & 0FFFFh
       db (%1 >> 16) & 0FFH
       dw ((%2 >> 8) & 0F00H) | (%3 & 0F0FFh)
       db (%1 >> 24) & 0FFH
%endmacro
