#include <cstdlib>
#include <cstdio>
#include <ctime>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>
#include <sys/time.h>
#include <getopt.h>

#include "pacman_message.hh"

#define SOCKET_A_BINDING_REQ "tcp://localhost:5555"

int main(int argc, char* argv[]) {
    // Default parameters
    unsigned verbose  = 0;
    unsigned nwords   = 1;
    unsigned n_tx     = 1000;
    unsigned delay_us = 132;

    int opt;
    while ((opt = getopt(argc, argv, "v:w:n:d:")) != -1) {
        switch(opt) {
            case 'v': verbose   = std::atoi(optarg); break;
            case 'w': nwords    = std::atoi(optarg); break;
            case 'n': n_tx      = std::atoi(optarg); break;
            case 'd': delay_us  = std::atoi(optarg); break;
            default:
                printf("Usage: %s [-v verbose] [-w nwords] [-n n_tx] [-d delay_us]\n", argv[0]);
                return 1;
        }
    }

    printf("INFO: Starting ZMQ loopback demo.\n");
    printf("INFO: RAND_MAX: 0x%x\n", RAND_MAX);
    printf("INFO: Parameters: verbose=%u nwords=%u n_tx=%u delay_us=%u\n",
           verbose, nwords, n_tx, delay_us);

    unsigned nbytes = nwords * WORD_BYTES;
    pacman_msg_t msg_buf;

    uint64_t ts = static_cast<uint64_t>(std::time(nullptr));
    write_header_data(&msg_buf.header, nbytes, ts);

    // Create ZMQ context
    void* ctx = zmq_ctx_new();
    assert(ctx != nullptr);

    // Initialize REQ socket
    void* req = zmq_socket(ctx, ZMQ_REQ);
    assert(req != nullptr);

    int param = 100;
    zmq_setsockopt(req, ZMQ_SNDHWM, &param, sizeof(param));
    param = 1000;
    zmq_setsockopt(req, ZMQ_LINGER, &param, sizeof(param));
    zmq_setsockopt(req, ZMQ_SNDTIMEO, &param, sizeof(param));
    zmq_setsockopt(req, ZMQ_RCVTIMEO, &param, sizeof(param));

    if (zmq_connect(req, SOCKET_A_BINDING_REQ) != 0) {
        printf("ERROR: Failed to connect socket (%s)!\n", SOCKET_A_BINDING_REQ);
        return 1;
    }
    printf("INFO: ZMQ REQ socket connected successfully...\n");

    // Rate-limiting setup
    struct timeval tau = {0, delay_us};
    struct timeval cur, target, start, end;
    gettimeofday(&cur, nullptr);
    timeradd(&cur, &tau, &target);
    start = target;

    unsigned tx_count = 0;
    printf("INFO: Benchmarking %u TX/RX messages...\n", n_tx);

    while (tx_count < n_tx) {
        gettimeofday(&cur, nullptr);
        if (timercmp(&cur, &target, <)) {
            usleep(10);
            continue;
        }
        cur = target;
        timeradd(&cur, &tau, &target);

        zmq_pollitem_t items[1];
        items[0].socket = req;
        items[0].fd = 0;
        items[0].events = ZMQ_POLLOUT;

        int rc_poll = zmq_poll(items, 1, 0);
        if (rc_poll <= 0 || !(items[0].revents & ZMQ_POLLOUT)) {
            continue;
        }

        for (unsigned i = 0; i < nwords; i++) {
	  uint32_t payload_hi = rand();
	  uint32_t payload_lo = rand();
	  write_word_data(&msg_buf.words[i], 0, 1, upper_32(ts), lower_32(ts), payload_hi, payload_lo);
        }

        if (verbose) {
            if (check_msg(&msg_buf))
                printf("DEBUG: valid message...\n");
            print_msg(&msg_buf);
        }

        zmq_msg_t msg;
        rc_poll = zmq_msg_init_data(&msg, (char*)&msg_buf, HEADER_BYTES + nbytes, nullptr, nullptr);
        assert(rc_poll == 0);
        rc_poll = zmq_msg_send(&msg, req, 0);
        assert(rc_poll != -1);
        rc_poll = zmq_msg_close(&msg);
        assert(rc_poll == 0);

        zmq_msg_t reply;
        zmq_msg_init(&reply);
        rc_poll = zmq_msg_recv(&reply, req, 0);
        zmq_msg_close(&reply);

        tx_count++;
    }

    gettimeofday(&end, nullptr);
    double elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec)/1000.0;

    uint64_t data = 40 * tx_count * nbytes;
    uint64_t packets = data / 24;
    double mbps = 8.0 * data * 1000 / (elapsed_time * 1024 * 1024);
    double ppms = packets / elapsed_time;

    printf("INFO: tx_count: %u\n", tx_count);
    printf("INFO: total bytes:       %lu\n", data);
    printf("INFO: total packets:     %lu\n", packets);
    printf("INFO: elapsed time (ms): %lf\n", elapsed_time);
    printf("INFO: Mbps:              %lf\n", mbps);
    printf("INFO: packets per ms:    %lf\n", ppms);
    printf("INFO: uart rate (kHz):   %lf\n", ppms / 40.0);

    zmq_close(req);
    zmq_ctx_destroy(ctx);

    return 0;
}
