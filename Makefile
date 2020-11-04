start:
	docker run --rm -it -v `pwd`:/src klakegg/hugo:0.78.0

new:
	docker run --rm -it -v `pwd`:/src klakegg/hugo:0.78.0 new site test

server:
	docker run --rm -it -p 1313:1313 -v `pwd`:/src klakegg/hugo:0.78.0 server --disableFastRender

publish:
	docker run --rm -it -p 1313:1313 -v `pwd`:/src klakegg/hugo:0.78.0 -D
