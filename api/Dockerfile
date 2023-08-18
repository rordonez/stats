FROM python:3.11-slim
RUN apt-get -y update && apt-get -y upgrade && \
    apt-get -y clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --chown=nobody:nobody requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt
COPY --chown=nobody:nobody app.py ./

USER nobody

ENTRYPOINT ["python", "./app.py"]
