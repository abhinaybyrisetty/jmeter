FROM justb4/jmeter
RUN apk add git
COPY run.sh /
ENTRYPOINT ["/run.sh"]
