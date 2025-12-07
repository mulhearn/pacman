#include <chrono>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <thread>
#include <zmq.h>

#include "rx_buffer.hh"
#include "pacman.hh"
#include "pacman_message.hh"

// -----------------------------
// Configuration constants
// -----------------------------
#define PUB_SOCKET_BINDING "tcp://*:5556"
#define MAX_BATCH 16000       // max words per message
#define MIN_BATCH 4000        // min words to trigger send
#define BATCH_TIMEOUT_MS 1    // flush timeout in milliseconds

const int PUB_HWM     = 100;    // high-water mark
const int PUB_LINGER  = 0;      // drop unsent messages at close
const int PUB_SNDTIMEO = 1000;  // send timeout in ms

volatile bool msg_ready = true;

// ZMQ free callback
void clear_msg(void*, void*) {
    msg_ready = true;
}

int main(int argc, char* argv[]) {
    printf("INFO:  Starting pacman-dataserver...\n");

    printf("INFO:  Initializing RX buffer.\n");
    rx_buffer_init();

    printf("INFO:  Initializing ZMQ socket.\n");
    void* ctx = zmq_ctx_new();
    if (!ctx) { perror("ERROR: zmq_ctx_new failed"); return EXIT_FAILURE; }

    void* pub_socket = zmq_socket(ctx, ZMQ_PUB);
    if (!pub_socket) { perror("ERROR: zmq_socket failed"); zmq_ctx_term(ctx); return EXIT_FAILURE; }

    if (zmq_setsockopt(pub_socket, ZMQ_SNDHWM, &PUB_HWM, sizeof(PUB_HWM)) != 0 ||
        zmq_setsockopt(pub_socket, ZMQ_LINGER, &PUB_LINGER, sizeof(PUB_LINGER)) != 0 ||
        zmq_setsockopt(pub_socket, ZMQ_SNDTIMEO, &PUB_SNDTIMEO, sizeof(PUB_SNDTIMEO)) != 0) {
        perror("ERROR: zmq_setsockopt failed");
        zmq_close(pub_socket);
        zmq_ctx_term(ctx);
        return EXIT_FAILURE;
    }

    if (zmq_bind(pub_socket, PUB_SOCKET_BINDING) != 0) {
        printf("ERROR: Failed to bind socket at %s\n", PUB_SOCKET_BINDING);
        printf("ERROR: (Perhaps pacman_dataserver is already running?)\n");
        zmq_close(pub_socket);
        zmq_ctx_term(ctx);
        return EXIT_FAILURE;
    }
    printf("INFO: ZMQ socket bound successfully at %s\n", PUB_SOCKET_BINDING);

    printf("INFO: Initializing PACMAN RX driver.\n");
    if (pacman_init_rx(1,1) == EXIT_FAILURE) {
        printf("ERROR: Failed to initialize PACMAN RX driver\n");
        zmq_close(pub_socket);
        zmq_ctx_term(ctx);
        return EXIT_FAILURE;
    }
    printf("INFO: PACMAN RX driver initialization was successful.\n");

    printf("INFO: Entering RX loop.\n");

    // -----------------------------
    // Preallocated message buffer
    // -----------------------------
    static char msg_buffer[HEADER_BYTES + MAX_BATCH*WORD_BYTES];
    zmq_msg_t pub_msg;

    uint64_t total_words = 0;
    auto batch_start_time = std::chrono::steady_clock::now();

    while (1) {
        // Poll RX buffer continuously
        pacman_poll_rx();
        uint32_t available = rx_buffer_count();

        // Accumulate words in batch counter
        if (available > MAX_BATCH) available = MAX_BATCH;

        auto now = std::chrono::steady_clock::now();
        auto elapsed_ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - batch_start_time).count();

        // Check if we should flush
        if (msg_ready && ((available >= MIN_BATCH) || ((available > 0) && (elapsed_ms >= BATCH_TIMEOUT_MS)))){

            // Copy words from RX buffer into message buffer
            for (uint32_t i = 0; i < available; i++) {
                pacman_word_t* w = (pacman_word_t*)(msg_buffer + HEADER_BYTES + i*WORD_BYTES);
                if (rx_buffer_out((uint32_t*)w) == 0) {
                    printf("ERROR: rx_buffer_out failed unexpectedly\n");
                    available = 0;
                    batch_start_time = std::chrono::steady_clock::now();
                    break;
                }
            }

            // Initialize header
            write_header_data((pacman_header_t*)msg_buffer, available*WORD_BYTES);

            // Send message with zero-copy
            msg_ready = false;
            if (zmq_msg_init_data(&pub_msg, msg_buffer,
                                  HEADER_BYTES + available*WORD_BYTES,
                                  clear_msg, NULL) != 0) {
                perror("ERROR: zmq_msg_init_data failed");
                available = 0;
                batch_start_time = std::chrono::steady_clock::now();
                continue;
            }

            if (zmq_msg_send(&pub_msg, pub_socket, 0) < 0) {
                perror("ERROR: zmq_msg_send failed");
            } else {
                total_words += available;
            }

            zmq_msg_close(&pub_msg);

            available = 0;
            batch_start_time = std::chrono::steady_clock::now();
        }

        // Avoid busy spin if nothing to do
        if (available < MIN_BATCH) {
	  std::this_thread::sleep_for(std::chrono::microseconds(100));
        }
    }

    zmq_close(pub_socket);
    zmq_ctx_term(ctx);
    return EXIT_SUCCESS;
}

