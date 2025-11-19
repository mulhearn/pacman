#include <cstdlib>
#include <cstdio>
#include <unistd.h>
#include <zmq.h>
#include <cstring>
#include <cassert>
#include <sys/time.h>

#define SOCKET_A_BINDING_REQ "tcp://localhost:5555"

// BUFFER SIZE:  24 + N * 24
//#define MAX_BUFFER_SIZE 984
#define MAX_BUFFER_SIZE 48
uint32_t tx_buffer[MAX_BUFFER_SIZE/4];

int main() {
    printf("INFO: Starting ZMQ loopback demo.\n");
    printf("INFO: RAND_MAX: 0x%x\n", RAND_MAX);

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
    struct timeval tau = {0, 132}; // inter-send delay
    struct timeval cur, target, start, end;
    gettimeofday(&cur, nullptr);
    timeradd(&cur, &tau, &target);
    start = target;

    int tx_count = 0;
    const int N = 1000;

    printf("INFO: Benchmarking %d TX/RX messages...\n", N);

    while (tx_count < N) {
        // Wait until next send time
        gettimeofday(&cur, nullptr);
        if (timercmp(&cur, &target, <)) {
            usleep(10);
            continue;
        }
        cur = target;
        timeradd(&cur, &tau, &target);

        // Poll ZMQ socket for send readiness
        zmq_pollitem_t items[1];
        items[0].socket = req;   // ZMQ socket
        items[0].fd = 0;         // must be 0 when polling a ZMQ socket
        items[0].events = ZMQ_POLLOUT;

        int rc_poll = zmq_poll(items, 1, 0); // 0 ms timeout
        if (rc_poll <= 0 || !(items[0].revents & ZMQ_POLLOUT)) {
            continue; // socket not ready
        }

        // Prepare message
        unsigned nbytes = MAX_BUFFER_SIZE - 24;
        tx_buffer[0] = 0x3F; // REQUEST
        tx_buffer[1] = nbytes;
	unsigned nwords = nbytes/24;

        for (unsigned i = 0; i < nwords; i++) {
            tx_buffer[6 + 6*i + 0] = 0x0044 + (64 << 16); // broadcast + replay
            tx_buffer[6 + 6*i + 1] = 0;
            tx_buffer[6 + 6*i + 2] = 0;
            tx_buffer[6 + 6*i + 3] = 0;
            tx_buffer[6 + 6*i + 4] = rand();
            tx_buffer[6 + 6*i + 5] = rand();
        }

        // Send message
        zmq_msg_t msg;
        rc_poll = zmq_msg_init_data(&msg, tx_buffer, MAX_BUFFER_SIZE, nullptr, nullptr);
        assert(rc_poll == 0);
        rc_poll = zmq_msg_send(&msg, req, 0);
        assert(rc_poll != -1);
        rc_poll = zmq_msg_close(&msg);
        assert(rc_poll == 0);

        // Receive reply
        zmq_msg_t reply;
        zmq_msg_init(&reply);
        rc_poll = zmq_msg_recv(&reply, req, 0);
        zmq_msg_close(&reply);
	
        tx_count++;
    }

    // Calculate elapsed time
    gettimeofday(&end, nullptr);
    double elapsed_time = 1000.0*(end.tv_sec - start.tv_sec) + (end.tv_usec - start.tv_usec)/1000.0;

    uint64_t data = 40 * tx_count * (MAX_BUFFER_SIZE - 24); // broadcast multiplier
    uint64_t packets = data / 24;
    double mbps = 8.0 * data * 1000 / (elapsed_time * 1024 * 1024); // Mega bits/sec
    double ppms = packets / elapsed_time;

    printf("INFO: tx_count: %d\n", tx_count);
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
