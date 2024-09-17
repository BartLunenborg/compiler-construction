// See the previous submission for a 'normal' solution.
#import<stdio.h>
y;a(x){while((y=getchar())==' ');return y==x?1:(ungetc(y,stdin),0);}
S();B(){return a('+')?S():a('*')?B():a('\n')||a(')')||S();}
S(){return(a('a')||a('(')&&S())&&B();}
main(){puts(S()&&getchar()<0?"SUCCESS":"FAILURE");}
