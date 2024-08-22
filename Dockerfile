FROM spotify/techdocs:v1.2.3

RUN apk --no-cache add bash npm

RUN npm install -g @techdocs/cli@1.8.12

RUN pip install --no-cache-dir mkdocs-awesome-pages-plugin==2.5.0 \
    mkdocs-nav-enhancements==0.9.1 \
    mkdocs-exclude==1.0.2 \
    mkdocs-section-index==0.3.5

COPY main.sh /main.sh

ENTRYPOINT ["/main.sh"]
