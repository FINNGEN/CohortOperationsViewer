# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 rocker/rstudio:4.3.0

# install OS dependencies including java and python 3
RUN apt-get update && apt-get install -y openjdk-21-jdk liblzma-dev libbz2-dev libncurses5-dev curl python3-dev python3.venv git \
    # rjava
    libssl-dev libcurl4-openssl-dev  libpcre2-dev libicu-dev \
    # xml2
    libxml2-dev \
    # sodium
    libsodium-dev\
    # systemfonts
    libfontconfig1-dev \
    # textshaping
    libharfbuzz-dev libfribidi-dev\
    #ragg
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev\
&& R CMD javareconf \
&& rm -rf /var/lib/apt/lists/*

# install utility R packages
RUN install2.r \
	openssl \
	httr \
	xml2 \
	remotes \
	gitcreds \
&& rm -rf /tmp/download_packages/ /tmp/*.rds

# Create user and move to users directory
# Create a new user named "myuser" with UID and GID set to 1000
#RUN useradd -ms /bin/bash shiny
#USER shiny

# clone repo
RUN git clone https://github.com/FINNGEN/CohortOperationsViewer /root/CohortOperationsViewer

WORKDIR /root/CohortOperationsViewer

COPY GITHUBPAT.txt /tmp/GITHUBPAT.txt

# install OHDSI HADES R packages from CRAN and GitHub, temporarily adding a GitHub Personal Access Token (PAT) to the Renviron file
# use RSPM
ENV RENV_CONFIG_REPOS_OVERRIDE https://packagemanager.posit.co/cran/latest
RUN --mount=type=secret,id=build_github_pat \
	cp /usr/local/lib/R/etc/Renviron ./Renviron \
        && echo "GITHUB_PAT=$(cat /tmp/GITHUBPAT.txt)" >> ./Renviron \
        && R -e "renv::restore()" \
        && R -e "renv::isolate()" \
        && rm ./Renviron


#
# FORCES REBUILD FROM THIS POINT
# if you want the cache to be busted from this point, you can add a build argument to the build command like so:
# docker build --build-arg CACHEBUST=$(date +%s) -t myimage .
#
ARG CACHEBUST=1

ARG BRANCH_NAME=development

# Update the code and dependencies
RUN git pull
RUN git checkout $BRANCH_NAME
RUN R -e "renv::restore()" \
    && R -e "renv::isolate()" \
    && R -e "devtools::install(dependencies = FALSE)"

EXPOSE 8888

ENTRYPOINT  ["/usr/local/bin/R", "-e", \
             "CohortOperationsViewer::run_app(\
                options = list(host='0.0.0.0', port=8888)\
            )"]

