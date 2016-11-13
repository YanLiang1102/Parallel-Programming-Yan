#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <netdb.h>
#include <sys/types.h> 
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <stdbool.h>

#define BUFSIZE 1024

socklen_t clientlen1;
//struct sockaddr_in server;

void error(char *msg) {
  perror(msg);
  exit(1);
}
typedef struct {
		int portno;
    char* hostname;
    char clientname[9];
    char* neighbors[9]; //this will be the destionation of who to send.
    int routingtable[12]; //routing[0] will represent 140, [1] will be 151,[2]will be 152 and,[11] will be 161
    int neighborsport[10];
    int neighborsnum;
    char* wlanid;
    } info;

 void * worker(info* argv)
 {
  printf("this is to test if thread is working  \n");
  fflush(stdout);  /** you need to flush the stdout **/
  
  pthread_exit(NULL);
 }
 
 void * sender(info* myinfo) 
 {
          int sockfd, portno, n;
          int serverlen;
          struct sockaddr_in serveraddr;
          struct hostent *server;
          char *hostname;
          char clientname[9];
          char buf[BUFSIZE];

          hostname = (*myinfo).hostname;
          portno = (*myinfo).portno;

          int k=0;
          for(k=0;k<9;k++)
          {
            clientname[k]=(*myinfo).clientname[k];
          }

    /* socket: create the socket */
        sockfd = socket(AF_INET, SOCK_DGRAM, 0);
        if (sockfd < 0) 
            error("ERROR opening socket");

    /* gethostbyname: get the server's DNS entry */
        server = gethostbyname(hostname);
        if (server == NULL) 
        {
            fprintf(stderr,"ERROR, no such host as %s\n", hostname);
            exit(0);
        }

    /* build the server's Internet address */
         bzero((char *) &serveraddr, sizeof(serveraddr));
         serveraddr.sin_family = AF_INET;
          bcopy((char *)server->h_addr, 
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
          
         /*       hp = gethostbyname(host);
          if (!hp)
          {
            printf("%c[client]: could not obtain address of %s\n", id, host);
            return 0;
          }*/

         //memcpy((void *)&serveraddr.sin_addr, server->h_addr_list[0], server->h_length);
        
        /* get a message from the user */
        bzero(buf, BUFSIZE);
      //loop through all the file that you are ready to send.
        int fileno=0;
        int neighborsnum=(*myinfo).neighborsnum;
          for(fileno=0;fileno<1;fileno++)
          {
                   FILE* fileptr;
                   char filenamebuffer[32]; // The filename buffer.
                  snprintf(filenamebuffer, sizeof(char) * 32, "pac%i", fileno);
                  fileptr = fopen(filenamebuffer, "r");

                 if (fileptr != NULL) 
                 {
                  bool sendflag=true;
                  char line [200];
                  int lineno=0;
                  while(fgets(line,sizeof line,fileptr)!= NULL&&lineno<18)
                    {
                        if(lineno<16)
                         lineno++; //print the file contents on stdout.
                        else if(lineno==16)
                        {
                          //printf("the source address in the frame: %s \n",line);
                          memcpy(buf,line,sizeof(line));
                           int k=0;
                           sendflag=true;
                           for(k=0;k<9;k++)
                           {
                              if(buf[16+k]!=clientname[k])
                              {
                                  sendflag=false;
                                  break;
                              }
                           }
                           //only send if the resource address is the current server address
                          lineno++;
                        }
                      else if(lineno==17)
                      {
                        if(sendflag)
                       {
                           printf("the package is going to sent to destination address : %s\n",line);

                           serverlen = sizeof(struct sockaddr_in);
                           long filelen;
                          fseek(fileptr, 0, SEEK_END);          // Jump to the end of the file
                          filelen = ftell(fileptr);             // Get the current byte offset in the file
                          rewind(fileptr);                      // Jump back to the beginning of the file
                          fread(buf, filelen, 1, fileptr);
                          
                          //printf("this is the file length that is going to send: %d",filelen);


                          int j=0;
                          char destno[3];
                          for(j=0;j<9;j++)
                          {
                            buf[150+j]=line[21+j];
                             if(j>=6)
                             {
                              destno[j-6]=line[21+j];
                             }
                          }
                      //inject the current sender ip address into buf start from the 160th position,
                      //this needs to be update each time the package send.
                          for(j=0;j<9;j++)
                          {
                            buf[160+j]=clientname[j];
                          }
                      //this 170th info also need to update each time this package get sent.
                          char tmpportno[4];
                          sprintf(tmpportno,"%ld",portno);
                          for(j=0;j<4;j++)
                          {
                            buf[170+j]=tmpportno[j];
                          }
                      
                          int destnoasint=atoi(destno);
                          int nexthopasint=0;
               /*           int fi=0;
                          for( fi=0;fi<12;fi++)
                          {
                            printf("routing table record: %d \n",(*myinfo).routingtable[fi]);
                          }
*/
                          if(destnoasint==140)
                          {
                            nexthopasint=(*myinfo).routingtable[0];
                          }
                          else
                          {
                            nexthopasint=(*myinfo).routingtable[destnoasint-150];
                          }

                          int neiindex=0;
                          int loopindex=0;
                          for(neiindex=0;neiindex<neighborsnum;neiindex++)
                          {
                              char destip[3];
                              for(loopindex=0;loopindex<3;loopindex++)
                              {
                                destip[loopindex]=(*myinfo).neighbors[neiindex][6+loopindex];
                              }
                              if(atoi(destip)==nexthopasint)
                              {
                               //so the idea is search the routing table, to find the nexhop it needs to go to,
                                //then using the port and neighbor's array(they line up in order) to find the port of its neighbor.
                                break;//using the neiinex to get the port the nexthop (which is the neighbor)
                              }
                          }

                          //portno=(*myinfo).neighborsport[neiindex];
                          //portno=nexthopasint-100+5000;
                          //portno=5059;
                          printf("Is this the correct port? %d \n",nexthopasint-100+5000);
                          serveraddr.sin_port = htons((unsigned short)portno);

                          
                          n = sendto(sockfd, buf, BUFSIZE, 0, (struct sockaddr *)&serveraddr,sizeof(serveraddr));
                           
                          if (n < 0) 
                              error("ERROR in sendto 1");  
                          else{
                            printf("successful sent!!! \n");
                          } 
                         // printf("this is the message send! %s size :%d \n",buf,sizeof(buf));

                     }
                     
                    fflush(stdout);  /** you need to flush the stdout **/
                    bzero(buf, BUFSIZE);
                    fclose(fileptr);
                    lineno++;
                    sendflag=true;
               }
       }
    }
  }
        pthread_exit(NULL);
}



void* receiver(info* myinfo) {
  int sockfd; /* socket */
  int portno; /* port to listen on */

  //socklen_t clientlen; /* byte size of client's address */
  struct sockaddr_in serveraddr; /* server's addr */
  struct sockaddr_in clientaddr; /* client addr */
  struct hostent *hostp; /* client host info */
  char buf[BUFSIZE]; /* message buf */
 /* char *hostaddrp;*/ /* dotted decimal host addr string */
  int optval; /* flag value for setsockopt */
  int n; /* message byte size */
  char clientname[9]; //here it will be the server name,clinet is just still the name of the sender.

  //portno = (*myinfo).portno;

  int k=0;
  char clientno[3];
  for(k=0;k<9;k++)
  {
    clientname[k]=(*myinfo).clientname[k];
    if(k>=6)
    {
      clientno[k-6]=clientname[k];
    }
  }
  portno=atoi(clientno)-100+5000;

  printf("server start at fakeIp: %s \n",clientname);
  sockfd = socket(AF_INET, SOCK_DGRAM, 0);
  if (sockfd < 0) 
    error("ERROR opening socket");

  /* setsockopt: Handy debugging trick that lets 
   * us rerun the server immediately after we kill it; 
   * otherwise we have to wait about 20 secs. 
   * Eliminates "ERROR on binding: Address already in use" error. 
   */
  optval = 1;
  setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, 
         (const void *)&optval , sizeof(int));

  /*
   * build the server's Internet address
   */
  bzero((char *) &serveraddr, sizeof(serveraddr));
  serveraddr.sin_family = AF_INET;
  serveraddr.sin_addr.s_addr = htonl(INADDR_ANY);
  serveraddr.sin_port = htons((unsigned short)portno);
  printf("port: %d  bind to server and listening.\n",portno);

  /* 
   * bind: associate the parent socket with a port 
   */
  if (bind(sockfd, (struct sockaddr *) &serveraddr, 
       sizeof(serveraddr)) < 0) 
    error("ERROR on binding");

  /* 
   * main loop: wait for a datagram, then echo it
   */
  clientlen1 = sizeof(struct sockaddr_in);
  while (1) {

    /*
     * recvfrom: receive a UDP datagram from a client
     */
    bzero(buf, BUFSIZE);
    printf("keep waiting ....\n");
    /*n = recvfrom(sockfd, buf, BUFSIZE, 0,
         (struct sockaddr *) &clientaddr,&clientlen1);*/
    n = recvfrom(sockfd, buf, BUFSIZE, 0,
        (struct sockaddr *) &clientaddr, &clientlen1);
    printf("this is what I received :\n %s \n",buf);
    if (n < 0)
    {
      error("ERROR in recvfrom 1");
      
    }
    else
    {
      printf("which means you successfully received \n \n");
      if(buf[0]=='h')
      {
        printf("replied from the destination: %s \n",buf); 
      }
    }
    /* 
     * gethostbyaddr: determine who sent the datagram
     */
/*    hostp = gethostbyaddr((const char *)&clientaddr.sin_addr.s_addr, 
              sizeof(clientaddr.sin_addr.s_addr), AF_INET);
    if (hostp == NULL)
      error("ERROR on gethostbyaddr");
    hostaddrp = inet_ntoa(clientaddr.sin_addr);
    if (hostaddrp == NULL)
      error("ERROR on inet_ntoa\n");*/


      if(buf[0]!='h')
     {
                printf("have you ever get here 0?");
                char destionationchar[3];
                int charindex=0;
                for(charindex=0;charindex<3;charindex++)
                {
                  destionationchar[charindex]=buf[156+charindex];
                }
                int destinationno=atoi(destionationchar);

                if(buf[157]==clientname[7]&&buf[158]==clientname[8])
                {
                 
                  //which means the destion address from the frame match the current server address,
                  //then the server will print what it receives, other wise just print receive message
                  //but the destionation is not me.
                   printf("server received message and destination is me,so I will print the frame: \n %s\n",buf);
                   const char *tmp = "hey sender,my wlan is: ";
                   char replywlan[100];
                   strcpy(replywlan, tmp);
                   strcat(replywlan,(*myinfo).wlanid);
                   int replyportno=0;
                   char charport[4];
                   int tmpindex=0;
                   for(tmpindex=0;tmpindex<4;tmpindex++)
                   {
                     charport[tmpindex]=buf[170+tmpindex];
                   }
                   printf("send response to the server that sends me the package through prot: %s \n",charport);
                   replyportno=atoi(charport);

                   clientaddr.sin_port = htons(replyportno);
                   n = sendto(sockfd, replywlan, strlen(replywlan), 0, (struct sockaddr *)&clientaddr, sizeof(clientaddr));
                        if (n < 0) 
                          error("ERROR in sendto 1");
                }
                //destination is not this server, send to the next hop based on the map.
                else
                {
                   
                     int desnexhopno=0;
                     if(destinationno==140)
                     {
                        desnexhopno=(*myinfo).routingtable[0];
                     }
                     else
                     {
                        desnexhopno=(*myinfo).routingtable[destinationno-150];
                     }

                     int neighindex=0;
                     for(neighindex=0;neighindex<(*myinfo).neighborsnum;neighindex++)
                     {
                        char tmpneigh[3];
                        int tmpindex=0;
                        for(tmpindex=0;tmpindex<3;tmpindex++)
                        {
                          tmpneigh[tmpindex]=(*myinfo).neighbors[neighindex][6+tmpindex];
                        }
                        if(atoi(tmpneigh)==desnexhopno)
                        {
                          break;
                        }
                     }

                                clientaddr.sin_port = htons(atoi((*myinfo).neighborsport[neighindex]));
                                //printf("show me which is the port you send to : %d \n",clientportno);
                                int tmpindex=0;
                                char tmpportno1[4];
                                sprintf(tmpportno1,"%ld",(*myinfo).portno);
                                for(tmpindex=0;tmpindex<4;tmpindex++)
                                {  
                                  //printf("this is the sender port: %d \n", (*myinfo).portno);
                                  buf[170+tmpindex]=tmpportno1[tmpindex];
                                }

                             /*   for(tmpindex=0;tmpindex<9;tmpindex++)
                                {
                                  buf[160+tmpindex]=clientname[tmpindex];
                                }*/
                            
                              n = sendto(sockfd, buf, BUFSIZE, 0, (struct sockaddr *)&clientaddr, sizeof(clientaddr));

                              if (n < 0) 
                                error("ERROR in sendto 1");
                }
        }

   
  }
   fflush(stdout);  /** you need to flush the stdout **/
   pthread_exit(NULL);
}

int main (int argc, char** argv)
{
    if (argc != 2) {
      printf("please enter the name of the server config file \n");
      exit(1);
       }

   FILE *file = fopen ( argv[1], "r" );
     info i1,i2;
     int noofneighbors=0;
  
   if (file != NULL) {
    char line [200];

    int lineno=0;
    int neighborsrank=0;
    int currentip=0;
    while(fgets(line,sizeof line,file)!= NULL) 
    {
     
        if(lineno==0)
        { 
           //i1.hostname=line;
           int tmpindex=0;
           char currip[3];
           for(tmpindex=0;tmpindex<9;tmpindex++)
           {

            i1.clientname[tmpindex]=line[tmpindex];
            i2.clientname[tmpindex]=line[tmpindex];
            if(tmpindex>=6)
            {
              currip[tmpindex-6]=line[tmpindex];
            }
           }
           currentip=atoi(currip);
        }
        else if(lineno==1)
        {
          //line is gone and wlanid is reference will be lost if you need this, you need to make this a hard copy.
           int tmpindex=0;
           i1.wlanid=(char*) malloc(17);
           for(tmpindex=0;tmpindex<17;tmpindex++)
           {
            i1.wlanid[tmpindex]=line[tmpindex];
           }   
        }
        else if(lineno==2)
        {
           i1.portno=atoi(line);
           i2.portno=atoi(line);
        }
        else if(lineno==3)
        {
            noofneighbors=atoi(line);
            i2.neighborsnum=noofneighbors;//this is how many neighbors this node have 
            i1.neighborsnum=noofneighbors;
            //will use it when you try to send to multiple destionation.
            //malloc the address for each ip this has to be here, otherwise you have a core segment error
            int i=0;
            for(i=0;i<i2.neighborsnum;i++)
            {
              i2.neighbors[i]=(char*) malloc(9);
            }

             for(i=0;i<i1.neighborsnum;i++)
            {
              i1.neighbors[i]=(char*) malloc(9);
            }
        }
        else if(lineno>3&&lineno<=3+noofneighbors)
        {
                int tmpindex=0;
                char tmpip[9];
            /*      char str[] = "Hello World";
             char *result = (char *)malloc(strlen(str)+1);
             strcpy(result,str);*/

                for(tmpindex=0;tmpindex<9;tmpindex++)
                {
                   i2.neighbors[neighborsrank][tmpindex]=line[tmpindex];
                   i1.neighbors[neighborsrank][tmpindex]=line[tmpindex];
                }
                char tmpport[4];
                for(tmpindex=0;tmpindex<4;tmpindex++)
                {
                  tmpport[tmpindex]=line[20+tmpindex];
                  //printf("i think it will be still good here!\n");
                }
                //update the destination port here.
                i2.neighborsport[neighborsrank]=atoi(tmpport);
                i1.neighborsport[neighborsrank]=atoi(tmpport);
                //printf("%d \n",i2.neighborsport[neighborsrank]);
                //negeibors rank will be he rank for the destination.
                neighborsrank++;
          //printf("tmp port is : %d \n",atoi(tmpport));
         
        }
        else if(lineno>3+noofneighbors&&lineno<6+noofneighbors)
        {
          lineno++;
          continue;
        }

          else if(lineno>=6+noofneighbors) 
        {
               char ipindex[3];
               char nexthop[3];
               int i=0;
               for(i=0;i<3;i++)
                  {
                    ipindex[i]=line[6+i];
                    nexthop[i]=line[16+i];
                  }
               int ipindexno=atoi(ipindex);
               int nexthopno=atoi(nexthop);
               //printf("next hop no %d \n",nexthopno);
               if(currentip==140)
               {
                //-1 one means you are at the current spot.
                  i1.routingtable[0]=-1;
                  i2.routingtable[0]=-1;
               }
               else
               {
                 i1.routingtable[currentip-150]=-1;
                 i2.routingtable[currentip-150]=-1;
               }
               if(ipindexno==140)
               {
                 //printf("have you ever reach here????? \n");
                 i1.routingtable[0]=nexthopno;
                 i2.routingtable[0]=nexthopno;
               }
               else
               {
                 i1.routingtable[ipindexno-150]=nexthopno;
                 i2.routingtable[ipindexno-150]=nexthopno;
               }
             
        }
      lineno++; //print the file contents on stdout.
      }

    
    fclose(file);
  }
  else {
    perror(argv[1]); //print the error message on stderr.
  }

  
  pthread_t threads[2];   /* the three thread object's indentifiers */
  void *exit_value;
  int status;

  i2.hostname="localhost";
  i1.hostname="localhost";
  //i1 is for server which is the receiver.
  status = pthread_create (&threads[0], NULL, receiver,&i1);
  //i2 is for client which is the sender.
  printf("the package will be send 15 seconds later since we need to wait to start all the server \n");
  //sleep 1 min
  sleep(15);
  
  status = pthread_create (&threads[1], NULL, sender,&i2);

  status = pthread_join (threads[0], &exit_value);

  status = pthread_join (threads[1], &exit_value);

  return 0;
} 

