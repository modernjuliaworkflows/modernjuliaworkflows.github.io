# Local development for the Zola site. The authored pages live in src/ and
# are executed into content/ by tools/ZolaPreprocessor before Zola runs.
# Requires Julia 1.11 (the section Manifests are resolved for it) and Zola 0.23.

JULIA ?= julia
ZOLA ?= zola

.PHONY: preprocess serve build check test clean

# --startup-file=no: a startup.jl loading Revise would pull JuliaInterpreter
# into the session at whatever version the default environment has, breaking
# precompilation of the section environments' pinned JET.
preprocess:
	$(JULIA) --startup-file=no --project=tools/ZolaPreprocessor tools/ZolaPreprocessor/main.jl src content

serve: preprocess
	$(ZOLA) serve

build: preprocess
	$(ZOLA) build

check: preprocess
	$(ZOLA) check

test:
	$(JULIA) --project=tools/ZolaPreprocessor -e 'using Pkg; Pkg.test()'

clean:
	rm -rf content public _workdir
