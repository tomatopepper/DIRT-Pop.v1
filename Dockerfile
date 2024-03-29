FROM mambaorg/micromamba:0.19.1

USER root

RUN apt-get update && \
    apt-get install -y dirmngr \
    gnupg \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    libcurl4-openssl-dev \
    libssl-dev \
    libstdc++6

# install tk for python3 (need to temporarily switch to root since micromamba sets the default user)
RUN apt-get update && apt-get install -y python3-tk curl bzip2

# install R
run apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' && \
    add-apt-repository 'deb http://cloud.r-project.org/bin/linux/debian bullseye-cran40/' && \
    apt-get update && \
    apt-get install -y r-base r-base-dev

# install R dependencies
run R -e "install.packages('remotes',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('stringr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('tidyr',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('lattice',dependencies=TRUE, repos='http://cran.rstudio.com/')"
# run R -e "install.packages('reticulate',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('roahd',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('cluster',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "install.packages('optparse',dependencies=TRUE, repos='http://cran.rstudio.com/')"
run R -e "library(remotes); install_version('reticulate', '1.22')"

USER $MAMBAUSER

# copy source and configure conda environment
WORKDIR /opt/DIRT-Pop
COPY . /opt/DIRT-Pop
COPY --chown=$MAMBA_USER:$MAMBA_USER dirtclust.yml /opt/DIRT-Pop/DIRT-Pop.yml
RUN micromamba create --yes --file /opt/DIRT-Pop/DIRT-Pop.yml && micromamba clean --all --yes
ENV ENV_NAME="arbc"

# fix matplotlib Qt issue (https://stackoverflow.com/a/52353715)
ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN pip uninstall -y matplotlib && \
    python -m pip install --upgrade pip && \
    pip install matplotlib

# environment should automatically activate
RUN chmod +x activate_env.sh
ENV BASH_ENV=/opt/code/activate_env.sh

# fix libstdc++.so.6
# https://stackoverflow.com/questions/20357033/usr-lib-x86-64-linux-gnu-libstdc-so-6-version-cxxabi-1-3-8-not-found
RUN mv /usr/lib/x86_64-linux-gnu/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6.old && \
    cp /opt/conda/pkgs/libstdcxx-ng-12.2.0-h46fd767_19/lib/libstdc++.so.6 /usr/lib/x86_64-linux-gnu/libstdc++.so.6
