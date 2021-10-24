server:
	docker run --rm -it -p 1313:1313 -v `pwd`/hugo:/src klakegg/hugo:0.78.0 server --disableFastRender

publish:
	docker run --rm -it -p 1313:1313 -v `pwd`/hugo:/src -v `pwd`/docs:/publish klakegg/hugo:0.78.0 -d /publish
