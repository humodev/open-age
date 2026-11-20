# Relevo y salas de Raíces (proceso/44-version-para-amigos). Sin dependencias: solo Python.
#   docker build -t raices-relevo server/
#   docker run -d --name raices-relevo --restart unless-stopped -p 47900:47900 raices-relevo
FROM python:3.12-alpine
RUN adduser -D -H raices
COPY relevo.py /app/relevo.py
USER raices
EXPOSE 47900/tcp
ENTRYPOINT ["python3", "-u", "/app/relevo.py", "--puerto", "47900"]
CMD ["--max-salas", "200"]
