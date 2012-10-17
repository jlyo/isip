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

static const char PROGNAME[] = "isip";

%%{
    machine isip;

    octet4 =               [0-9]{1,2}
           |       [0-1] . [0-9]{2}
           | '2' . [0-4] . [0-9]
           | '2' .   '5' . [0-5];

    short_netmask = [0-9]
            | [0-2] . [0-9]
            | '3' . [0-2];

    zero = '0'{1,3};

    dqnetmaskoctet = '255'
                   | '254'
                   | '252'
                   | '248'
                   | '240'
                   | '224'
                   | '192'
                   | '128'
                   | zero;

    dqnetmask = '255.'{3} dqnetmaskoctet
              | '255.'{2} dqnetmaskoctet ('.' zero){1}
              | '255.'{1} dqnetmaskoctet ('.' zero){2}
              |           dqnetmaskoctet ('.' zero){3};

    netmask = '/' (  short_netmask
                   | dqnetmask);

    ipv4 = (octet4 '.'){3} octet4;

    short6 = xdigit{1,4};

    prefix = '/' (  [0-9]{1,2}
                  | '1' . [0-1] . [0-9]
                  | '12' . [0-8]);

    ipv6 = (  (short6 ':'){7} short6
            | (short6 ':'){7} ':' short6?
            | (short6 ':'){6} ':' ((short6 ':'){0,1} short6)?
            | (short6 ':'){5} ':' ((short6 ':'){0,2} short6)?
            | (short6 ':'){4} ':' ((short6 ':'){0,3} short6)?
            | (short6 ':'){3} ':' ((short6 ':'){0,4} short6)?
            | (short6 ':'){2} ':' ((short6 ':'){0,5} short6)?
            | (short6 ':'){1} ':' ((short6 ':'){0,6} short6)?
            |                '::' ((short6 ':'){0,7} short6)?);

}%%

%%write data;

#define ISIP_ALLOW_NETMASK  (1<<0)
#define ISIP_ALLOW_BRACKETS (1<<1)
#define ISIP_ALLOW_IPV4     (1<<2)
#define ISIP_ALLOW_IPV6     (1<<3)
static bool isip(const char *p, const size_t len, unsigned int flags)
{
    const char *const pe = p + len;
    const char *const eof = pe;
    const bool allow_netmask = flags & ISIP_ALLOW_NETMASK;
    const bool allow_brackets = flags & ISIP_ALLOW_BRACKETS;
    const bool allow_ipv4 = flags & ISIP_ALLOW_IPV4;
    const bool allow_ipv6 = flags & ISIP_ALLOW_IPV6;
    int cs;

    %%{
        ipv6_ = ipv6 % { if (!allow_ipv6) { return false; } };
        ipv4_ = ipv4 % { if (!allow_ipv4) { return false; } };
        prefix_ = prefix  % { if (!allow_netmask) { return false; } };
        netmask_ = netmask % { if (!allow_netmask) { return false; } };
        bracket_ipv6_ = ('[' ipv6_ prefix_? ']') %
                            { if (!allow_brackets) { return false; } };
        main := (  (ipv4_ netmask_?)
                 | (ipv6_ prefix_?)
                 | bracket_ipv6_
                ) $err { return false; } ;
        write init;
        write exec;
    }%%

    return true;
}

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
        "usage: %s [-c] [-p] [-n] [-b] [-4] [-6] [-v] ADDR [,ADDR...]\n"
        "       %s -h\n"
        "\n"
        "       -c Print the canonical IP address\n"
        "       -p Allow IP addresses with a prefix\n"
        "       -n Allow IP addresses with a netmask (same as -p)\n"
        "       -b Allow square brackets (for IPv6)\n"
        "       -4 Allow IPv4 addresses\n"
        "       -6 Allow IPv6 addresses\n"
        "       -v Verbose output\n"
        "\n"
        "       -h Print this help message.\n"
        , progname, progname);
}

int main(const int argc, char *const argv[])
{
    int c;
    char *host = NULL;
    size_t host_len = NI_MAXHOST;
    int canonicalize = 0;
    int verbose = 0;
    int ret = 0;
    int rc;
    int isip_flags = 0;

    progname = argc > 0 ? argv[0] : PROGNAME;

    while ((c = getopt(argc, argv, "hcvpnb46")) != -1) {
        switch (c) {
            case 'c':
                ++canonicalize;
                break;

            case 'v':
                ++verbose;
                break;

            case 'h':
                usage(NULL);
                exit(0);
                break;

            case 'p':
            case 'n':
                isip_flags |= ISIP_ALLOW_NETMASK;
                break;

            case 'b':
                isip_flags |= ISIP_ALLOW_BRACKETS;
                break;

            case '4':
                isip_flags |= ISIP_ALLOW_IPV4;
                break;

            case '6':
                isip_flags |= ISIP_ALLOW_IPV6;
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

    /* If neither -4 or -6 specified assume both */
    if (!(isip_flags & (ISIP_ALLOW_IPV4 | ISIP_ALLOW_IPV6))) {
        isip_flags |= ISIP_ALLOW_IPV4 | ISIP_ALLOW_IPV6;
    }

    if (canonicalize && (host = malloc(NI_MAXHOST)) == NULL) {
        perror(progname);
        exit(4);
    }

    for (argv += optind; optind < argc; ++optind, ++argv) {
        if (!isip(*argv, strlen(*argv), isip_flags)) {
            if (verbose) {
                fprintf(stderr, "%s: Not an IP address: %s\n",
                        progname, *argv);
            }
            ret = 1;
            goto out;
        }
        /* else */

        if (canonicalize) {
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
    }

out:
    if (canonicalize) { free(host); }
    return ret;
}

/* vim: set ft=c:
 */
