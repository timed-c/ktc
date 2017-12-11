/* An example program from Concurrent C paper by Gehani and Roome. The program is taken from the below link
 http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.47.850&rep=rep1&type=pdf 
It is modified to include the specify priority constructs */


process spec fork()
{
  trans void pick_up();
  trans void put_down();
};
process spec philosopher(int id, process fork left, process fork right);


#define LIFE_LIMIT 100000
#include "dining.h"  /*contains the process specifications*/
process body philosopher(id, left, right)
{
  int times_eaten;
  for (times_eaten = 0; times_eaten != LIFE_LIMIT; times_eaten++) {
    /*think for a while; then enter dining room and sit down*/
    /*pick up forks*/
      right.pick_up();
      printf("PHIL %d: PICK UP FORK %d\n",id, id+1%5);
      left.pick_up();
      printf("PHIL %d: PICK UP FORK %d\n",id, id);
   /*eat*/
      printf("Philosopher %d: That was delicious -- Thank You\n", id);
   /*burp*/
   /*put down forks*/
      left.put_down();
      printf("PHIL %d: PUT DOWN FORK %d\n",id, id);
      right.put_down();
      printf("PHIL %d: PUT DOWN FORK %d\n",id, id+1%5);
    /*get up and leave dining room*/
  }
  printf("Philosopher %d: SEE YOU IN THE NEXT WORLD\n", id);
}
process body fork()
{
  for (;;)
    select {
      accept pick_up();
      accept put_down();
    or
       terminate; }
}
main() {
  process fork f[5];
  process philosopher p[5];
  int j;    /*loop variable*/
  /*create the forks and philosophers; the forks must be*/
  /*created before the philosophers*/
    for (j=0; j<=4; j++)
      f[j] = create fork() with priority(3);
    for (j=0; j<=4; j++)
      p[j] = create philosopher(j, f[j], f[(j+1)%5]) with priority(4);
}

