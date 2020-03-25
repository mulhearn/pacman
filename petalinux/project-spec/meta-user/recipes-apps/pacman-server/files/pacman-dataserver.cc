#ifndef pacman_dataserver_cc
#define pacman_dataserver_cc

#include <algorithm>
#include <fcntl.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <string.h>
#include <zmq.h>

#include "fw-addr-conf.hh"
#include "dma.cc"
#include "larpix.cc"

#define RX_ERR (DMA_ERR_IRQ|DMA_INTERR|DMA_SLVERR|DMA_DECERR)

#define RV_ERR_FAILED_TO_BIND 1

#define DMA_BLOCK   0
#define DMA_NOBLOCK 1

uint32_t dma_start(uint32_t* virtual_address, uint32_t rx_address){
    dma_set(virtual_address, DMA_S2MM_CTRL_REG, DMA_RST);
    dma_set(virtual_address, DMA_S2MM_CTRL_REG, 0);
    dma_set(virtual_address, DMA_S2MM_ADDR_REG, rx_address);
    dma_set(virtual_address, DMA_S2MM_CTRL_REG, DMA_RUN | DMA_IOC_IRQEN | DMA_ERR_IRQEN);
}

uint32_t dma_clear(uint32_t* virtual_address){
    uint32_t status = dma_get(virtual_address, DMA_S2MM_STAT_REG);
    if (status & (DMA_IOC_IRQ | DMA_ERR_IRQ)) {
        dma_set(virtual_address, DMA_S2MM_STAT_REG, status);
    }
}

uint32_t dma_read_data(uint32_t* virtual_address, uint32_t nbytes, uint32_t block){
    dma_set(virtual_address, DMA_S2MM_LEN_REG, nbytes);
    if (block == DMA_NOBLOCK) { return 0; }
    return dma_s2mm_sync(virtual_address);
}

int main(int argc, char* argv[]){
    printf("Start pacman-dataserver\n");
    // create zmq connection
    void* ctx = zmq_ctx_new();
    void* pub_socket = zmq_socket(ctx, ZMQ_PUB);
    if (zmq_bind(pub_socket, "tcp://127.0.0.1:5556") !=0 ) {
        printf("Failed to bind socket!\n");
        return RV_ERR_FAILED_TO_BIND;
    }
    printf("ZMQ socket created\n");

    // initialize dma
    int dh = open("/dev/mem", O_RDWR|O_SYNC);
    uint32_t* dma = (uint32_t*)mmap(NULL, DMA_LEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_ADDR);
    uint32_t* dma_rx = (uint32_t*)mmap(NULL, DMA_RX_MAXLEN, PROT_READ|PROT_WRITE, MAP_SHARED, dh, DMA_RX_ADDR);
    dma_start(dma, DMA_RX_ADDR);
    printf("DMA started\n");

    uint32_t fifo_nwords;
    uint32_t dma_max_rx_words = DMA_RX_MAXLEN / LARPIX_WORD_LEN_BYTES;
    uint32_t status;
    uint32_t rx_nbytes;
    while(1) {
        // read current fifo words
        fifo_nwords = 1; // FIXME: placeholder for checking PL fifo

        if (fifo_nwords > 0) {
            printf("New data in FIFO: %i\n", fifo_nwords);
            // initiate non-blocking dma read of fifo words
            rx_nbytes = std::min(fifo_nwords, dma_max_rx_words) * LARPIX_WORD_LEN_BYTES;
            dma_read_data(dma, rx_nbytes, DMA_NOBLOCK);

            // prepare zmq msg
            zmq_msg_t pub_msg;
            zmq_msg_init_size(&pub_msg, rx_nbytes);

            // wait for dma read to complete and transfer data to zmq msg
            status = dma_s2mm_sync(dma);
            memcpy(zmq_msg_data(&pub_msg), dma_rx, rx_nbytes);
            printf("RX: ");
            fwrite(zmq_msg_data(&pub_msg), 1, rx_nbytes, stdout);
            printf("\n");

            if (status & RX_ERR) {
                // read error - restart dma
                dma_s2mm_status(dma);
                dma_start(dma, DMA_RX_ADDR);
                printf("Read error!\nDMA restarted\n");
            } else {
                // queue zmq msg
                zmq_msg_send(&pub_msg, pub_socket, ZMQ_DONTWAIT);
                printf("Message sent!\n");
            }

            // reset
            dma_clear(dma);
            zmq_msg_close(&pub_msg);
        }
    }
    return 0;
}

#endif
