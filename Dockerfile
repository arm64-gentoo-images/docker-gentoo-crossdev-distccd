FROM samuelololol/docker-gentoo-websync
MAINTAINER samuelololol <samuelololol@gmail.com>
RUN rm /sbin/unix_chkpwd
#COPY crossdev.conf /etc/portage/repos.conf/crossdev.conf
RUN emerge crossdev sys-libs/db sys-libs/pam sys-apps/iproute2 dev-lang/perl \
    sys-libs/binutils-libs \
    # helps to save time for building later image
&& USE="${USE} crossdev" emerge distcc \
&&  mkdir -p /usr/local/portage-crossdev/{profiles,metadata} && \
    echo 'crossdev' > /usr/local/portage-crossdev/profiles/repo_name && \
    echo 'masters = gentoo' > /usr/local/portage-crossdev/metadata/layout.conf && \
    chown -R portage:portage /usr/local/portage-crossdev \
&& ( \
    echo "[crossdev]" && \
    echo "location = /usr/local/portage-crossdev" && \
    echo "priority = 10" && \
    echo "masters = gentoo" && \
    echo "auto-sync = no" \
    ) > /etc/portage/repos.conf/crossdev.conf \
&&  ( \
    echo "#!/bin/sh" && \
    echo "eval \"\`gcc-config -E\`\"" && \
    echo "exec distccd \"\$@\"" \
    ) > /usr/local/sbin/distccd-launcher && \
    chmod +x /usr/local/sbin/distccd-launcher \
&& emerge ccache && \
    echo 'FEATURES="ccache"' >> /etc/portage/make.conf && \
    echo 'CCACHE_SIZE="2G"' >> /etc/portage/make.conf && \
    echo 'CCACHE_MAXSIZE="2G"' >> /etc/portage/make.conf && \
    echo 'CCACHE_DIR="/var/tmp/portage/ccache"' >> /etc/portage/make.conf && \
    echo 'CCACHE_TEMPDIR="/var/tmp/portage/ccache"' >> /etc/portage/make.conf \
&& emerge -f binutils gcc linux-headers glibc \
&& crossdev --stable -t aarch64-unknown-linux-gnu --init-target -oO /usr/local/portage-crossdev \
&& echo "cross-aarch64-unknown-linux-gnu/gcc cxx multilib fortran -mudflap nls openmp -sanitize -vtv" >> /etc/portage/package.use/crossdev \
&& crossdev --stable -t aarch64-unknown-linux-gnu -oO /usr/local/portage-crossdev \
&& cd /usr/aarch64-unknown-linux-gnu/etc/portage \
&& rm -f make.profile \
&& ln -s /usr/portage/profiles/default/linux/arm64/17.0/desktop make.profile \
&& echo 'CHOST="aarch64-unknown-linux-gnu-5.4.0"' >> /etc/portage/make.conf \
&& gcc-config aarch64-unknown-linux-gnu-5.4.0 \
&&  rm -r /usr/portage
#RUN crossdev -S -v -t armv6j-hardfloat-linux-gnueabi
#RUN emerge-webrsync
#RUN mkdir -pv /usr/local/portage-crossdev
#RUN ls /etc/env.d/gcc/
#RUN grep CHOST /etc/portage/make.conf
#RUN ls /usr/local/portage-crossdev
#RUN bash -c 'source /etc/profile &&  gcc-config  -l'
#RUN aarch64-unknown-linux-gnu-gcc --version
CMD ["/usr/local/sbin/distccd-launcher", "--allow", "0.0.0.0/0", "--user", "distcc", "--log-level", "notice", "--log-stderr", "--no-detach"]
EXPOSE 3632
