#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stdio.h>
#include <unistd.h>

#ifndef NI_MAXHOST
#define NI_MAXHOST      1025
#endif

static const char PROGNAME[] = "canonip";

/**
 *  Get a canonical IP address
 */
static int canonical_ip(const char *s, char *const host, size_t *const host_len)
{
    struct addrinfo *res;
    int err = 0;

    static const struct addrinfo HINTS = {
        AI_V4MAPPED | AI_ADDRCONFIG | AI_NUMERICHOST,
        AF_UNSPEC,
        0,
        0,
        0,
        NULL,
        NULL,
        NULL
    };

    if ((err = getaddrinfo(s, NULL, &HINTS, &res)) != 0) { goto err0; }
    if ((err = getnameinfo(res->ai_addr, res->ai_addrlen, host, *host_len,
            NULL, 0, NI_NUMERICHOST)) != 0) { goto err1; }
    *host_len = strlen(host);
    freeaddrinfo(res); res = NULL;
    return 0;

err1:
    freeaddrinfo(res); res = NULL;
err0:
    return err;
}

static const char *progname;

static void usage(const char *const msg)
{
    FILE *const f = msg ? stderr : stdout;

    if (msg) {
        fprintf(f, "%s: %s\n", progname, msg);
    }
    fprintf(f,
        "usage: %s [-v] ADDR [,ADDR...]\n"
        "       %s -h\n"
        "       -v Verbose output\n"
        "\n"
        "       -h Print this help message.\n"
        , progname, progname);
}

int main(const int argc, char *const argv[])
{
    int c;
    char host[NI_MAXHOST];
    size_t host_len = NI_MAXHOST;
    int verbose = 0;
    int ret = 0;
    int rc;

    progname = argc > 0 ? argv[0] : PROGNAME;

    while ((c = getopt(argc, argv, "hv")) != -1) {
        switch (c) {
            case 'v':
                ++verbose;
                break;

            case 'h':
                usage(NULL);
                exit(0);
                break;

            default:
                usage("Invalid option");
                exit(2);
                break;
        }
    }

    if (optind >= argc) {
        usage("Need at least one address");
        exit(2);
    }

    for (argv += optind; optind < argc; ++optind, ++argv) {
        host_len = NI_MAXHOST;
        if ((rc = canonical_ip(*argv, host, &host_len)) == 0) {
            fwrite(host, 1, host_len, stdout);
            printf("\n");
        } else {
            if (verbose) {
                fprintf(stderr, "%s: %s\n", progname, gai_strerror(rc));
            }
            ret = 4;
            goto out;
        }
    }

out:
    return ret;
}

/* vim: set ft=c:
 */
