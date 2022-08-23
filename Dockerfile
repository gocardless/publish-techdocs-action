FROM spotify/techdocs

RUN apk --no-cache add bash npm

RUN npm install -g @techdocs/cli@^1.2.0

RUN pip install mkdocs-awesome-pages-plugin==2.5.0 mkdocs-nav-enhancements==0.9.1 mkdocs-exclude==1.0.2

COPY main.sh /main.sh

ENTRYPOINT ["/main.sh"]
