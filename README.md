# Robocat base docker image

This is the base docker image that bundles [TagUI](https://aisingapore.org/aiproducts/tagui/) together with [Xvfb](https://en.wikipedia.org/wiki/Xvfb), [fluxbox](https://en.wikipedia.org/wiki/Fluxbox), [x11vnc](https://en.wikipedia.org/wiki/X11vnc), [Google Chrome](https://en.wikipedia.org/wiki/Google_Chrome), and [some other dependencies](#full-list-of-installed-dependencies) in a neat package, so it is possible to run TagUI flows in a container.

## Full list of installed dependencies

- [Amazon Corretto 8 (1.8.0)](https://docs.aws.amazon.com/corretto/latest/corretto-8-ug/what-is-corretto-8.html)
- [PHP 8.1](https://www.php.net/releases/8.1/en.php)
- [Tesseract OCR 4.1](https://github.com/tesseract-ocr/tesseract/tree/4.1#about)
- [tinyproxy](https://tinyproxy.github.io)
