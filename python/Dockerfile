FROM python:2-alpine

RUN adduser -D web

WORKDIR /home/web

COPY requirements.txt requirements.txt

RUN pip install -r requirements.txt

COPY web.py ./

RUN chown -R web:web ./
USER web

EXPOSE 5000
ENTRYPOINT ["gunicorn", "-b", ":5000", "web:app"]
