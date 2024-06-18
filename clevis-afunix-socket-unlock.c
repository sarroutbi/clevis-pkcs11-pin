/*
 * Copyright (c) 2024 Red Hat, Inc.
 * Author: Red Hat Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <arpa/inet.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/un.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <unistd.h>

const char* VERSION = "202406181113";
const uint16_t MAX_ITERATIONS = 3;
const uint16_t MAX_KEY = 256;
const uint16_t MAX_PATH = 1024;

int main(int argc, char* argv[]) {
    int s, a, opt, ret;
    uint32_t iterations = MAX_ITERATIONS;
    uint32_t ic = 0;
    char file[MAX_PATH];
    char key[MAX_KEY];
    struct sockaddr_un control_addr, acept_addr, peer_addr, anon_addr;
    socklen_t len;
    socklen_t pathlen;

    while ((opt = getopt(argc, argv, "f:k:i:")) != -1) {
        switch (opt) {
        case 'f':
          strncpy(file, optarg, MAX_PATH);
          break;
        case 'k':
          strncpy(key, optarg, MAX_KEY);
          break;
        case 'i':
          iterations = strtoul(optarg, 0, 10);
          break;
        default: /* '?' */
          fprintf(stderr, "Usage: %s -f file -k key [-i iterations, 3 by default]\n",
                  argv[0]);
          exit(EXIT_FAILURE);
        }
    }
    printf("VERSION: [%s]\n", VERSION);
    printf("FILE: [%s]\n", file);
    printf("KEY: [%s]\n", key);
    printf("TRY ITERATIONS: [%u]\n", iterations);

    memset(&control_addr, 0, sizeof(control_addr));
    control_addr.sun_family = AF_UNIX;
    strcpy(control_addr.sun_path, file);
    unlink(file);

    s = socket(AF_UNIX, SOCK_STREAM, 0);
    if (s == -1) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    ret = bind(s, (struct sockaddr *)&control_addr, sizeof(control_addr));
    if (ret == -1) {
        perror("bind");
        exit(EXIT_FAILURE);
    }

    ret = listen(s, SOMAXCONN);
    if (ret == -1) {
        perror("listen");
        exit(EXIT_FAILURE);
    }

    len = sizeof(acept_addr);

    while (ic++ < iterations) {
        a = accept(s, (struct sockaddr *)&acept_addr, &len);
        if (a == -1) {
            perror("accept");
            exit(EXIT_FAILURE);
        }

        pathlen = len - offsetof(struct sockaddr_un, sun_path);

        len = sizeof(peer_addr);
        ret = getpeername(a, (struct sockaddr *)&peer_addr, &len);
        if (ret == -1) {
            perror("getpeername");
            exit(EXIT_FAILURE);
        }

        pathlen = len - offsetof(struct sockaddr_un, sun_path);
        char peer[pathlen];
        memset(peer, 0, pathlen);
        strncpy(peer, peer_addr.sun_path+1, pathlen-1);
        printf("Try: [%u/%u]\n", ic, iterations);
        printf("getpeername sun_path(peer): [%s]\n", peer);

        // Now we have all the information in peer, something like:
        // \099226072855ae2d8/cryptsetup/luks-6e38d5e1-7f83-43cc-819a-7416bcbf9f84
        // NUL random /cryptsetup/ DEVICE
        // If we need to unencrypt device, pick it from peer information
        // To return the key, just respond to socket returned by accept
        send(a, key, strlen(key), 0);
        close(a);
    }
    return EXIT_SUCCESS;
}
