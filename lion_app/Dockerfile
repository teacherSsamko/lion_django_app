FROM python:3.11-alpine

ARG APP_HOME=/app

ENV PYTHONUNBUFFERED 1
ENV PYTHONDONTWRITEBYTECODE 1

RUN mkdir ${APP_HOME}

COPY ./requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . ${APP_HOME}

COPY ./scripts/start /start
RUN sed -i 's/\r$//g' /start
RUN chmod +x /start

WORKDIR ${APP_HOME}

RUN if [-e /var/www/html/static ]; then rm -rf /var/www/html/static; fi
RUN python manage.py collectstatic -c


CMD [ "python", "--version" ]
