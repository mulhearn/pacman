#ifndef pacman_cmdserver_cc
#define pacman_cmdserver_cc

#include <stdio.h>
#include <fcntl.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <zmq.h>
#include <cerrno>

#include "fw-addr-conf.hh"
#include "dma.cc"
#include "larpix.cc"

#define TX_ERR (DMA_ERR_IRQ|DMA_INTERR|DMA_SLVERR|DMA_DECERR)

#define RV_ERR_FAILED_TO_BIND 1

#define MAX_REPLY_LEN_BYTES 5
#define REPLY_OK   "OK"
#define REPLY_ERR  "ERR"
#define REPLY_PONG "PONG"

uint32_t dma_start(uint32_t* virtual_address, uint32_t tx_address){
    dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RST);
    dma_set(virtual_address, DMA_MM2S_CTRL_REG, 0);
    dma_set(virtual_address, DMA_MM2S_ADDR_REG, tx_address);
    dma_set(virtual_address, DMA_MM2S_CTRL_REG, DMA_RUN | DMA_IOC_IRQEN | DMA_ERR_IRQEN);
}

uint32_t dma_clear(uint32_t* virtual_address){
    uint32_t status = dma_get(virtual_address, DMA_MM2S_STAT_REG);
    if (status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) {
        dma_set(virtual_address, DMA_MM2S_STAT_REG, status);
    }
}

uint32_t dma_write_data(uint32_t* virtual_address, uint32_t nbytes){
    dma_set(virtual_address, DMA_MM2S_LEN_REG, nbytes);
    return dma_mm2s_sync(virtual_address);
}

uint32_t transmit_data(uint32_t* virtual_address, uint32_t tx_address, uint32_t nbytes) {
    uint32_t status;
    uint32_t attempts = 0;
    uint32_t max_attempts = 10;
    do {
        // write data that's sitting in dma buffer
        status = dma_write_data(virtual_address, nbytes);

        if (status & TX_ERR) {
            // write error - restart dma
            dma_mm2s_status(virtual_address);
            dma_start(virtual_address, tx_address);
        }

        // retry write if there was a write error
        attempts++;
    } while (attempts < max_attempts && status & TX_ERR);

    // reset
    dma_clear(virtual_address);
    return status;
}

int main(int argc, char* argv[]){
    printf("Start pacman-cmdserver\n");
    // create zmq connection
    void* ctx = zmq_ctx_new();
    void* rep_socket = zmq_socket(ctx, ZMQ_REP);
//    char req_relaxed = 1;
//    zmq_setsockopt(rep_socket, ZMQ_REQ_RELAXED, &req_relaxed, sizeof(req_relaxed));
    if (zmq_bind(rep_socket, "tcp://*:5555") != 0) {
        printf("Failed to bind socket!\n");
        return RV_ERR_FAILED_TO_BIND;
    }
    printf("ZMQ socket created\n");

    // initialize dma
    int dh = open("/dev/mem", O_RDWR|O_SYNC);
    uint32_t* dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
    uint32_t* dma_tx = (uint32_t*)mmap(NULL, DMA_TX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_TX_ADDR);
    dma_start(dma, DMA_TX_ADDR);
    printf("DMA started\n");

    // initialize zmq msg
    int req_msg_nbytes;
    int rep_msg_nbytes;
    while (1) {
        // wait for msg
        zmq_msg_t req_msg;
        zmq_msg_init(&req_msg);
        req_msg_nbytes = zmq_msg_recv(&req_msg, rep_socket, 0);
        if (req_msg_nbytes<0) {
            zmq_msg_close(&req_msg);
            continue;
        }
        printf("Message received: ");
        fwrite(zmq_msg_data(&req_msg), 1, req_msg_nbytes, stdout);
        printf("\n");

        // switch based on first byte of message
        char cmd = ((char*)zmq_msg_data(&req_msg))[0];
        char reply[MAX_REPLY_LEN_BYTES];
        switch(cmd) {
            case 'P': {
                // ping-pong
                rep_msg_nbytes = strlen(REPLY_PONG);
                memcpy(reply, REPLY_PONG, rep_msg_nbytes);
                break;
            }
            case 'D': {
                // transmit data
                memcpy(dma_tx, (char*)zmq_msg_data(&req_msg)+1, req_msg_nbytes-1);
                printf("TX: ");
                fwrite(dma_tx, 1, req_msg_nbytes-1, stdout);
                printf("\n");
                const char* result = transmit_data(dma, DMA_TX_ADDR, req_msg_nbytes-1) & TX_ERR ? REPLY_ERR : REPLY_OK;
                rep_msg_nbytes = strlen(result);
                memcpy(reply, result, rep_msg_nbytes);
                break;
            }
            default: {
                // unknown command
                rep_msg_nbytes = strlen(REPLY_ERR);
                memcpy(reply, REPLY_ERR, rep_msg_nbytes);
            }
        }
        zmq_msg_t rep_msg;
        zmq_msg_init_size(&rep_msg, rep_msg_nbytes);
        memcpy(zmq_msg_data(&rep_msg), reply, rep_msg_nbytes);
        zmq_msg_send(&rep_msg, rep_socket, 0);

        printf("Message sent: ");
        fwrite(zmq_msg_data(&rep_msg), 1, rep_msg_nbytes, stdout);
        printf("\n");

        // clear messages
        zmq_msg_close(&req_msg);
        zmq_msg_close(&rep_msg);
    }
    return 0;
}
#endif
