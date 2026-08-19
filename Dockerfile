FROM ubuntu:latest

RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base r-base-dev \
    pandoc \
    jq git lsb-release \
    libcurl4-openssl-dev \
    libfontconfig-dev \
    libfreetype-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libicu-dev \
    libgit2-dev \
    libjpeg-turbo8-dev \
    libpng-dev \
    libuv1-dev \
    libxml2-dev \
    libxslt1-dev \
    libssl-dev \
    libtiff-dev \
    && rm -rf /var/lib/apt/lists/*

RUN printf '%s\n' \
    'local({' \
    ' RV <- getRversion()' \
    ' OS <- paste(RV, R.version["platform"], R.version["arch"], R.version["os"])' \
    ' codename <- sub("Codename.\t", "", system2("lsb_release", "-c", stdout = TRUE))' \
    # Set the default HTTP user agent to get pre-built binary packages
    ' options(HTTPUserAgent = sprintf("R/%s R (%s)", RV, OS))' \
    # register the repositories for The Carpentries and CRAN
    ' options(repos = c(' \
        ' carpentries = "https://carpentries.r-universe.dev/",' \
        ' CRAN = paste0("https://packagemanager.posit.co/all/__linux__/", codename, "/latest")' \
    ' ))' \
    '})' \
    >> /root/.Rprofile


RUN R --no-save -e 'install.packages(c("sandpaper", "varnish", "pegboard"))'
