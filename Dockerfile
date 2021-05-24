FROM spotify/techdocs

RUN apk --no-cache add bash npm

RUN npm install -g @techdocs/cli

RUN pip install mkdocs-awesome-pages-plugin==2.5.0 mkdocs-nav-enhancements==0.9.1

WORKDIR /github/workspace

RUN chmod +x /main.sh

ENTRYPOINT ["main.sh"]