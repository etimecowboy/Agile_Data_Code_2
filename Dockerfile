
# Setup an environment for running this book's examples

FROM ubuntu:16.04
MAINTAINER Russell Jurney, russell.jurney@gmail.com

WORKDIR /root

# Update apt-get and install things
RUN apt-get autoclean
RUN apt-get update && \
    apt-get install -y zip unzip curl bzip2 python-dev build-essential git libssl1.0.0 libssl-dev

# Setup Oracle Java8
# RUN apt-get install -y software-properties-common debconf-utils && \
#     add-apt-repository -y ppa:webupd8team/java && \
#     apt-get update && \
#     echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
#     apt-get install -y oracle-java8-installer
# ENV JAVA_HOME=/usr/lib/jvm/java-8-oracle
RUN apt-get install -y openjdk-8-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Download and install Anaconda Python
ADD ./thirdparty/Anaconda3-4.2.0-Linux-x86_64.sh /tmp/Anaconda3-4.2.0-Linux-x86_64.sh
RUN bash /tmp/Anaconda3-4.2.0-Linux-x86_64.sh -b -p /root/anaconda
ENV PATH="/root/anaconda/bin:$PATH"

#
# Install git, clone repo, install Python dependencies
#
RUN git clone https://github.com/etimecowboy/Agile_Data_Code_2.git
WORKDIR /root/Agile_Data_Code_2
ENV PROJECT_HOME=/Agile_Data_Code_2

RUN git pull
RUN pip install --upgrade pip
RUN pip install -I colorama>=0.3.9
# RUN pip install sqlalchemy
# RUN pip install requests
# RUN pip install Flask
# RUN pip install numpy
# RUN pip install scipy
# RUN pip install ipython
# RUN pip install matplotlib
# RUN pip install scikit-learn
# RUN pip install notebook==5.0.0
RUN pip install pymongo
RUN pip install kafka-python
RUN pip install bs4
RUN pip install py4j
RUN pip install frozendict
RUN pip install geopy
RUN pip install selenium
RUN pip install tabulate
RUN pip install tldextract
RUN pip install wikipedia
RUN pip install findspark
RUN pip install iso8601
RUN pip install beautifulsoup4
RUN pip install pyelasticsearch
RUN pip install apache-airflow --ignore-installed
RUN pip install -I notebook==5.0.0
# RUN pip install -r requirements.txt
# RUN conda install --yes --file requirements.txt
WORKDIR /root

#
# Install Hadoop: may need to update this link... see http://hadoop.apache.org/releases.html
#
COPY ./thirdparty/hadoop-2.7.3.tar.gz /tmp/hadoop-2.7.3.tar.gz
RUN mkdir -p /root/hadoop && \
    tar -xvf /tmp/hadoop-2.7.3.tar.gz -C hadoop --strip-components=1
ENV HADOOP_HOME=/root/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin
ENV HADOOP_CLASSPATH=/root/hadoop/etc/hadoop/:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/etc/hadoop:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/contrib/capacity-scheduler/*.jar:/root/hadoop/contrib/capacity-scheduler/*.jar
ENV HADOOP_CONF_DIR=/root/hadoop/etc/hadoop

#
# Install Spark: may need to update this link... see http://spark.apache.org/downloads.html
#
COPY ./thirdparty/spark-2.1.0-bin-without-hadoop.tgz /tmp/spark-2.1.0-bin-without-hadoop.tgz
RUN mkdir -p /root/spark && \
    tar -xvf /tmp/spark-2.1.0-bin-without-hadoop.tgz -C spark --strip-components=1
ENV SPARK_HOME=/root/spark
ENV HADOOP_CONF_DIR=/root/hadoop/etc/hadoop/
ENV SPARK_DIST_CLASSPATH=/root/hadoop/etc/hadoop/:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/etc/hadoop:/root/hadoop/share/hadoop/common/lib/*:/root/hadoop/share/hadoop/common/*:/root/hadoop/share/hadoop/hdfs:/root/hadoop/share/hadoop/hdfs/lib/*:/root/hadoop/share/hadoop/hdfs/*:/root/hadoop/share/hadoop/yarn/lib/*:/root/hadoop/share/hadoop/yarn/*:/root/hadoop/share/hadoop/mapreduce/lib/*:/root/hadoop/share/hadoop/mapreduce/*:/root/hadoop/contrib/capacity-scheduler/*.jar:/root/hadoop/contrib/capacity-scheduler/*.jar
ENV PATH=$PATH:/root/spark/bin

# Have to set spark.io.compression.codec in Spark local mode, give 8GB RAM
RUN cp /root/spark/conf/spark-defaults.conf.template /root/spark/conf/spark-defaults.conf && \
    echo 'spark.io.compression.codec org.apache.spark.io.SnappyCompressionCodec' >> /root/spark/conf/spark-defaults.conf && \
    echo "spark.driver.memory 8g" >> /root/spark/conf/spark-defaults.conf

# Setup spark-env.sh to use Python 3
RUN echo "PYSPARK_PYTHON=python3" >> /root/spark/conf/spark-env.sh && \
    echo "PYSPARK_DRIVER_PYTHON=python3" >> /root/spark/conf/spark-env.sh

# Setup log4j config to reduce logging output
RUN cp /root/spark/conf/log4j.properties.template /root/spark/conf/log4j.properties && \
    sed -i 's/INFO/ERROR/g' /root/spark/conf/log4j.properties

#
# Install Mongo, Mongo Java driver, and mongo-hadoop and start MongoDB
#
RUN echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.4.list
RUN apt-get update && \
    apt-get install -y --allow-unauthenticated mongodb-org && \
    mkdir -p /data/db
# apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 && \
RUN /usr/bin/mongod --fork --logpath /var/log/mongodb.log

# Get the MongoDB Java Driver and put it in Agile_Data_Code_2
ADD ./thirdparty/mongo-java-driver-3.4.0.jar /tmp/mongo-java-driver-3.4.0.jar
RUN mv /tmp/mongo-java-driver-3.4.0.jar /root/Agile_Data_Code_2/lib/

# Install the mongo-hadoop project in the mongo-hadoop directory in the root of our project.
COPY ./thirdparty/mongo-hadoop-r1.5.2.tar.gz /tmp/mongo-hadoop-r1.5.2.tar.gz
RUN mkdir -p /root/mongo-hadoop && \
    tar -xvzf /tmp/mongo-hadoop-r1.5.2.tar.gz -C mongo-hadoop --strip-components=1 && \
    rm -f /tmp/mongo-hadoop-r1.5.2.tar.gz
WORKDIR /root/mongo-hadoop
RUN /root/mongo-hadoop/gradlew jar
WORKDIR /root
RUN cp /root/mongo-hadoop/spark/build/libs/mongo-hadoop-spark-*.jar /root/Agile_Data_Code_2/lib/ && \
    cp /root/mongo-hadoop/build/libs/mongo-hadoop-*.jar /root/Agile_Data_Code_2/lib/

# Install pymongo_spark
WORKDIR /root/mongo-hadoop/spark/src/main/python
RUN python setup.py install
WORKDIR /root
RUN cp /root/mongo-hadoop/spark/src/main/python/pymongo_spark.py /root/Agile_Data_Code_2/lib/
ENV PYTHONPATH=$PYTHONPATH:/root/Agile_Data_Code_2/lib

# Cleanup mongo-hadoop
RUN rm -rf /root/mongo-hadoop

#
# Install ElasticSearch in the elasticsearch directory in the root of our project, and the Elasticsearch for Hadoop package
#
COPY ./thirdparty/elasticsearch-5.1.1.tar.gz /tmp/elasticsearch-5.1.1.tar.gz
RUN mkdir /root/elasticsearch && \
    tar -xvzf /tmp/elasticsearch-5.1.1.tar.gz -C elasticsearch --strip-components=1 && \
    /root/elasticsearch/bin/elasticsearch -d && \
    rm -f /tmp/elasticsearch-5.1.1.tar.gz

# Install Elasticsearch for Hadoop
COPY ./thirdparty/elasticsearch-hadoop-5.1.1.zip /tmp/elasticsearch-hadoop-5.1.1.zip
RUN unzip /tmp/elasticsearch-hadoop-5.1.1.zip && \
    mv /root/elasticsearch-hadoop-5.1.1 /root/elasticsearch-hadoop && \
    cp /root/elasticsearch-hadoop/dist/elasticsearch-hadoop-5.1.1.jar /root/Agile_Data_Code_2/lib/ && \
    cp /root/elasticsearch-hadoop/dist/elasticsearch-spark-20_2.10-5.1.1.jar /root/Agile_Data_Code_2/lib/ && \
    echo "spark.speculation false" >> /root/spark/conf/spark-defaults.conf && \
    rm -f /tmp/elasticsearch-hadoop-5.1.1.zip && \
    rm -rf /root/elasticsearch-hadoop

# Install and add snappy-java and lzo-java to our classpath below via spark.jars
ADD ./thirdparty/snappy-java-1.1.2.6.jar /tmp/snappy-java-1.1.2.6.jar
ADD ./thirdparty/lzo-hadoop-1.0.5.jar /tmp/lzo-hadoop-1.0.5.jar
RUN mv /tmp/snappy-java-1.1.2.6.jar /root/Agile_Data_Code_2/lib/ && \
    mv /tmp/lzo-hadoop-1.0.5.jar /root/Agile_Data_Code_2/lib/

# Setup mongo and elasticsearch jars for Spark
RUN echo "spark.jars /root/Agile_Data_Code_2/lib/mongo-hadoop-spark-1.5.2.jar,/root/Agile_Data_Code_2/lib/mongo-java-driver-3.4.0.jar,/root/Agile_Data_Code_2/lib/mongo-hadoop-1.5.2.jar,/root/Agile_Data_Code_2/lib/elasticsearch-spark-20_2.10-5.1.1.jar,/root/Agile_Data_Code_2/lib/snappy-java-1.1.2.6.jar,/root/Agile_Data_Code_2/lib/lzo-hadoop-1.0.5.jar" >> /root/spark/conf/spark-defaults.conf

#
# Install and setup Kafka
#
COPY ./thirdparty/kafka_2.11-0.10.1.1.tgz /tmp/kafka_2.11-0.10.1.1.tgz
RUN mkdir -p /root/kafka && \
    tar -xvzf /tmp/kafka_2.11-0.10.1.1.tgz -C kafka --strip-components=1 && \
    rm -f /tmp/kafka_2.11-0.10.1.1.tgz

# Run zookeeper (which kafka depends on), then Kafka
RUN /root/kafka/bin/zookeeper-server-start.sh -daemon /root/kafka/config/zookeeper.properties && \
    /root/kafka/bin/kafka-server-start.sh -daemon /root/kafka/config/server.properties

#
# Install and set up Airflow
#
# Install Apache Incubating Airflow
RUN pip install apache-airflow && \
    mkdir /root/airflow && \
    mkdir /root/airflow/dags && \
    mkdir /root/airflow/logs && \
    mkdir /root/airflow/plugins && \
    airflow initdb && \
    airflow webserver -D && \
    airflow scheduler -D &

#
# Install and setup Zeppelin
#
WORKDIR /root
COPY ./thirdparty/zeppelin-0.6.2-bin-all.tgz /tmp/zeppelin-0.6.2-bin-all.tgz
RUN mkdir -p /root/zeppelin && \
    tar -xvzf /tmp/zeppelin-0.6.2-bin-all.tgz -C zeppelin --strip-components=1 && \
    rm -f /tmp/zeppelin-0.6.2-bin-all.tgz

# Configure Zeppelin
RUN cp /root/zeppelin/conf/zeppelin-env.sh.template /root/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_HOME=/root/spark" >> /root/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_MASTER=local" >> /root/zeppelin/conf/zeppelin-env.sh && \
    echo "export SPARK_CLASSPATH=" >> /root/zeppelin/conf/zeppelin-env.sh

#
# Download the data
#
WORKDIR /root/Agile_Data_Code_2/data

# On-time performance records
# ADD ./data/On_Time_On_Time_Performance_2015.csv.gz /root/Agile_Data_Code_2/data/On_Time_On_Time_Performance_2015.csv.gz

# Openflights data
# ADD ./data/airports.dat /root/Agile_Data_Code_2/data/airports.dat
# ADD ./data/airlines.dat /root/Agile_Data_Code_2/data/airlines.dat
# ADD ./data/routes.dat /root/Agile_Data_Code_2/data/routes.dat
# ADD ./data/countries.dat /root/Agile_Data_Code_2/data/countries.dat

# FAA data
# ADD ./data/aircraft.txt /root/Agile_Data_Code_2/data/aircraft.txt
# ADD ./data/ata.txt /root/Agile_Data_Code_2/data/ata.txt
# ADD ./data/compt.txt /root/Agile_Data_Code_2/data/compt.txt
# ADD ./data/engine.txt /root/Agile_Data_Code_2/data/engine.txt
# ADD ./data/prop.txt /root/Agile_Data_Code_2/data/prop.txt

# WBAN Master List
# ADD ./data/wbanmasterlist.psv.zip /tmp/wbanmasterlist.psv.zip

# RUN for i in $(seq -w 1 12); do curl -Lko /tmp/QCLCD2015${i}.zip http://www.ncdc.noaa.gov/orders/qclcd/QCLCD2015${i}.zip && \
#     unzip -o /tmp/QCLCD2015${i}.zip && \
#     gzip 2015${i}*.txt && \
#     rm -f /tmp/QCLCD2015${i}.zip; done

#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201501.zip /tmp/QCLCD201501.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201502.zip /tmp/QCLCD201502.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201503.zip /tmp/QCLCD201503.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201504.zip /tmp/QCLCD201504.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201505.zip /tmp/QCLCD201505.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201506.zip /tmp/QCLCD201506.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201507.zip /tmp/QCLCD201507.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201508.zip /tmp/QCLCD201508.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201509.zip /tmp/QCLCD201509.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201510.zip /tmp/QCLCD201510.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201511.zip /tmp/QCLCD201511.zip
#ADD https://www.ncdc.noaa.gov/orders/qclcd/QCLCD201512.zip /tmp/QCLCD201512.zip
#
#RUN unzip -o /tmp/wbanmasterlist.psv.zip && \
#    gzip wbanmasterlist.psv && \
#    rm -f /tmp/wbanmasterlist.psv.zip && \
#    unzip -o /tmp/QCLCD201501.zip && \
#    gzip 201501*.txt && \
#    rm -f /tmp/QCLCD201501.zip && \
#    unzip -o /tmp/QCLCD201502.zip && \
#    gzip 201502*.txt && \
#    rm -f /tmp/QCLCD201502.zip && \
#    unzip -o /tmp/QCLCD201503.zip && \
#    gzip 201503*.txt && \
#    rm -f /tmp/QCLCD201503.zip && \
#    unzip -o /tmp/QCLCD201504.zip && \
#    gzip 201504*.txt && \
#    rm -f /tmp/QCLCD201504.zip && \
#    unzip -o /tmp/QCLCD201505.zip && \
#    gzip 201505*.txt && \
#    rm -f /tmp/QCLCD201505.zip && \
#    unzip -o /tmp/QCLCD201506.zip && \
#    gzip 201506*.txt && \
#    rm -f /tmp/QCLCD201506.zip && \
#    unzip -o /tmp/QCLCD201507.zip && \
#    gzip 201507*.txt && \
#    rm -f /tmp/QCLCD201507.zip && \
#    unzip -o /tmp/QCLCD201508.zip && \
#    gzip 201508*.txt && \
#    rm -f /tmp/QCLCD201508.zip && \
#    unzip -o /tmp/QCLCD201509.zip && \
#    gzip 201509*.txt && \
#    rm -f /tmp/QCLCD201509.zip && \
#    unzip -o /tmp/QCLCD201510.zip && \
#    gzip 201510*.txt && \
#    rm -f /tmp/QCLCD201510.zip && \
#    unzip -o /tmp/QCLCD201511.zip && \
#    gzip 201511*.txt && \
#    rm -f /tmp/QCLCD201511.zip && \
#    unzip -o /tmp/QCLCD201512.zip && \
#    gzip 201512*.txt && \
#    rm -f /tmp/QCLCD201512.zip

# Back to /root
WORKDIR /root
RUN pip install --upgrade notebook
# RUN pip install -I tornado==5.1.1

# Cleanup
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Done!

WORKDIR /root/Agile_Data_Code_2
RUN git pull 
# ENTRYPOINT ["jupyter", "notebook", "--allow-root"]