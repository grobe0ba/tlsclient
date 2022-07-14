ROOT=.
include ./Make.config

LIBS=\
	libauthsrv/libauthsrv.a\
	libmp/libmp.a\
	libc/libc.a\
	libsec/libsec.a\
	third_party/boringssl/libcrypto.a\
	third_party/boringssl/libssl.a

default: tlsclient
OFILES=cpu.$O p9any.$O

default: $(TARG)
$(TARG): $(LIBS) $(OFILES)
	$(CXX) -pthread -Lthird_party/boringssl $(LDFLAGS) -o $(TARG) $(OFILES) -Wl,--start-group $(LIBS) -Wl,--end-group $(LDADD)

login_-dp9ik: bsd.$O $(LIBS)
	$(CC) -o $@ bsd.$O $(LIBS)

pam_p9.so: pam.$O $(LIBS)
	$(CC) -shared -o $@ pam.$O $(LIBS)

cpu.$O: cpu.c
	$(CC) -Ithird_party/boringssl/src/include $(CFLAGS) cpu.c -o cpu.o

%.$O: %.c
	$(CC) $(CFLAGS) $< -o $@

pam.$O: pam.c
	$(CC) $(CFLAGS) pam.c -o pam.o

bsd.$O: bsd.c
	$(CC) $(CFLAGS) bsd.c -o bsd.o

.PHONY: clean
clean:
	rm -f *.o */*.o */*.a *.a $(TARG) pam_p9.so login_-dp9ik
	$(MAKE) -C third_party/boringssl clean

.PHONY: libauthsrv/libauthsrv.a
libauthsrv/libauthsrv.a:
	(cd libauthsrv; $(MAKE))

libmp/libmp.a:
	(cd libmp; $(MAKE))

libc/libc.a:
	(cd libc; $(MAKE))

libsec/libsec.a:
	(cd libsec; $(MAKE))

.PHONY: third_party/boringssl/libcrypto.a
third_party/boringssl/libcrypto.a:
	(cd third_party/boringssl; $(MAKE) libcrypto.a)

.PHONY: third_party/boringssl/libssl.a
third_party/boringssl/libssl.a:
	(cd third_party/boringssl; $(MAKE) libssl.a)

linuxdist: tlsclient pam_p9.so 9cpu
	tar cf tlsclient.tar tlsclient pam_p9.so 9cpu
	gzip tlsclient.tar

linux.tar.gz: tlsclient pam_p9.so tlsclient.1
	tar cf - tlsclient pam_p9.so tlsclient.1 | gzip > $@

tlsclient.obsd:
	OPENSSL=eopenssl11 LDFLAGS="$(LDFLAGS) -Xlinker --rpath=/usr/local/lib/eopenssl11/" $(MAKE) tlsclient
	mv tlsclient tlsclient.obsd

obsd.tar.gz: tlsclient.obsd login_-dp9ik tlsclient.1
	tar cf - tlsclient.obsd login_-dp9ik tlsclient.1 | gzip > $@

.PHONY: tlsclient.install
tlsclient.install: tlsclient tlsclient.1
	cp tlsclient $(PREFIX)/bin
	cp tlsclient.1 $(PREFIX)/man/man1/

.PHONY: tlsclient.obsd.install
tlsclient.obsd.install: tlsclient.obsd login_-dp9ik tlsclient.1
	install tlsclient.obsd $(PREFIX)/bin/tlsclient
	install tlsclient.1 $(PREFIX)/man/man1/
	install -d $(PREFIX)/libexec/auth
	install -g auth login_-dp9ik $(PREFIX)/libexec/auth/
	install -d $(PREFIX)/libexec/git
	install git-remote-hjgit $(PREFIX)/libexec/git
