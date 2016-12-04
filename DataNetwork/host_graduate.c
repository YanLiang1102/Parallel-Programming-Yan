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
#include <time.h>

#define BUFSIZE 1024
#define BUFSIZE1 20  //the first value in buffer will be the sender's globalmonitor.


static pthread_mutex_t mtx;
static pthread_cond_t cond;
//77 means infinity, 0 means distance itself and the first 2 represent the globalmonitor, 
//and each distance is represent by two integer.
static int distancevector[12];
//need another vector to store the route info,distancevector is used for compare.
static int routeinfo[12];
static int globalmonitor=0;
static int localcount=0; //use this to count that it received all the neighnors message for this step, then update
//this to 0 and wait for the next step message from its neighbor.
unsigned int
randr(unsigned int min, unsigned int max);
void error(char *msg) {
  perror(msg);
  exit(1);
}
typedef struct {
    int portno;
    char filename;
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

 void * constructtable(info* myinfo)
 {
     //do something ,and when the routingtable does not change signal the condition variable
     //set everything to infinity before the constructing table process
 	  int sockfd, portno, n;
      struct sockaddr_in serveraddr;
      char buf[BUFSIZE1]; //buf[0] wil be the global monitor and buf[13] will be the current ipaddress
      //but we will represent as follows, if it is 140, we set buf[13]=0, if it is 151, we set buf[13]=1....if it is 161,buf[13]=11.
      char *hostname;
      struct hostent *server;
      
      hostname=(*myinfo).hostname;
    //set the initial route info to be 13 which means no node connection
      int t=0;
      for(t=0;t<12;t++)
      {
      	routeinfo[t]=13;
      }
    int k=0;
 	for(k=0;k<12;k++)
 	{
 		distancevector[k]=77; //everything will be infinity at the begining.
 	}
 	//then find its neighbor and set the distance to 1.
 	 int neighindex=0;
     for(neighindex=0;neighindex<(*myinfo).neighborsnum;neighindex++)
     {
        char tmpneigh[3];
        int tmpindex=0;
        for(tmpindex=0;tmpindex<3;tmpindex++)
        {
          tmpneigh[tmpindex]=(*myinfo).neighbors[neighindex][6+tmpindex];
        }
        if(atoi(tmpneigh)==140)
        {
          distancevector[0]=1;
          routeinfo[0]=0;
        }
        else
        {
          distancevector[atoi(tmpneigh)-150]=1;
          routeinfo[atoi(tmpneigh)-150]=atoi(tmpneigh)-150;
        }
     }
     //set the distance to itself to be -100.
     char myself[3];
     for(k=0;k<3;k++)
     {
     	myself[k]=(*myinfo).clientname[6+k];
     }
     if(atoi(myself)==140)
     {
     	//77 means infinity
     	distancevector[0]=0;
     	buf[13]=0+'0';
     }
     else
     {
     	//0 means itself
     	distancevector[atoi(myself)-150]=0;
     	buf[13]=atoi(myself)-150+'0';
     }

     //print the vector out :
 /*    for(k=0;k<12;k++)
     {
     	printf("%d:%d \n",k,distancevector[k]);
     }*/
     //send the current distance to your neighbor.

    buf[0]=globalmonitor+'0';
    for(k=1;k<=12;k++)
    {
     buf[k]=distancevector[k-1]+'0';
    }
    buf[14]='o';

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

         bzero((char *) &serveraddr, sizeof(serveraddr));
         serveraddr.sin_family = AF_INET;
          bcopy((char *)server->h_addr, 
          (char *)&serveraddr.sin_addr.s_addr, server->h_length);
      
         int ipno=atoi(myself);
         printf("ip no %d \n",ipno);
         if(ipno!=140)
         {
         	sleep((ipno-150)*2);
         }
         // sleep(randr(1,30));
          //printf("my sleep time is %f \n",s);
          for(k=0;k<(*myinfo).neighborsnum;k++)
          {
              int sendport=(*myinfo).neighborsport[k];
          	  serveraddr.sin_port = htons(sendport);
              sleep(k);
              n = sendto(sockfd, buf, BUFSIZE1, 0, (struct sockaddr *)&serveraddr, sizeof(serveraddr));
              if (n < 0) 
              error("ERROR in send routingtable info!");
              else
              {
              	printf("successfully sent %d! to port %d \n",buf[0]-'0',sendport);
              }
             fflush(stdout);  /** you need to flush the stdout **/
          
          }  
         bzero(buf, BUFSIZE1); 
         pthread_exit(NULL);

 	/*pthread_cond_signal(&cond);
 	pthread_mutex_unlock(&mtx);*/
 }

 void * sender(info* myinfo) 
 {
          int sockfd, portno, n;
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
    

        /* get a message from the user */
        bzero(buf, BUFSIZE);
      //loop through all the file that you are ready to send.
        int fileno=0;
        int neighborsnum=(*myinfo).neighborsnum;
          for(fileno=0;fileno<9;fileno++)
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
                           //serverlen = sizeof(serveraddr);
                           long filelen;
                          fseek(fileptr, 0, SEEK_END);          // Jump to the end of the file
                          filelen = ftell(fileptr);             // Get the current byte offset in the file
                          rewind(fileptr);                      // Jump back to the beginning of the file
                          fread(buf, filelen, 1, fileptr);
                          //start from 150 add in the destinantion
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
                          sprintf(tmpportno,"%d",portno);
                          for(j=0;j<4;j++)
                          {
                            buf[170+j]=tmpportno[j];
                          }
                      
                          int destnoasint=atoi(destno);
                          int nexthopasint=0;
                          if(destnoasint==140)
                          {
                            if(routeinfo[0]==0)
                             nexthopasint=140;//(*myinfo).routingtable[0];
                            else
                              nexthopasint=150+routeinfo[0];

                          }
                          else
                          {
                            //nexthopasint=(*myinfo).routingtable[destnoasint-150];
                            int tempitem=routeinfo[destnoasint-150];
                            if(tempitem==0)
                              nexthopasint=140;
                            else
                              nexthopasint=tempitem+150;
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

                          portno=(*myinfo).neighborsport[neiindex];

                          serveraddr.sin_port = htons(portno);

                      
                          n = sendto(sockfd, buf, BUFSIZE, 0, (struct sockaddr *)&serveraddr, sizeof(serveraddr));
                          if (n < 0) 
                              error("ERROR in sendto 1");  
                          else
                          {
                          	printf("package send through portno: %d to final %s \n",portno,line);
                          }          
                     }
                     
                    //printf("Echo from server: %d", buf);
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
  socklen_t clientlen; /* byte size of client's address */
  struct sockaddr_in serveraddr; /* server's addr */
  struct sockaddr_in clientaddr; /* client addr */
  struct hostent *hostp; /* client host info */
  char buf[BUFSIZE]; /* message buf */
  char *hostaddrp; /* dotted decimal host addr string */
  int optval; /* flag value for setsockopt */
  int n; /* message byte size */
  char clientname[9]; //here it will be the server name,clinet is just still the name of the sender.

  portno = (*myinfo).portno;

  int k=0;
 
  for(k=0;k<9;k++)
  {
    clientname[k]=(*myinfo).clientname[k];
  }



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

  /* 
   * bind: associate the parent socket with a port 
   */
  if (bind(sockfd, (struct sockaddr *) &serveraddr, 
       sizeof(serveraddr)) < 0) 
    printf("ERROR on binding \n");
  else
  {
  	printf("succesful binding port at : %d!\n",portno);
  }

  /* 
   * main loop: wait for a datagram, then echo it
   */
  clientlen = sizeof(struct sockaddr_in);
  while (1) {

    /*
     * recvfrom: receive a UDP datagram from a client
     */  
    //printf("are you getting here? \n");
    bzero(buf, BUFSIZE);
    n = recvfrom(sockfd, buf, BUFSIZE, 0,
         (struct sockaddr *) &clientaddr, &clientlen);
    if (n < 0)
      error("ERROR in recvfrom 1");
    else
    {
       if(buf[0]=='h')
        {
        printf("============================================\n");
        printf("response from destination: %s \n",buf);
        printf("============================================\n");
        }
    	//printf("I did received something so the port works! \n");
    }

    hostp = gethostbyaddr((const char *)&clientaddr.sin_addr.s_addr, 
              sizeof(clientaddr.sin_addr.s_addr), AF_INET);
    if (hostp == NULL)
      error("ERROR on gethostbyaddr");
    hostaddrp = inet_ntoa(clientaddr.sin_addr);
    if (hostaddrp == NULL)
      error("ERROR on inet_ntoa\n");

      if(buf[0]!='h')
     {
                //printf("have you ever reached here agian? \n");
                char destionationchar[3];
                int charindex=0;
                for(charindex=0;charindex<3;charindex++)
                {
                  destionationchar[charindex]=buf[156+charindex];
                }
                int destinationno=atoi(destionationchar);
                printf("here is the destination sent to me: %d \n",destinationno);

            /*    printf("desnoasint is : %d \n",desnoasint);
                printf("servernoasint is :%d \n",servernoasint);*/

                if(buf[157]==clientname[7]&&buf[158]==clientname[8])
                {
                  printf("are you here man?? \n");
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
                     //printf("are you getting here? 0 \n");
                    
	                  if(destinationno==140)
	                  {
	                    if(routeinfo[0]==0)
	                     desnexhopno=140;//(*myinfo).routingtable[0];
	                    else
	                      desnexhopno=150+routeinfo[0];

	                  }
	                  else
	                  {
	                    //nexthopasint=(*myinfo).routingtable[destnoasint-150];
	                    int tempitem=routeinfo[destinationno-150];
	                    if(tempitem==0)
	                      desnexhopno=140;
	                    else
	                     desnexhopno=tempitem+150;
	                  }
                      //printf("are you getting here? 1 \n");
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
                     // printf("are you getting here? 2 \n");
                    clientaddr.sin_port = htons((*myinfo).neighborsport[neighindex]);
                    // printf("are you getting here? 3 \n");
                    int tmpindex=0;
                    char tmpportno1[4];
                    sprintf(tmpportno1,"%d",(*myinfo).portno);
                    for(tmpindex=0;tmpindex<4;tmpindex++)
                    {  
                      //printf("this is the sender port: %d \n", (*myinfo).portno);
                      buf[170+tmpindex]=tmpportno1[tmpindex];
                    }
                      // printf("are you getting here? 5 \n");
                    for(tmpindex=0;tmpindex<9;tmpindex++)
                    {
                      buf[160+tmpindex]=clientname[tmpindex];
                    }
                      // printf("are you getting here? 6\n");
                    n = sendto(sockfd, buf, strlen(buf), 0, (struct sockaddr *)&clientaddr, clientlen);

                   if (n < 0) 
                      error("ERROR in sendto 1");
                }
        }

   
  }
   fflush(stdout);  /** you need to flush the stdout **/
   pthread_exit(NULL);
}

void* receivertable(info* myinfo) {
  int sockfd; /* socket */
  int portno; /* port to listen on */
  socklen_t clientlen; /* byte size of client's address */
  struct sockaddr_in serveraddr; /* server's addr */
  struct sockaddr_in clientaddr; /* client addr */
  struct hostent *hostp; /* client host info */
  char buf[BUFSIZE]; /* message buf */
  char *hostaddrp; /* dotted decimal host addr string */
  int optval; /* flag value for setsockopt */
  int n; /* message byte size */
  char clientname[9]; //here it will be the server name,clinet is just still the name of the sender.

  portno = (*myinfo).portno;
  bool changed=false;

  int k=0;
 
  for(k=0;k<9;k++)
  {
    clientname[k]=(*myinfo).clientname[k];
  }



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

  /* 
   * bind: associate the parent socket with a port 
   */
  if (bind(sockfd, (struct sockaddr *) &serveraddr, 
       sizeof(serveraddr)) < 0) 
    error("ERROR on binding");

  /* 
   * main loop: wait for a datagram, then echo it
   */
  clientlen = sizeof(struct sockaddr_in);
    char myself[3];
     for(k=0;k<3;k++)
     {
     	myself[k]=(*myinfo).clientname[6+k];
     }
  while (1) {

    /*
     * recvfrom: receive a UDP datagram from a client
     */
    bzero(buf, BUFSIZE1);
    n = recvfrom(sockfd, buf, BUFSIZE1, 0,
         (struct sockaddr *) &clientaddr, &clientlen);
    if (n < 0)
      error("ERROR in recvfrom 1");
    else
    {
       if(buf[14]=='o')
       {
        printf("============================================\n");
 
      /*  for(k=0;k<14;k++)
        {
        	printf("%d ",buf[k]-'0');
        }*/
        //printf("I received! %d\n",buf[13]-'0');
        printf("I received from stage %d! \n",buf[0]-'0');
        printf("============================================\n");
       }
    }
    //if this is the update version, then you need to update the distance vector based on this, and you 
    //need to update its neighbor's amount of time.
    
    if(true)//buf[0]-'0'==globalmonitor)
    {
       for(k=0;k<12;k++)
       {
       	 if(buf[k+1]-'0'!=77)
       	 {
       	 	if(1+buf[k+1]-'0'<distancevector[k])
       	 	{

             distancevector[k]=1+(buf[k+1]-'0');
             routeinfo[k]=buf[13]-'0';
             //set the changed to be true, otherwise if no changing we don't need to send the message to the neighbor any more.
             changed=true;
             //printf("hey test %d \n",routeinfo[k]);
       	 	}
       	 }
       }
       localcount=localcount+1;
       if(localcount==(*myinfo).neighborsnum)
       {
       	localcount=0;
       	printf("my route info after %d step: \n",globalmonitor);
       	for(k=0;k<12;k++)
       	{
       		printf("%d,",routeinfo[k]);
       	}
       	printf("\n");
       	globalmonitor=globalmonitor+1;
       	if(globalmonitor==10)
       	{
       		break;
       	}
       	//changed
       	if(true)
       	{
	       	 buf[0]=globalmonitor+'0';
	       	 for(k=0;k<12;k++)
	       	 {
	       		buf[k+1]=distancevector[k]+'0';
	       	 }
	       	  if(atoi(myself)==140)
		     {
		     	//77 means infinity
		     	distancevector[0]=0;
		     	buf[13]=0+'0';
		     }
		     else
		     {
		     	distancevector[atoi(myself)-150]=0;
		     	buf[13]=atoi(myself)-150+'0';
	     	 }
	     	 buf[14]='o';
		//change this 5 to other number might break the code, since the send and receive in the same 
		//thread the race condition.
	     	 sleep(5);
	     	 for(k=0;k<(*myinfo).neighborsnum;k++)
	          {
                  int sendport=(*myinfo).neighborsport[k];
	          	  serveraddr.sin_port = htons(sendport);
	              //sleep(k);
	              n = sendto(sockfd, buf, BUFSIZE1, 0, (struct sockaddr *)&serveraddr, sizeof(serveraddr));
	              if (n < 0) 
	              error("ERROR in send routingtable info!");
	              else
	              {
	              	printf("successfully sent %d to port %d! \n",buf[0]-'0',sendport);
	              }
	             fflush(stdout);  
	          }  
	          //changed=false;
	          /* pthread_t threads[1]; 
	          pthread_create(&threads[0],NULL,constructtable2,myinfo,buf);*/
       	}

       }
    }
    fflush(stdout);  /** you need to flush the stdout **/
    bzero(buf, BUFSIZE1);


}
//kill this thread no need to wait any more.

  sleep(30);
  
  serveraddr.sin_port = htons((unsigned short)portno*10);
  close(sockfd);
  pthread_exit(NULL);
  //start another receiver thread
 /* pthread_t threads[2]; 
  int status=0;
  status=pthread_create(&threads[0],NULL,receiver,myinfo);
  //wait for 30 seconds before sending
  sleep(30);
  status=pthread_create(&threads[1],NULL,sender,myinfo);
 // status=pthread_create(&threads[1],NULL,sender,myinfo)
  void* exit_value;
  pthread_join (threads[0], &exit_value);
  pthread_join(threads[0],&exit_value);*/

}

int main (int argc, char** argv)
{
	//int ipno=0;
    if (argc != 2) {
      printf("please enter the name of the server config file \n");
      exit(1);
       }

   FILE *file = fopen ( argv[1], "r" );
   //printf("this is my file %c \n",argv[1][0]);
     info i1,i2;
     int noofneighbors=0;
   i1.filename=argv[1][0];
   i2.filename=argv[1][0];
   if (file != NULL) {
    char line [200];

    int lineno=0;
    int neighborsrank=0;
    while(fgets(line,sizeof line,file)!= NULL) 
    {
     
        if(lineno==0)
        { 
           //i1.hostname=line;
           int tmpindex=0;
           for(tmpindex=0;tmpindex<9;tmpindex++)
           {
            i1.clientname[tmpindex]=line[tmpindex];
            i2.clientname[tmpindex]=line[tmpindex];
            //printf("line: %c \n",line[tmpindex]);
           }
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
               //ipno=ipindexno;
               //printf("next hop no %d \n",nexthopno);
               if(ipindexno==140)
               {
                 i1.routingtable[0]=nexthopno;
                 i2.routingtable[0]=nexthopno;
               }
               else
               {
                 i1.routingtable[ipindexno-150]=nexthopno;
                 i2.routingtable[ipindexno-150]=nexthopno;
               }
               //i1.ipno=ipno;
               //i2.ipno=ipno;  
        }
      lineno++; //print the file contents on stdout.
      }

    
    fclose(file);
  }
  else {
    perror(argv[1]); //print the error message on stderr.
  }

  
  pthread_t threads[4];   /* the three thread object's indentifiers */
  void *exit_value;
  int status;

  i2.hostname="localhost";
  i1.hostname="localhost";
  /*pthread_mutex_init(&mtx,NULL);
  pthread_cond_init(&cond,NULL);*/
  
  //the first thread will handle the routing table construction
  status=pthread_create(&threads[1],NULL,receivertable,&i1);
  sleep(30);
  status=pthread_create(&threads[0],NULL,constructtable,&i1);
  //need to wait on this thread finish then we can start sneding the real message,
  //this is achived by waiting on a condition variable.
  //make the construct table run and wait on the conditional variable, which indicate the routing 
  //table not change any more
  //pthread_mutex_lock();
  //i1 is for server which is the receiver.
  //status = pthread_create (&threads[1], NULL, receiver,&i1);
/*  
  pthread_mutex_lock(&mtx);
  pthread_cond_wait(&cond,&mtx);*/
  
  //i2 is for client which is the sender.
  //printf("the package will be send 15 seconds later since we need to wait to start all the server \n");
  //1 min
  //(15);
  
  //status = pthread_create (&threads[2], NULL, sender,&i2);

  status = pthread_join (threads[0], &exit_value);

  status = pthread_join (threads[1], &exit_value);

  printf("routing table constructed!!! now we start sending real packages! \n");
  sleep(30);
  status=pthread_create(&threads[2],NULL,receiver,&i1);
  //wait for 30 seconds before sending
  sleep(45);
  status=pthread_create(&threads[3],NULL,sender,&i2);
 // status=pthread_create(&threads[1],NULL,sender,myinfo)

  pthread_join (threads[2], &exit_value);
  pthread_join(threads[3],&exit_value);

  return 0;
} 
unsigned int
randr(unsigned int min, unsigned int max)
{
       double scaled = (double)rand()/RAND_MAX;

       return (max - min +1)*scaled + min;
}

