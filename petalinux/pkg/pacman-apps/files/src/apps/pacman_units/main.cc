#include <stdio.h>
#include <assert.h>
#include <ctime>

#include "pacman_message.hh"
#include "tx_buffer.hh"
#include "rx_buffer.hh"
#include "asic.h"

// Placeholder for user test function
int test_message(pacman_msg_t* msg) {
  if (check_msg(msg)){
    printf("INFO:  messages passes consistency check.\n");
    print_msg(msg);
  } else {
    printf("ERROR: messages FAILS consistency check.\n");
    return 0;
  }

  return 1;
}

int test_pacman_message(){
  int success = 1;
  printf("INFO:  ****** running PACMAN message unit test. *******\n");

  uint64_t ts = static_cast<uint64_t>(std::time(nullptr));
  uint32_t ts_hi = upper_32(ts);
  uint32_t ts_lo = lower_32(ts);
  pacman_msg_t msg;

  printf("INFO:  Step 1: REQ/PING\n");
  write_header_req(&msg.header, 1, ts_hi, ts_lo);
  write_word_ping(&msg.words[0]);
  success &= test_message(&msg);

  printf("INFO:  Step 2: REQ/PING\n");
  write_header_rep(&msg.header, 1, ts_hi, ts_lo);
  write_word_ping(&msg.words[0]);
  success &= test_message(&msg);

  if (success==0){
    printf("ERROR:  PACMAN message unit test FAILED at Step 1-2 (PING).\n");
    return 0;
  }
  printf("INFO:  Step 3: REQ/READ\n");
  write_header_req(&msg.header, 1, ts_hi, ts_lo);
  write_word_read(&msg.words[0], 2, 0xFF10, 0x00000000);
  success &= test_message(&msg);

  printf("INFO:  Step 4: REQ/READ\n");
  write_header_rep(&msg.header, 1, ts_hi, ts_lo);
  write_word_read(&msg.words[0], 2, 0xFF10, 0xAABBCCDD);
  success &= test_message(&msg);

  if (success==0){
    printf("ERROR:  PACMAN message unit test FAILED at Step 3-4 (PING).\n");
    return 0;
  }

  printf("INFO:  Step 5: REQ/WRITE\n");
  write_header_req(&msg.header, 1, ts_hi, ts_lo);
  write_word_write(&msg.words[0], 2, 0xFF14, 0x12345678);
  success &= test_message(&msg);

  printf("INFO:  Step 6: REQ/WRITE\n");
  write_header_rep(&msg.header, 1, ts_hi, ts_lo);
  write_word_write(&msg.words[0], 2, 0xFF14, 0x12345678);
  success &= test_message(&msg);

  if (success==0){
    printf("ERROR:  PACMAN message unit test FAILED at Step 5-6 (PING).\n");
    return 0;
  }

  printf("INFO:  Step 7: DATA/DATA\n");
  write_header_data(&msg.header, 1, ts_hi, ts_lo);
  write_word_data(&msg.words[0], 2, 4, ts_hi, ts_lo, 0x12345678, 0x90ABCDEF);
  success &= test_message(&msg);

  printf("INFO:  Step 8: DATA/SYNC\n");
  write_header_data(&msg.header, 1, ts_hi, ts_lo);
  write_word_sync(&msg.words[0], 2, 'H', 0, ts_hi, ts_lo, 0);
  success &= test_message(&msg);

  printf("INFO:  Step 9: DATA/TRIG\n");
  write_header_data(&msg.header, 1, ts_hi, ts_lo);
  write_word_trig(&msg.words[0], 2, 4, 1, ts_hi, ts_lo);
  success &= test_message(&msg);

  if (success==0){
    printf("ERROR:  PACMAN message unit test FAILED at Step 7-9 (DATA,SYNC,TRIG).\n");
    return 0;
  }

  printf("INFO:  Step 9: DATA/ERR\n");
  write_header_data(&msg.header, 1, ts_hi, ts_lo);
  write_word_err(&msg.words[0], 2, ts_hi, ts_lo, 0xEEEE);
  success &= test_message(&msg);

  printf("INFO:  Step 10: STRING message\n");
  const char* test_str = "Hello PACMAN!";
  size_t str_len = strlen(test_str);

  // Clear message and write header
  memset(&msg, 0, sizeof(msg));
  msg.header.msg_type = MSG_TYPE_STRING;
  msg.header.pacman = 1;
  msg.header.version_major = MSG_VERSION_MAJOR;
  msg.header.version_minor = MSG_VERSION_MINOR;
  msg.header.n_bytes = str_len;
  msg.header.timestamp_hi = ts_hi;
  msg.header.timestamp_lo = ts_lo;

  // Copy string bytes into the raw union buffer
  memcpy(msg.words[0].raw, test_str, str_len);

  // Test
  success &= test_message(&msg);


  printf("SUMMARY:  PACMAN message unit test SUCCESS.\n");
  return success;
}

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
    success &= (tx_buffer_in(5, tx_data[1], tx_data[0])==1);
  }
  tx_data[0] = 0x11111111;
  tx_data[1] = 0x22222222;
  tx_buffer_in(1, tx_data[1], tx_data[0]);

  for (int i=0; i<TX_BUFFER_DEPTH-1; i++){
    tx_data[0] = 0xAAAA0000+i;
    tx_data[1] = 0xBBBB0000+i;
    success &= (tx_buffer_in(10, tx_data[1], tx_data[0])==1);
  }

  tx_buffer_status();

  success &= (tx_buffer_lost()==0);
  success &= (tx_buffer_in(10, tx_data[1], tx_data[0])==0);
  success &= (tx_buffer_lost()==1);

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

  printf("DEBUG:  lost:  %d\n", tx_buffer_lost());
  // completely fill the entire buffer:
  tx_data[0] = 0;
  tx_data[1] = 0;
  for (unsigned i=0; i<TX_BUFFER_CHAN; i++){
    for (unsigned j=0; j<(TX_BUFFER_DEPTH-1); j++){
      tx_data[0] = (j<<8) + i+1;
      tx_data[1] = (j<<8) + 0x00000033;
      if (i >= 0)
	success &= (tx_buffer_in(i, tx_data[1], tx_data[0])==1);
    }
  }

  // how about this wafer thin mint?
  success &= (tx_buffer_in(20, tx_data[1], tx_data[0])==0);

  if (success==0){
    printf("ERROR:  failed filing the entire buffer.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  tx_buffer_status();

  printf("INFO:  Draining the entire buffer and checking contents.\n");

  // completely drain the entire buffer:
  for (unsigned i=0; i<TX_BUFFER_DEPTH-1; i++){
    success &= (tx_buffer_out(output)==1);

    //printf("INFO:  printing output...\n");
    //tx_buffer_print_output(output);

    success &= (output[0] == 0xFFFFFFFF);
    //success &= (output[1] == 0x00000000);
    success &= (output[1] == 0x000000FF);
    for (unsigned j=0; j<TX_BUFFER_CHAN; j++){
      unsigned chan = j;
      if (chan<0)
	continue;
      //printf("%d %d 0x%x\n", j, chan, output[4+2*chan]);
      success &= ((output[2+2*chan+0]&0xFF) == j+1);
      success &= ((output[2+2*chan+0]>>8) == i);
      success &= ((output[2+2*chan+1]&0xFF) == 0x33);
      success &= ((output[2+2*chan+1]>>8) == i);
    }
  }
  // check we are empty:
  success &= (tx_buffer_out(output)==0);

  success &= (tx_buffer_lost()==2);

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
  uint32_t rx_data[6];

  printf("INFO:  ****** running rx buffer unit test. ****** \n");
  rx_buffer_init(1);

  printf("INFO:  checking basic functionality.\n");

  rx_buffer_status();

  rx_data[0]=0xAAAAAAAA;
  rx_data[1]=0xBBBBBBBB;
  rx_data[2]=0xCCCCCCCC;
  rx_data[3]=0xDDDDDDDD;
  rx_data[4]=0xEEEEEEEE;
  rx_data[5]=0xFFFFFFFF;

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

  // check no losses:
  success &= (rx_buffer_lost()==0);

  if (success==0){
    printf("ERROR:  failed basic functionality test.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  printf("INFO:  Filling the entire buffer.\n");

  // completely fill the entire buffer:
  for (unsigned i=0; i<RX_BUFFER_DEPTH-1; i++){
    unsigned I = i%1024;
    rx_data[0] = I;
    rx_data[1] = 2*I;
    success &= (rx_buffer_in(rx_data)==1);
  }

  // check no losses:
  success &= (rx_buffer_lost()==0);

  // how about this wafer thin mint?
  success &= (rx_buffer_in(rx_data)==0);

  // check loss detected:
  success &= (rx_buffer_lost()==1);

  if (success==0){
    printf("ERROR:  filling the entire buffer failed.\n");
    return 0;
  } else {
    printf("INFO:  ...success so far.\n");
  }

  printf("INFO:  Draining the entire buffer and checking contents\n");

  // drain the entire buffer:
  for (unsigned i=0; i<RX_BUFFER_DEPTH-1; i++){
    unsigned I = i%1024;
    success &= (rx_buffer_out(rx_data)==1);
    success &= (rx_data[0] == I);
    success &= (rx_data[1] == 2*I);
    //printf("DEBUG: rx_data %3d 0x%lx %lx\n", i, rx_data[1], rx_data[0]);
    if (success==0){
      printf("ERROR:  draining the entire buffer.\n");
      return 0;
    }
  }

  //confirm empty:
  success &= (rx_buffer_out(rx_data)==0);

  // check no more loss detected:
  success &= (rx_buffer_lost()==1);


  rx_buffer_status();

  if (success==0){
    printf("ERROR:  rx buffer unit test FAILED.\n");
    return 0;
  }

  printf("SUMMARY:  rx buffer unit test SUCCESS.\n");
  return 1;
}

int test_asic_util(){
  int success = 1;
  const unsigned MAX_NUM_WORDS = 20;
  hw_u32_t payload[2*MAX_NUM_WORDS];
  unsigned NUM_WORDS;
  printf("INFO:  ****** running ASIC utility unit test. ****** \n");

  NUM_WORDS = 13;
  // set chip id to 4:
  asic_config_write(&payload[0], 1,  122, 0xB);
  // set various enables:
  asic_config_write(&payload[2], 11, 123, 0xC0);
  // i_rx 0-1
  asic_config_write(&payload[4], 11, 243, 0x77);
  // r_term1
  asic_config_write(&payload[6], 11, 248, 0x07);
  // enable POSI
  asic_config_write(&payload[8], 11, 126, 0x2);
  // enable tx_slices 0-3
  asic_config_write(&payload[10], 11, 239, 0x77);
  asic_config_write(&payload[12], 11, 240, 0x77);
  // tx_diff 0-3
  asic_config_write(&payload[14], 11, 241, 0x77);
  asic_config_write(&payload[16], 11, 242, 0x77);
  //common mode
  asic_config_write(&payload[18], 11, 254, 0x55);
  asic_config_write(&payload[20], 11, 255, 0x55);
  //piso downstream:
  asic_config_write(&payload[22], 11, 125, 0xF);
  //piso upstream:
  asic_config_write(&payload[24], 11, 124, 0x0);

  for (unsigned i=0; i< NUM_WORDS; i++){
    asic_print_packet_summary(&payload[2*i]);
  }

  for (unsigned i=0; i< NUM_WORDS; i++){
    printf("0x%08x%08x\n",payload[2*i+1],payload[2*i]);
  }

  return success;
}
int main(){
  int success = 1;
  success &= test_pacman_message();
  success &= test_tx_buffer();
  success &= test_rx_buffer();
  success &= test_asic_util();
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
