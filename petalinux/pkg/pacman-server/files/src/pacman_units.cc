#include <stdio.h>
#include <assert.h>

#include "larpix.hh"
#include "message_format.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "chan_map.hh"

int test_tx_buffer(){
  int success = 1;
  uint32_t tx_data[2];
  uint32_t output[TX_BUFFER_BYTES/4];

  printf("INFO:  ****** running tx buffer unit test. *******\n");
  tx_buffer_init(1);

  printf("INFO:  checking basic functionality.\n");

  success &= (tx_buffer_out(NULL)==0);

  for (int i=0; i<3; i++){
    tx_data[0] = 0xBBBBAA00+i;
    tx_data[1] = 0xDDDDCCCC;
    success &= (tx_buffer_in(5, tx_data)==1);
  }
  tx_data[0] = 0x11111111;
  tx_data[1] = 0x22222222;
  tx_buffer_in(1, tx_data);

  for (int i=0; i<TX_BUFFER_DEPTH-1; i++){
    tx_data[0] = 0xAAAA0000+i;
    tx_data[1] = 0xBBBB0000+i;
    success &= (tx_buffer_in(10, tx_data)==1);
  }
  success &= (tx_buffer_in(10, tx_data)==0);

  tx_buffer_status();

  success &= (tx_buffer_out(output)==1);
  tx_buffer_print_output(output);

  success &= (tx_buffer_out(output)==1);
  tx_buffer_print_output(output);

  success &= (tx_buffer_out(output)==1);
  tx_buffer_print_output(output);

  success &= (tx_buffer_out(output)==1);
  tx_buffer_print_output(output);

  for (int i=0; i<TX_BUFFER_DEPTH-5; i++){
    success &= (tx_buffer_out(output)==1);
  }
  // check we are empty:
  success &= (tx_buffer_out(output)==0);

  if (success==0){
    printf("ERROR:  failed basic functionality test.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  printf("INFO:  Filling the entire buffer.\n");

  // completely fill the entire buffer:
  tx_data[0] = 0;
  tx_data[1] = 0;
  for (unsigned i=0; i<TX_BUFFER_CHAN; i++){
    for (unsigned j=0; j<TX_BUFFER_DEPTH-1; j++){
      tx_data[0] = (j<<8) + i+1;
      tx_data[1] = (j<<8) + 0x00000033;
      if (chan_map_tx(i) >= 0)
	success &= (tx_buffer_in(i, tx_data)==1);
    }
  }
  // how about this wafer thin mint?
  success &= (tx_buffer_in(20, tx_data)==0);

  if (success==0){
    printf("ERROR:  failed filing the entire buffer.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  tx_buffer_status();

  printf("INFO:  Draining the entire buffer and checking contents.\n");

  // completely drain the entire buffer:
  for (int i=0; i<TX_BUFFER_DEPTH-1; i++){
    success &= (tx_buffer_out(output)==1);

    //printf("INFO:  printing output...\n");
    //tx_buffer_print_output(output);

    success &= (output[0] == 0xFFFFFFFF);
    success &= (output[1] == 0x00000000);
    //success &= (output[1] == 0x000000FF);
    for (int j=0; j<TX_BUFFER_CHAN; j++){
      int chan = chan_map_tx(j);
      if (chan<0)
	continue;
      //printf("%d %d 0x%x\n", j, chan, output[4+2*chan]);
      success &= ((output[4+2*chan+0]&0xFF) == j+1);
      success &= ((output[4+2*chan+0]>>8) == i);
      success &= ((output[4+2*chan+1]&0xFF) == 0x33);
      success &= ((output[4+2*chan+1]>>8) == i);
    }
  }
  // check we are empty:
  success &= (tx_buffer_out(output)==0);

  if (success==0){
    printf("ERROR:  failed draining the entire buffer and checking contents.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  if (success==0){
    printf("ERROR:  tx buffer unit test FAILED.\n");
    return 0;
  }

  printf("SUMMARY:  tx buffer unit test SUCCESS.\n");
  return 1;
}

int test_rx_buffer(){
  int success = 1;
  uint32_t rx_data[4];

  printf("INFO:  ****** running rx buffer unit test. ****** \n");
  rx_buffer_init(1);

  printf("INFO:  checking basic functionality.\n");

  rx_buffer_status();

  rx_data[0]=0xAAAAAAAA;
  rx_data[1]=0xBBBBBBBB;
  rx_data[2]=0xCCCCCCCC;
  rx_data[3]=0xDDDDDDDD;

  success &= (rx_buffer_in(rx_data)==1);
  success &= (rx_buffer_in(rx_data)==1);
  success &= (rx_buffer_in(rx_data)==1);
  success &= (rx_buffer_count()==3);

  rx_buffer_status();

  success &= (rx_buffer_out(rx_data)==1);
  rx_buffer_print_output(rx_data);
  success &= (rx_buffer_count()==2);

  success &= (rx_buffer_out(rx_data)==1);
  success &= (rx_buffer_out(rx_data)==1);
  success &= (rx_buffer_out(rx_data)==0);

  rx_buffer_status();

  if (success==0){
    printf("ERROR:  failed basic functionality test.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  printf("INFO:  Filling the entire buffer.\n");

  // completely fill the entire buffer:
  for (unsigned i=0; i<RX_BUFFER_DEPTH-1; i++){
    rx_data[0] = i;
    rx_data[1] = 2*i;
    success &= (rx_buffer_in(rx_data)==1);
  }
  // how about this wafer thin mint?
  success &= (rx_buffer_in(rx_data)==0);

  if (success==0){
    printf("ERROR:  filling the entire buffer failed.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  printf("INFO:  Draining the entire buffer and checking contents\n");

  // completely fill the entire buffer:
  for (unsigned i=0; i<RX_BUFFER_DEPTH-1; i++){
    success &= (rx_buffer_out(rx_data)==1);
    success &= (rx_data[0] == i);
    success &= (rx_data[1] == 2*i);
    //printf("DEBUG: rx_data %3d 0x%lx %lx\n", i, rx_data[1], rx_data[0]);
    if (success==0)
      return 0;
  }

  //confirm empty:
  success &= (rx_buffer_out(rx_data)==0);

  rx_buffer_status();

  if (success==0){
    printf("ERROR:  rx buffer unit test FAILED.\n");
    return 0;
  }

  printf("SUMMARY:  rx buffer unit test SUCCESS.\n");
  return 1;
}

int test_chan_map(){
  int success=1;
  uint32_t rx_data[4];

  printf("INFO:  chan_map unit test.\n");

  print_chan_map();

  for (int i = 0 ; i < 8 ; i++){
    success &= (chan_map_tx(i)==i);
  }
  success &= (chan_map_tx(254)==254);

  rx_data[0]=0xAAAA00AA;
  rx_data[1]=0xBBBBBBBB;
  rx_data[2]=0xCCCCCCCC;
  rx_data[3]=0xDDDDDDDD;

  for (int i=0; i<40; i++){
    int pchan = i+1;
    int mchan = chan_map_tx(i);
    if (mchan < 0){
      printf("%d (unmapped)\n", pchan);
      continue;
    }
    // legacy firmware starts at 1 not 0:
    mchan = mchan+1;
    rx_data[0]=0xAAAA00AA + ((mchan&0xFF)<<8);
    chan_map_rx(rx_data);
    unsigned uchan = (rx_data[0]>>8)&0xFF;
    printf("%d %d %d\n", pchan, mchan, uchan);
    success &= (pchan == uchan);
  }

  if (success==0){
    printf("ERROR:  chan_map unit test has failed.\n");
    return 0;
  }
  printf("SUMMARY:  chan_map unit test SUCCESS.\n");
  return 1;
}

int main(){
  int success = 1;
  success &= test_tx_buffer();
  success &= test_rx_buffer();
  success &= test_chan_map();
  if (success) {
    printf("SUMMARY:  *************************************************\n");
    printf("SUMMARY:  Congratulations!  All unit tests were successful.\n");
    printf("SUMMARY:  *************************************************\n");
    return 0;
  } else {
    printf("ERROR:  *** Failures detected! ***\n");
    return 1;
  }
}
