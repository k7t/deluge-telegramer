FROM python:3.13-alpine AS base

RUN mkdir -p /usr/src/app
RUN mkdir -p /output
WORKDIR /usr/src/app

RUN pip install --no-cache-dir setuptools

COPY telegramer /usr/src/app/telegramer
COPY setup.py /usr/src/app/setup.py
COPY LICENSE /usr/src/app/LICENSE

RUN python setup.py bdist_egg && \
    python -c "import zipfile,os,glob; e=glob.glob('dist/*.egg')[0]; t=e+'.tmp'; z=zipfile.ZipFile(t,'w',compression=zipfile.ZIP_STORED); [z.writestr(i,zipfile.ZipFile(e).read(i.filename)) for i in zipfile.ZipFile(e).infolist()]; z.close(); os.replace(t,e)"
